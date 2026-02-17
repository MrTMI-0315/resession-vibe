import 'package:flutter/material.dart';

class RunSurface extends StatelessWidget {
  const RunSurface({
    super.key,
    required this.phaseLabel,
    required this.timeText,
    required this.onTap,
    this.timerTextKey,
    this.phaseLabelColor,
    this.ringColor,
  });

  final String phaseLabel;
  final String timeText;
  final VoidCallback onTap;
  final Key? timerTextKey;
  final Color? phaseLabelColor;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final Color resolvedLabelColor = phaseLabelColor ?? Colors.white;
    final Color resolvedRingColor = ringColor ?? Colors.white;

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
                      painter: _RunRingPainter(color: resolvedRingColor),
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
  const _RunRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide / 2) - 8;

    final Paint outerRing = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outerRing);

    final Paint innerRing = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, innerRing);
  }

  @override
  bool shouldRepaint(covariant _RunRingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
