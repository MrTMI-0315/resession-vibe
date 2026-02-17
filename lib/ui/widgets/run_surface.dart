import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../theme/app_tone.dart';

class RunSurface extends StatefulWidget {
  const RunSurface({
    super.key,
    required this.phaseLabel,
    required this.timeText,
    required this.progress,
    required this.onTap,
    this.timerTextKey,
    this.phaseLabelColor,
    this.ringColor,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  final String phaseLabel;
  final String timeText;
  final double progress;
  final VoidCallback onTap;
  final Key? timerTextKey;
  final Color? phaseLabelColor;
  final Color? ringColor;
  final bool animate;
  final Duration animationDuration;

  @override
  State<RunSurface> createState() => _RunSurfaceState();
}

class _RunSurfaceState extends State<RunSurface> {
  late double _previousProgress;

  double get _resolvedProgress {
    return widget.progress.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _previousProgress = _resolvedProgress;
  }

  @override
  void didUpdateWidget(covariant RunSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate || widget.animationDuration == Duration.zero) {
      _previousProgress = _resolvedProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color resolvedLabelColor =
        widget.phaseLabelColor?.withValues(alpha: AppTone.labelOpacity) ??
        Colors.white;
    final Color resolvedRingColor = widget.ringColor ?? AppTone.accent;
    final double resolvedProgress = _resolvedProgress;
    final Color trackColor = AppTone.ringTrack;
    final Color progressColor = resolvedRingColor.withValues(alpha: 0.85);
    final Duration effectiveDuration = widget.animate
        ? widget.animationDuration
        : Duration.zero;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.phaseLabel,
                style: TextStyle(
                  color: resolvedLabelColor,
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
                    TweenAnimationBuilder<double>(
                      duration: effectiveDuration,
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(
                        begin: _previousProgress,
                        end: resolvedProgress,
                      ),
                      onEnd: () {
                        if (_previousProgress != resolvedProgress) {
                          setState(() {
                            _previousProgress = resolvedProgress;
                          });
                        }
                      },
                      builder:
                          (
                            BuildContext context,
                            double animatedProgress,
                            Widget? child,
                          ) {
                            return CustomPaint(
                              key: const ValueKey<String>('run-ring'),
                              painter: _RunRingPainter(
                                trackColor: trackColor,
                                progressColor: progressColor,
                                progress: animatedProgress,
                              ),
                            );
                          },
                    ),
                    Center(
                      child: Text(
                        widget.timeText,
                        key: widget.timerTextKey,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 84,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                          height: 0.95,
                          fontFeatures: <ui.FontFeature>[
                            ui.FontFeature.tabularFigures(),
                          ],
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
