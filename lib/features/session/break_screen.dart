import 'package:flutter/material.dart';

import '../../ui/widgets/run_surface.dart';
import '../../ui/theme/app_tone.dart';
import 'session_controller.dart';

class BreakScreen extends StatelessWidget {
  const BreakScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final int totalSeconds = controller.runState.preset.breakSeconds;
    final int remainingSeconds = controller.currentBreakRemainingSeconds;
    final int clampedRemainingSeconds = remainingSeconds.clamp(0, totalSeconds);
    final double progress = totalSeconds <= 0
        ? 0.0
        : 1.0 - (clampedRemainingSeconds / totalSeconds);

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
            progress: progress,
            onTap: controller.resumeFocus,
            phaseLabelColor: AppTone.breakTone,
            ringColor: AppTone.breakTone,
          ),
        ),
      ),
    );
  }
}
