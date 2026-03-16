import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'car_physics.dart';
import 'city_map.dart';

class CityPainter extends CustomPainter {
  final CityMap map;
  final CarState car;
  final List<ui.Image?> buildingImages;
  final List<CarState> policeCars;

  CityPainter({
    required this.map,
    required this.car,
    this.buildingImages = const [],
    this.policeCars = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Camera: center on car
    final camX = car.x - size.width / 2;
    final camY = car.y - size.height / 2;

    canvas.save();
    canvas.translate(-camX, -camY);

    final viewport = Rect.fromLTWH(camX - 50, camY - 50, size.width + 100, size.height + 100);

    _drawGround(canvas);
    _drawRoads(canvas, viewport);
    _drawRoadMarkings(canvas, viewport);
    _drawSidewalks(canvas, viewport);
    _drawBuildings(canvas, viewport);
    _drawLandmarks(canvas, viewport);
    for (final police in policeCars) {
      _drawPoliceCar(canvas, police);
    }
    _drawCar(canvas);

    canvas.restore();

    // Minimap drawn in screen space
    _drawMinimap(canvas, size);
  }

  void _drawGround(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, CityMap.mapSize, CityMap.mapSize),
      Paint()..color = const Color(0xFF4E6B4A),
    );
  }

  void _drawRoads(Canvas canvas, Rect viewport) {
    final paint = Paint()..color = const Color(0xFF616161);
    for (final road in map.roads) {
      if (road.overlaps(viewport)) {
        canvas.drawRect(road, paint);
      }
    }
  }

  void _drawRoadMarkings(Canvas canvas, Rect viewport) {
    final yellowPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;
    final whitePaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.fill;

    const rw = CityMap.roadWidth;
    const dashLen = 20.0;
    const gapLen = 15.0;

    for (int i = 0; i < 5; i++) {
      final pos = i * (CityMap.blockSize + rw);

      // Horizontal road — center dashed yellow line
      final hCenterY = pos + rw / 2 - 1.5;
      for (double dx = 0; dx < CityMap.mapSize; dx += dashLen + gapLen) {
        final dashRect = Rect.fromLTWH(dx, hCenterY, dashLen, 3);
        if (dashRect.overlaps(viewport)) {
          canvas.drawRect(dashRect, yellowPaint);
        }
      }
      // Horizontal road — white edge lines
      final hTopEdge = Rect.fromLTWH(0, pos.toDouble() + 2, CityMap.mapSize, 2);
      final hBotEdge = Rect.fromLTWH(0, pos.toDouble() + rw - 4, CityMap.mapSize, 2);
      if (hTopEdge.overlaps(viewport)) canvas.drawRect(hTopEdge, whitePaint);
      if (hBotEdge.overlaps(viewport)) canvas.drawRect(hBotEdge, whitePaint);

      // Vertical road — center dashed yellow line
      final vCenterX = pos + rw / 2 - 1.5;
      for (double dy = 0; dy < CityMap.mapSize; dy += dashLen + gapLen) {
        final dashRect = Rect.fromLTWH(vCenterX, dy, 3, dashLen);
        if (dashRect.overlaps(viewport)) {
          canvas.drawRect(dashRect, yellowPaint);
        }
      }
      // Vertical road — white edge lines
      final vLeftEdge = Rect.fromLTWH(pos.toDouble() + 2, 0, 2, CityMap.mapSize);
      final vRightEdge = Rect.fromLTWH(pos.toDouble() + rw - 4, 0, 2, CityMap.mapSize);
      if (vLeftEdge.overlaps(viewport)) canvas.drawRect(vLeftEdge, whitePaint);
      if (vRightEdge.overlaps(viewport)) canvas.drawRect(vRightEdge, whitePaint);
    }
  }

  void _drawSidewalks(Canvas canvas, Rect viewport) {
    final paint = Paint()..color = const Color(0xFF9E9E9E);
    const sw = CityMap.sidewalkWidth;
    const rw = CityMap.roadWidth;

    for (int i = 0; i < 5; i++) {
      final pos = i * (CityMap.blockSize + rw);

      // Sidewalks on horizontal roads (top and bottom edges, inside road)
      final hTop = Rect.fromLTWH(0, pos.toDouble() + 4, CityMap.mapSize, sw);
      final hBot = Rect.fromLTWH(0, pos.toDouble() + rw - 4 - sw, CityMap.mapSize, sw);
      if (hTop.overlaps(viewport)) canvas.drawRect(hTop, paint);
      if (hBot.overlaps(viewport)) canvas.drawRect(hBot, paint);

      // Sidewalks on vertical roads
      final vLeft = Rect.fromLTWH(pos.toDouble() + 4, 0, sw, CityMap.mapSize);
      final vRight = Rect.fromLTWH(pos.toDouble() + rw - 4 - sw, 0, sw, CityMap.mapSize);
      if (vLeft.overlaps(viewport)) canvas.drawRect(vLeft, paint);
      if (vRight.overlaps(viewport)) canvas.drawRect(vRight, paint);
    }
  }

  void _drawBuildings(Canvas canvas, Rect viewport) {
    for (int i = 0; i < map.buildings.length; i++) {
      final b = map.buildings[i];
      if (!b.overlaps(viewport)) continue;

      final imgIndex = map.buildingImageIndices[i];
      final img = (imgIndex < buildingImages.length) ? buildingImages[imgIndex] : null;

      if (img != null) {
        final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        canvas.drawImageRect(img, src, b, Paint());
      } else {
        // Fallback: colored rectangle
        final rrect = RRect.fromRectAndRadius(b, const Radius.circular(6));
        canvas.drawRRect(rrect, Paint()..color = map.buildingColors[i]);
      }

      // Subtle border
      final rrect = RRect.fromRectAndRadius(b, const Radius.circular(6));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0x33000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawLandmarks(Canvas canvas, Rect viewport) {
    for (final lm in map.landmarks) {
      if (!lm.area.overlaps(viewport)) continue;

      final center = lm.area.center;
      // Background circle
      canvas.drawCircle(center, 20, Paint()..color = lm.color);
      canvas.drawCircle(
        center, 20,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label letter
      final tp = TextPainter(
        text: TextSpan(
          text: lm.label[0], // first letter
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

      // Label text below
      final labelTp = TextPainter(
        text: TextSpan(
          text: lm.label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black, blurRadius: 3)]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(canvas, Offset(center.dx - labelTp.width / 2, center.dy + 22));
    }
  }

  void _drawPoliceCar(Canvas canvas, CarState police) {
    canvas.save();
    canvas.translate(police.x, police.y);
    canvas.rotate(police.angle);

    final halfW = police.width / 2;
    final halfH = police.height / 2;

    // Blue police car body
    final bodyRect = Rect.fromLTRB(-halfW, -halfH, halfW, halfH);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(4));
    canvas.drawRRect(bodyRRect, Paint()..color = const Color(0xFF1565C0));

    // Front indicator (white)
    final frontRect = Rect.fromLTRB(halfW - 8, -halfH + 2, halfW - 1, halfH - 2);
    canvas.drawRect(frontRect, Paint()..color = const Color(0xFFFFFFFF));

    // Outline
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = const Color(0xFF0D47A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  void _drawCar(Canvas canvas) {
    canvas.save();
    canvas.translate(car.x, car.y);
    canvas.rotate(car.angle);

    final halfW = car.width / 2;
    final halfH = car.height / 2;

    // Car body (red)
    final bodyRect = Rect.fromLTRB(-halfW, -halfH, halfW, halfH);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(4));
    canvas.drawRRect(bodyRRect, Paint()..color = const Color(0xFFE74C3C));

    // Front indicator (orange-yellow, shows direction)
    final frontRect = Rect.fromLTRB(halfW - 8, -halfH + 2, halfW - 1, halfH - 2);
    canvas.drawRect(frontRect, Paint()..color = const Color(0xFFF39C12));

    // Windshield
    final windshield = Rect.fromLTRB(halfW - 14, -halfH + 3, halfW - 8, halfH - 3);
    canvas.drawRect(windshield, Paint()..color = const Color(0xFF90CAF9));

    // Outline
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = const Color(0xFF880000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  void _drawMinimap(Canvas canvas, Size size) {
    const mmSize = 120.0;
    const margin = 10.0;
    final mmRect = Rect.fromLTWH(size.width - mmSize - margin, margin, mmSize, mmSize);

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(mmRect, const Radius.circular(8)),
      Paint()..color = const Color(0xAA000000),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(mmRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final scale = mmSize / CityMap.mapSize;

    canvas.save();
    canvas.translate(mmRect.left, mmRect.top);
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, mmSize, mmSize), const Radius.circular(8),
    ));

    // Roads on minimap
    final roadPaint = Paint()..color = const Color(0xFF757575);
    for (final road in map.roads) {
      canvas.drawRect(
        Rect.fromLTWH(road.left * scale, road.top * scale, road.width * scale, road.height * scale),
        roadPaint,
      );
    }

    // Buildings on minimap
    for (int i = 0; i < map.buildings.length; i++) {
      final b = map.buildings[i];
      canvas.drawRect(
        Rect.fromLTWH(b.left * scale, b.top * scale, b.width * scale, b.height * scale),
        Paint()..color = map.buildingColors[i],
      );
    }

    // Landmarks on minimap
    for (final lm in map.landmarks) {
      canvas.drawCircle(
        Offset(lm.area.center.dx * scale, lm.area.center.dy * scale),
        3,
        Paint()..color = lm.color,
      );
    }

    // Police dots on minimap — large red dots with white outline
    for (final police in policeCars) {
      final policePos = Offset(police.x * scale, police.y * scale);
      canvas.drawCircle(policePos, 5, Paint()..color = Colors.white);
      canvas.drawCircle(policePos, 4, Paint()..color = const Color(0xFFFF1744));
    }

    // Car dot
    canvas.drawCircle(
      Offset(car.x * scale, car.y * scale),
      3,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(car.x * scale, car.y * scale),
      3,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CityPainter oldDelegate) => true;
}
