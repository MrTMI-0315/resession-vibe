import 'package:flutter/material.dart';

import '../../ui/widgets/run_surface.dart';
import 'session_controller.dart';

class BreakScreen extends StatelessWidget {
  const BreakScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('screen-break'),
      backgroundColor: const Color(0xFF1A1D22),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: RunSurface(
            key: const ValueKey<String>('run-surface'),
            phaseLabel: 'Break',
            timerTextKey: const ValueKey<String>('run-timer-text'),
            timeText: SessionController.formatClock(
              controller.currentBreakRemainingSeconds,
            ),
            onTap: controller.resumeFocus,
            ringColor: const Color(0xFFF18E6D),
            phaseLabelColor: const Color(0xFFFFD8C5),
          ),
        ),
      ),
    );
  }
}
