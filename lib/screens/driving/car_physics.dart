import 'dart:math';
import 'dart:ui';

const double maxSpeed = 200.0;
const double maxReverseSpeed = -40.0;
const double carAcceleration = 45.0;
const double brakeDeceleration = 120.0;
const double friction = 25.0;
const double turnRate = 2.5;

class CarState {
  double x;
  double y;
  double angle; // radians, 0 = right
  double speed = 0;
  final double width = 30;
  final double height = 16;

  CarState({required this.x, required this.y, this.angle = -pi / 2});

  void update(
    double dt, {
    bool accelerating = false,
    bool braking = false,
    bool steerLeft = false,
    bool steerRight = false,
  }) {
    // Acceleration / braking / friction
    if (accelerating) {
      speed = (speed + carAcceleration * dt).clamp(maxReverseSpeed, maxSpeed);
    } else if (braking) {
      if (speed > 0) {
        speed = (speed - brakeDeceleration * dt).clamp(0, maxSpeed);
      } else {
        speed = (speed - carAcceleration * 0.5 * dt).clamp(maxReverseSpeed, 0);
      }
    } else {
      // Friction
      if (speed > 0) {
        speed = (speed - friction * dt).clamp(0, maxSpeed);
      } else if (speed < 0) {
        speed = (speed + friction * dt).clamp(maxReverseSpeed, 0);
      }
    }

    // Steering — harder to turn at high speed
    if (speed.abs() > 0.5) {
      final turnFactor = turnRate * (1.0 - (speed.abs() / maxSpeed) * 0.6);
      if (steerLeft) {
        angle -= turnFactor * dt * speed.sign;
      }
      if (steerRight) {
        angle += turnFactor * dt * speed.sign;
      }
    }

    // Movement
    x += cos(angle) * speed * dt;
    y += sin(angle) * speed * dt;
  }

  /// Four corners of the rotated car rectangle (for collision detection).
  List<Offset> get corners {
    final halfW = width / 2;
    final halfH = height / 2;
    final cosA = cos(angle);
    final sinA = sin(angle);

    Offset rotate(double lx, double ly) =>
        Offset(x + lx * cosA - ly * sinA, y + lx * sinA + ly * cosA);

    return [
      rotate(-halfW, -halfH),
      rotate(halfW, -halfH),
      rotate(halfW, halfH),
      rotate(-halfW, halfH),
    ];
  }

  /// Axis-aligned bounding box enclosing the rotated car.
  Rect get aabb {
    final c = corners;
    double minX = c[0].dx, maxX = c[0].dx;
    double minY = c[0].dy, maxY = c[0].dy;
    for (int i = 1; i < 4; i++) {
      if (c[i].dx < minX) minX = c[i].dx;
      if (c[i].dx > maxX) maxX = c[i].dx;
      if (c[i].dy < minY) minY = c[i].dy;
      if (c[i].dy > maxY) maxY = c[i].dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
