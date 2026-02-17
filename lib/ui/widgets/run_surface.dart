import 'dart:math';

import 'package:flutter/material.dart';

class RunSurface extends StatelessWidget {
  const RunSurface({
    super.key,
    required this.phaseLabel,
    required this.timeText,
    required this.progress,
    required this.onTap,
    this.timerTextKey,
    this.phaseLabelColor,
    this.ringColor,
  });

  final String phaseLabel;
  final String timeText;
  final double progress;
  final VoidCallback onTap;
  final Key? timerTextKey;
  final Color? phaseLabelColor;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final Color resolvedLabelColor = phaseLabelColor ?? Colors.white;
    final Color resolvedRingColor = ringColor ?? Colors.white;
    final double resolvedProgress = progress.clamp(0.0, 1.0);
    final Color trackColor = const Color(0x1AFFFFFF);
    final Color progressColor = resolvedRingColor.withValues(alpha: 0.85);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                phaseLabel,
                style: TextStyle(
                  color: resolvedLabelColor.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 270,
                height: 270,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      key: const ValueKey<String>('run-ring'),
                      painter: _RunRingPainter(
                        trackColor: trackColor,
                        progressColor: progressColor,
                        progress: resolvedProgress,
                      ),
                    ),
                    Center(
                      child: Text(
                        timeText,
                        key: timerTextKey,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 84,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                          height: 0.95,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunRingPainter extends CustomPainter {
  const _RunRingPainter({
    required this.trackColor,
    required this.progressColor,
    required this.progress,
  });

  final Color trackColor;
  final Color progressColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide / 2) - 12;
    const double strokeWidth = 5;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint outerRing = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, outerRing);

    final Paint progressRing = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final double sweepAngle = 2 * pi * progress;
    if (sweepAngle > 0.0) {
      canvas.drawArc(arcRect, -pi / 2, sweepAngle, false, progressRing);
    }
  }

  @override
  bool shouldRepaint(covariant _RunRingPainter oldDelegate) {
    return oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.progress != progress;
  }
}
