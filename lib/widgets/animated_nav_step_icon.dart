import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/transit_modes.dart';

/// A motion-sensitive animated navigation step icon.
///
/// When the user is moving ([isMoving] is true), the icon comes alive:
/// - Walking: A procedurally drawn stick man strides forward with swinging arms,
///   legs, and vertical body bobbing.
/// - Bus / Minibus / Microbus: Suspension vibration and road motion effect.
/// - Metro / Train / Monorail: Track glide pulse animation.
/// - Transfer: Rotating interchange arrows.
/// - Arrival / Destination: Beacon pulse ring.
///
/// When the user stops ([isMoving] is false), the animation smoothly comes to rest
/// in an idle standing or stationary vehicle state.
class AnimatedNavStepIcon extends StatefulWidget {
  final String iconKey;
  final bool isMoving;
  final Color color;
  final double size;

  const AnimatedNavStepIcon({
    super.key,
    required this.iconKey,
    required this.isMoving,
    this.color = Colors.white,
    this.size = 24.0,
  });

  @override
  State<AnimatedNavStepIcon> createState() => _AnimatedNavStepIconState();
}

class _AnimatedNavStepIconState extends State<AnimatedNavStepIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    if (widget.isMoving) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedNavStepIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving != oldWidget.isMoving) {
      if (widget.isMoving) {
        if (!_controller.isAnimating) _controller.repeat();
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 250));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.iconKey.toLowerCase();

    if (key == 'walk') {
      return _buildWalkingStickMan();
    } else if (key == 'bus' || key == 'minibus' || key == 'microbus') {
      return _buildVehicleMotion(key);
    } else if (key == 'metro' || key == 'subway' || key == 'train' || key == 'monorail' || key == 'lrt') {
      return _buildRailMotion(key);
    } else if (key == 'transfer') {
      return _buildTransferMotion();
    } else if (key == 'arrive' || key == 'flag' || key == 'destination') {
      return _buildArrivalPulse();
    }

    // Default fallback icon with subtle breath animation when moving
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isMoving
            ? 1.0 + math.sin(_controller.value * 2 * math.pi) * 0.08
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Icon(TransitModes.icon(key), color: widget.color, size: widget.size),
        );
      },
    );
  }

  Widget _buildWalkingStickMan() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value * 2 * math.pi;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WalkingStickManPainter(
            color: widget.color,
            phase: widget.isMoving ? phase : 0.0,
            isMoving: widget.isMoving,
          ),
        );
      },
    );
  }

  Widget _buildVehicleMotion(String key) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Subtle suspension vibration + horizontal road glide
        final phase = _controller.value * 2 * math.pi;
        final dy = widget.isMoving ? math.sin(phase * 2) * 1.0 : 0.0;
        final dx = widget.isMoving ? math.sin(phase) * 0.7 : 0.0;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(TransitModes.icon(key), color: widget.color, size: widget.size),
              if (widget.isMoving)
                Positioned(
                  bottom: -3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final dotPhase = (phase + (index * 1.2)) % (2 * math.pi);
                      final opacity = (math.sin(dotPhase) * 0.5 + 0.5).clamp(0.2, 0.9);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3.5,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRailMotion(String key) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * 2 * math.pi;
        final forwardGlider = widget.isMoving ? math.sin(phase) * 1.2 : 0.0;
        final glowScale = widget.isMoving ? 1.0 + math.sin(phase * 2) * 0.06 : 1.0;

        return Transform.translate(
          offset: Offset(forwardGlider, 0),
          child: Transform.scale(
            scale: glowScale,
            child: Icon(TransitModes.icon(key), color: widget.color, size: widget.size),
          ),
        );
      },
    );
  }

  Widget _buildTransferMotion() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = widget.isMoving ? _controller.value * 2 * math.pi : 0.0;
        return Transform.rotate(
          angle: angle,
          child: Icon(Icons.swap_horiz_rounded, color: widget.color, size: widget.size),
        );
      },
    );
  }

  Widget _buildArrivalPulse() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * 2 * math.pi;
        final scale = widget.isMoving ? 1.0 + math.sin(phase) * 0.12 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Icon(Icons.place_rounded, color: widget.color, size: widget.size),
        );
      },
    );
  }
}

/// Custom painter rendering an animated walking stick figure.
///
/// Features realistic human gait kinematics:
/// - Torso & head with vertical bobbing on foot strike.
/// - Two independent legs swinging with sinusoidal alternating phases and knee flexing.
/// - Two independent arms swinging in counter-phase to the legs for natural balance.
class _WalkingStickManPainter extends CustomPainter {
  final Color color;
  final double phase;
  final bool isMoving;

