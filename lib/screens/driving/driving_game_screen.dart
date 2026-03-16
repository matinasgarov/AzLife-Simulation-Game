import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../models/player.dart';
import 'car_physics.dart';
import 'city_map.dart';
import 'city_renderer.dart';

class DrivingGameScreen extends StatefulWidget {
  final Player player;
  final String launchContext; // 'activities' or 'father_interaction'

  const DrivingGameScreen({
    super.key,
    required this.player,
    this.launchContext = 'activities',
  });

  @override
  State<DrivingGameScreen> createState() => _DrivingGameScreenState();
}

class _DrivingGameScreenState extends State<DrivingGameScreen> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  late CityMap _cityMap;
  late CarState _car;
  Duration _lastTick = Duration.zero;

  // Input state
  bool _accel = false;
  bool _brake = false;
  bool _left = false;
  bool _right = false;

  // Session tracking
  double _sessionTime = 0;
  double _lastHappinessRewardTime = 0;
  int _happinessEarned = 0;
  int _moneySpent = 0;

  // Landmark visit tracking
  final Set<LandmarkType> _visitedLandmarks = {};

  // Toast
  String? _toastMessage;
  double _toastTimer = 0;

  // Image sprites (buildings only — car uses canvas-drawn shape)
  List<ui.Image?> _buildingImages = [];
  bool _imagesLoaded = false;

  // Police chase (father_interaction only)
  final List<CarState> _policeCars = [];
  bool _policeSpawned = false;
  bool _gameEnded = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    debugPrint('DrivingGameScreen initState: launchContext=${widget.launchContext}');
    _cityMap = CityMap();
    _car = CarState(x: _cityMap.homeStart.dx, y: _cityMap.homeStart.dy);
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    _buildingImages = await Future.wait([
      _loadImage('assets/gameImages/building1.png'),
      _loadImage('assets/gameImages/building2.png'),
      _loadImage('assets/gameImages/building3.png'),
    ]);
    if (mounted) {
      setState(() => _imagesLoaded = true);
      _ticker = createTicker(_onTick)..start();
    }
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    double dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    if (dt > 0.05) dt = 0.05; // cap to prevent physics explosions

    // Save old position
    final oldX = _car.x;
    final oldY = _car.y;

    // Update physics
    _car.update(dt, accelerating: _accel, braking: _brake, steerLeft: _left, steerRight: _right);

    // Collision check
    if (_cityMap.collidesWithBuilding(_car.corners) != null) {
      _car.x = oldX;
      _car.y = oldY;
      _car.speed = 0;
    }

    // Clamp to map bounds
    _car.x = _car.x.clamp(20, CityMap.mapSize - 20);
    _car.y = _car.y.clamp(20, CityMap.mapSize - 20);

    // Happiness reward every 60 seconds
    _sessionTime += dt;
    if (_sessionTime - _lastHappinessRewardTime >= 60) {
      _lastHappinessRewardTime = _sessionTime;
      _happinessEarned += 2;
      widget.player.happiness = (widget.player.happiness + 2).clamp(0, 100);
    }

    // Police spawn after 10 seconds (father_interaction only)
    if (widget.launchContext == 'father_interaction' && !_policeSpawned && _sessionTime >= 10) {
      _policeSpawned = true;
      // Spawn on the closest road intersection that's >= 300px away
      const roadCenters = [40.0, 420.0, 800.0, 1180.0, 1560.0];
      double bestX = 800, bestY = 800, bestDist = double.infinity;
      for (final rx in roadCenters) {
        for (final ry in roadCenters) {
          final d = sqrt(pow(rx - _car.x, 2) + pow(ry - _car.y, 2));
          if (d >= 300 && d < bestDist) {
            bestX = rx;
            bestY = ry;
            bestDist = d;
          }
        }
      }
      final police = CarState(x: bestX, y: bestY);
      police.speed = 60; // start with some speed so it moves immediately
      _policeCars.add(police);
      debugPrint('POLICE SPAWNED at ($bestX, $bestY), player at (${_car.x}, ${_car.y}), dist=$bestDist');
      _showToast("🚔 Polislər səni axtarır!");
    }

    // Update police cars
    _updatePolice(dt);
    if (_gameEnded) return;

    // Landmark interactions
    _checkLandmarks();
    if (_gameEnded) return;

    // Toast timer
    if (_toastTimer > 0) {
      _toastTimer -= dt;
      if (_toastTimer <= 0) {
        _toastMessage = null;
      }
    }

    setState(() {});
  }

  void _checkLandmarks() {
    // Distance-based home escape check (more reliable than rect overlap)
    if (widget.launchContext == 'father_interaction' && _policeSpawned) {
      final homeLm = _cityMap.landmarks.firstWhere((l) => l.type == LandmarkType.home);
      final homeCenter = homeLm.area.center;
      final dist = sqrt(pow(_car.x - homeCenter.dx, 2) + pow(_car.y - homeCenter.dy, 2));
      if (dist < 100) {
        debugPrint('HOME ESCAPE! dist=$dist');
        _endGame('escaped');
        return;
      }
    }

    final carRect = _car.aabb;
    for (final lm in _cityMap.landmarks) {
      final overlaps = carRect.overlaps(lm.area);
      if (overlaps && !_visitedLandmarks.contains(lm.type)) {
        _triggerLandmark(lm);
      } else if (!overlaps && _visitedLandmarks.contains(lm.type)) {
        _visitedLandmarks.remove(lm.type);
      }
    }
  }

  void _triggerLandmark(Landmark lm) {
    _visitedLandmarks.add(lm.type);
    switch (lm.type) {
      case LandmarkType.gasStation:
        if (widget.player.money >= 5) {
          widget.player.money -= 5;
          _moneySpent += 5;
          _showToast("⛽ Yanacaq doldurdun (5 AZN)");
        } else {
          _showToast("⛽ Yanacaq üçün pulun yoxdur!");
        }
      case LandmarkType.restaurant:
        _showToast("🍽️ Restorana çatdın!");
      case LandmarkType.park:
        _showToast("🌳 Parkda gəzinti");
      case LandmarkType.home:
        if (widget.launchContext == 'father_interaction' && _policeSpawned) {
          _endGame('escaped');
          return;
        }
        _showToast("🏠 Evə çatdın");
    }
  }

  void _updatePolice(double dt) {
    if (_policeCars.isEmpty || _gameEnded) return;

    for (final police in _policeCars) {
      // Road-aware navigation: snap to nearest road axis when not at intersection
      final targetAngle = atan2(_car.y - police.y, _car.x - police.x);

      // Find nearest road center on each axis
      const roadCenters = [40.0, 420.0, 800.0, 1180.0, 1560.0];
      double nearestRoadX = roadCenters[0], nearestRoadY = roadCenters[0];
      for (final rc in roadCenters) {
        if ((rc - police.x).abs() < (nearestRoadX - police.x).abs()) nearestRoadX = rc;
        if ((rc - police.y).abs() < (nearestRoadY - police.y).abs()) nearestRoadY = rc;
      }

      final onVerticalRoad = (police.x - nearestRoadX).abs() < 30;
      final onHorizontalRoad = (police.y - nearestRoadY).abs() < 30;

      double desiredAngle;
      if (onVerticalRoad && onHorizontalRoad) {
        // At intersection — head toward player
        desiredAngle = targetAngle;
      } else if (onVerticalRoad) {
        // On vertical road — go up or down toward player
        desiredAngle = _car.y > police.y ? pi / 2 : -pi / 2;
      } else if (onHorizontalRoad) {
        // On horizontal road — go left or right toward player
        desiredAngle = _car.x > police.x ? 0 : pi;
      } else {
        // Off-road — head to nearest road intersection
        desiredAngle = atan2(nearestRoadY - police.y, nearestRoadX - police.x);
      }

      // Smooth steering
      double angleDiff = desiredAngle - police.angle;
      while (angleDiff > pi) { angleDiff -= 2 * pi; }
      while (angleDiff < -pi) { angleDiff += 2 * pi; }
      police.angle += angleDiff.clamp(-4.0 * dt, 4.0 * dt);

      // Gradually increase speed
      police.speed = (police.speed + 40 * dt).clamp(0, 180);

      final oldPX = police.x;
      final oldPY = police.y;
      police.x += cos(police.angle) * police.speed * dt;
      police.y += sin(police.angle) * police.speed * dt;

      // Building collision — revert and try perpendicular
      if (_cityMap.collidesWithBuilding(police.corners) != null) {
        police.x = oldPX;
        police.y = oldPY;
        // Try perpendicular direction closest to target
        final perp1 = police.angle + pi / 2;
        final perp2 = police.angle - pi / 2;
        double diff1 = targetAngle - perp1;
        while (diff1 > pi) { diff1 -= 2 * pi; }
        while (diff1 < -pi) { diff1 += 2 * pi; }
        double diff2 = targetAngle - perp2;
        while (diff2 > pi) { diff2 -= 2 * pi; }
        while (diff2 < -pi) { diff2 += 2 * pi; }
        police.angle = diff1.abs() < diff2.abs() ? perp1 : perp2;
        police.speed *= 0.7;
      }

      // Clamp to map
      police.x = police.x.clamp(20, CityMap.mapSize - 20);
      police.y = police.y.clamp(20, CityMap.mapSize - 20);

      // Catch check — 50px radius
      final dist = sqrt(pow(_car.x - police.x, 2) + pow(_car.y - police.y, 2));
      if (dist < 50) {
        debugPrint('POLICE CAUGHT player! dist=$dist');
        _endGame('caught');
        return;
      }
    }
  }

  void _endGame(String reason) {
    if (_gameEnded) return;
    debugPrint('ENDGAME: reason=$reason, sessionTime=$_sessionTime');
    _gameEnded = true;
    _ticker?.stop();
    Navigator.pop(context, <String, dynamic>{
      'log': reason == 'caught' ? 'Polislər tutdu' : 'Evə qaçdı',
      'sessionTime': _sessionTime,
      'happinessEarned': _happinessEarned,
      'moneySpent': _moneySpent,
      'endReason': reason,
    });
  }

  void _showToast(String message) {
    _toastMessage = message;
    _toastTimer = 2.5;
  }

  void _exit() {
    final logParts = <String>["Maşın sürdü"];
    if (_happinessEarned > 0) logParts.add("+$_happinessEarned xoşbəxtlik");
    if (_moneySpent > 0) logParts.add("-$_moneySpent AZN yanacaq");
    Navigator.pop(context, <String, dynamic>{
      'log': "Fəaliyyət: ${logParts.join(', ')}",
      'sessionTime': _sessionTime,
      'happinessEarned': _happinessEarned,
      'moneySpent': _moneySpent,
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      if (isDown) _accel = true;
      if (isUp) _accel = false;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      if (isDown) _brake = true;
      if (isUp) _brake = false;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      if (isDown) _left = true;
      if (isUp) _left = false;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      if (isDown) _right = true;
      if (isUp) _right = false;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!_imagesLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Yüklənir... ⏳",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Game canvas
            Positioned.fill(
              child: CustomPaint(
                painter: CityPainter(
                  map: _cityMap,
                  car: _car,
                  buildingImages: _buildingImages,
                  policeCars: _policeCars,
                ),
              ),
            ),

            // HUD — top left
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xBB000000),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🚗 ${_car.speed.abs().toInt()} km/s",
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "💰 ${widget.player.money} AZN",
                      style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "⏱️ ${(_sessionTime ~/ 60).toString().padLeft(2, '0')}:${(_sessionTime.toInt() % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
                    ),
                    if (widget.launchContext == 'father_interaction') ...[
                      const SizedBox(height: 2),
                      Text(
                        _policeSpawned
                            ? "🚔 Polis: ${_policeCars.length} (${_policeCars.isNotEmpty ? '${_policeCars[0].x.toInt()},${_policeCars[0].y.toInt()}' : '-'})"
                            : "🚔 ${(10 - _sessionTime).clamp(0, 10).toInt()}s sonra...",
                        style: TextStyle(
                          color: _policeSpawned ? const Color(0xFFFF5252) : const Color(0xFFBBBBBB),
                          fontSize: 12,
                          fontWeight: _policeSpawned ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Toast overlay — top center
            if (_toastMessage != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 40,
                right: 40,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xDD000000),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _toastMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),

            // Exit button — top right (below minimap)
            Positioned(
              top: MediaQuery.of(context).padding.top + 140,
              right: 12,
              child: GestureDetector(
                onTap: _exit,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xBB000000),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x66FFFFFF)),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),

            // D-pad controls — bottom center
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Center(child: _buildDPad()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDPad() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        children: [
          // Up
          Positioned(
            top: 0,
            left: 60,
            child: _dpadButton(Icons.arrow_drop_up, onDown: () => _accel = true, onUp: () => _accel = false),
          ),
          // Down
          Positioned(
            bottom: 0,
            left: 60,
            child: _dpadButton(Icons.arrow_drop_down, onDown: () => _brake = true, onUp: () => _brake = false),
          ),
          // Left
          Positioned(
            top: 60,
            left: 0,
            child: _dpadButton(Icons.arrow_left, onDown: () => _left = true, onUp: () => _left = false),
          ),
          // Right
          Positioned(
            top: 60,
            right: 0,
            child: _dpadButton(Icons.arrow_right, onDown: () => _right = true, onUp: () => _right = false),
          ),
        ],
      ),
    );
  }

  Widget _dpadButton(IconData icon, {required VoidCallback onDown, required VoidCallback onUp}) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: () => onUp(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0x88000000),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x44FFFFFF), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
