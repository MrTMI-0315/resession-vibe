import 'package:flutter/material.dart';

import '../../ui/widgets/run_surface.dart';
import 'session_controller.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('screen-focus'),
      backgroundColor: const Color(0xFF1A1D22),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: RunSurface(
            key: const ValueKey<String>('run-surface'),
            phaseLabel: 'Focus',
            timerTextKey: const ValueKey<String>('run-timer-text'),
            timeText: SessionController.formatClock(
              controller.currentFocusRemainingSeconds,
            ),
            onTap: controller.pauseForBreak,
            ringColor: const Color(0xFF89CBFD),
            phaseLabelColor: const Color(0xFFD3E9FF),
          ),
        ),
      ),
    );
  }
}