  _WalkingStickManPainter({
    required this.color,
    required this.phase,
    required this.isMoving,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.09;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Dimensions
    final cx = size.width * 0.5;
    // Vertical bobbing: head and torso bounce down when feet cross center
    final bob = isMoving ? math.sin(phase * 2).abs() * (size.height * 0.06) : 0.0;

    final headRadius = size.width * 0.15;
    final headCenter = Offset(cx, size.height * 0.20 + bob);

    // Draw Head
    canvas.drawCircle(headCenter, headRadius, fillPaint);

    // Torso
    final neckY = headCenter.dy + headRadius + 1;
    final hipY = neckY + (size.height * 0.32);
    final neck = Offset(cx, neckY);
    final hip = Offset(cx, hipY);
    canvas.drawLine(neck, hip, paint);

    // Limbs swing kinematics
    final legLength = size.height * 0.38;
    final armLength = size.height * 0.28;

    if (!isMoving) {
      // Resting stance (standing naturally with straight legs and down arms)
      final leftFoot = Offset(cx - (size.width * 0.12), size.height * 0.95);
      final rightFoot = Offset(cx + (size.width * 0.12), size.height * 0.95);
      canvas.drawLine(hip, leftFoot, paint);
      canvas.drawLine(hip, rightFoot, paint);

      final shoulderY = neckY + (size.height * 0.06);
      canvas.drawLine(Offset(cx, shoulderY), Offset(cx - (size.width * 0.18), shoulderY + armLength), paint);
      canvas.drawLine(Offset(cx, shoulderY), Offset(cx + (size.width * 0.18), shoulderY + armLength), paint);
      return;
    }

    // Walking Cycle Kinematics
    final legAngle1 = math.sin(phase) * 0.52; // radians
    final legAngle2 = -legAngle1;

    // Back leg knee bend: when leg moves backward, knee bends slightly
    final isLeg1Back = math.sin(phase) < 0;
    final isLeg2Back = math.sin(phase) > 0;

    // Leg 1 (Front/Back)
    final knee1 = Offset(
      hip.dx + math.sin(legAngle1) * (legLength * 0.52),
      hip.dy + math.cos(legAngle1) * (legLength * 0.52),
    );
    final footAngle1 = isLeg1Back ? legAngle1 - 0.25 : legAngle1;
    final foot1 = Offset(
      knee1.dx + math.sin(footAngle1) * (legLength * 0.48),
      knee1.dy + math.cos(footAngle1) * (legLength * 0.48),
    );
    canvas.drawLine(hip, knee1, paint);
    canvas.drawLine(knee1, foot1, paint);

    // Leg 2 (Alternating)
    final knee2 = Offset(
      hip.dx + math.sin(legAngle2) * (legLength * 0.52),
      hip.dy + math.cos(legAngle2) * (legLength * 0.52),
    );
    final footAngle2 = isLeg2Back ? legAngle2 - 0.25 : legAngle2;
    final foot2 = Offset(
      knee2.dx + math.sin(footAngle2) * (legLength * 0.48),
      knee2.dy + math.cos(footAngle2) * (legLength * 0.48),
    );
    canvas.drawLine(hip, knee2, paint);
    canvas.drawLine(knee2, foot2, paint);

    // Arms swing in counter-phase to legs for natural human balance
    final shoulderY = neckY + (size.height * 0.06);
    final shoulder = Offset(cx, shoulderY);

    final armAngle1 = -math.sin(phase) * 0.48; // Opposes Leg 1
    final armAngle2 = -armAngle1;              // Opposes Leg 2

    final elbow1 = Offset(
      shoulder.dx + math.sin(armAngle1) * (armLength * 0.55),
      shoulder.dy + math.cos(armAngle1) * (armLength * 0.55),
    );
    final hand1 = Offset(
      elbow1.dx + math.sin(armAngle1 + 0.2) * (armLength * 0.45),
      elbow1.dy + math.cos(armAngle1 + 0.2) * (armLength * 0.45),
    );
    canvas.drawLine(shoulder, elbow1, paint);
    canvas.drawLine(elbow1, hand1, paint);

    final elbow2 = Offset(
      shoulder.dx + math.sin(armAngle2) * (armLength * 0.55),
      shoulder.dy + math.cos(armAngle2) * (armLength * 0.55),
    );
    final hand2 = Offset(
      elbow2.dx + math.sin(armAngle2 + 0.2) * (armLength * 0.45),
      elbow2.dy + math.cos(armAngle2 + 0.2) * (armLength * 0.45),
    );
    canvas.drawLine(shoulder, elbow2, paint);
    canvas.drawLine(elbow2, hand2, paint);
  }

  @override
  bool shouldRepaint(covariant _WalkingStickManPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isMoving != isMoving ||
        oldDelegate.color != color;
  }
}
