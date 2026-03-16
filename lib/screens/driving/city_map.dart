import 'dart:ui';

enum LandmarkType { home, gasStation, restaurant, park }

class Landmark {
  final LandmarkType type;
  final Rect area;
  final String label;
  final Color color;

  const Landmark({
    required this.type,
    required this.area,
    required this.label,
    required this.color,
  });
}

class CityMap {
  static const double mapSize = 1600;
  static const double roadWidth = 80;
  static const double blockSize = 300;
  static const double sidewalkWidth = 8;

  // Grid: 5 roads + 4 blocks per axis
  // Road centers: 40, 420, 800, 1180, 1560
  // Block starts: 80, 460, 840, 1220

  late final List<Rect> roads;
  late final List<Rect> buildings;
  late final List<Color> buildingColors;
  late final List<int> buildingImageIndices;
  late final List<Landmark> landmarks;

  CityMap() {
    _buildRoads();
    _buildBuildings();
    _buildLandmarks();
  }

  void _buildRoads() {
    roads = [];
    for (int i = 0; i < 5; i++) {
      final pos = i * (blockSize + roadWidth);
      // Horizontal road strip
      roads.add(Rect.fromLTWH(0, pos.toDouble(), mapSize, roadWidth));
      // Vertical road strip
      roads.add(Rect.fromLTWH(pos.toDouble(), 0, roadWidth, mapSize));
    }
  }

  void _buildBuildings() {
    buildings = [];
    buildingColors = [];

    const colors = [
      Color(0xFFD7CCC8), // beige
      Color(0xFFBCAAA4), // brown-grey
      Color(0xFFB0BEC5), // blue-grey
      Color(0xFFCFD8DC), // light blue-grey
      Color(0xFFD7CCC8),
      Color(0xFFE0E0E0), // light grey
      Color(0xFFBCAAA4),
      Color(0xFFCFD8DC),
      Color(0xFFB0BEC5),
      Color(0xFFD7CCC8),
      Color(0xFFE0E0E0),
      Color(0xFF81C784), // park — green (block index 11 = row 2, col 3)
      Color(0xFFBCAAA4),
      Color(0xFFCFD8DC),
      Color(0xFFD7CCC8),
      Color(0xFFB0BEC5),
    ];

    buildingImageIndices = [];
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        final left = roadWidth + col * (blockSize + roadWidth);
        final top = roadWidth + row * (blockSize + roadWidth);
        buildings.add(Rect.fromLTWH(left, top, blockSize, blockSize));
        buildingColors.add(colors[row * 4 + col]);
        buildingImageIndices.add((row * 4 + col) % 3);
      }
    }
  }

  void _buildLandmarks() {
    // Place landmarks on road edges near specific blocks
    // Block indices: row*4+col

    // Home — near block (0,0), on the road to the right of it
    final homeBlock = buildings[0]; // top-left block
    final homeArea = Rect.fromLTWH(
      homeBlock.right + 10, // on the road to the right
      homeBlock.top + blockSize / 2 - 25,
      60, 50,
    );

    // Gas station — near block (1,3), on the road below it
    final gasBlock = buildings[1 * 4 + 3];
    final gasArea = Rect.fromLTWH(
      gasBlock.left + blockSize / 2 - 30,
      gasBlock.bottom + 10,
      60, 50,
    );

    // Restaurant — near block (2,1), on the road to the left
    final restBlock = buildings[2 * 4 + 1];
    final restArea = Rect.fromLTWH(
      restBlock.left - 70,
      restBlock.top + blockSize / 2 - 25,
      60, 50,
    );

    // Park — block (2,3) itself is green, landmark on road above
    final parkBlock = buildings[2 * 4 + 3];
    final parkArea = Rect.fromLTWH(
      parkBlock.left + blockSize / 2 - 30,
      parkBlock.top - 60,
      60, 50,
    );

    landmarks = [
      Landmark(type: LandmarkType.home, area: homeArea, label: "Ev", color: const Color(0xFF42A5F5)),
      Landmark(type: LandmarkType.gasStation, area: gasArea, label: "Yanacaq", color: const Color(0xFFFFA726)),
      Landmark(type: LandmarkType.restaurant, area: restArea, label: "Restoran", color: const Color(0xFFEF5350)),
      Landmark(type: LandmarkType.park, area: parkArea, label: "Park", color: const Color(0xFF66BB6A)),
    ];
  }

  /// Starting position for the car (on road near home).
  Offset get homeStart {
    final homeBlock = buildings[0];
    return Offset(
      homeBlock.right + roadWidth / 2,
      homeBlock.top + blockSize / 2,
    );
  }

  /// Returns the first building a car corner collides with, or null.
  Rect? collidesWithBuilding(List<Offset> carCorners) {
    for (final b in buildings) {
      for (final corner in carCorners) {
        if (b.contains(corner)) return b;
      }
    }
    return null;
  }
}
