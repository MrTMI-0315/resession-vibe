import 'package:flutter/material.dart';

class SessionStatusCard extends StatelessWidget {
  const SessionStatusCard({
    super.key,
    required this.statusLabel,
    required this.timeText,
    required this.description,
    this.dotColor,
  });

  final String statusLabel;
  final String timeText;
  final String description;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F1EF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusChip(label: statusLabel, dotColor: dotColor),
          const SizedBox(height: 18),
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.dotColor});

  final String label;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECEBE9),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
