import 'package:flutter/material.dart';

class PrimaryCtaButton extends StatelessWidget {
  const PrimaryCtaButton({
    super.key,
    this.ctaKey,
    required this.label,
    required this.onPressed,
  });

  final Key? ctaKey;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        key: ctaKey,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCFE6F9),
          foregroundColor: const Color(0xFF121212),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
