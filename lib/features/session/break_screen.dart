import 'package:flutter/material.dart';

import '../../ui/widgets/session_template.dart';
import 'session_controller.dart';

class BreakScreen extends StatelessWidget {
  const BreakScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final SessionRunState state = controller.runState;

    return SessionTemplate(
      statusLabel: 'Break',
      statusDotColor: const Color(0xFFF18E6D),
      timeText: SessionController.formatClock(
        controller.currentBreakRemainingSeconds,
      ),
      description: 'Break ${state.preset.breakMinutes}m',
      ctaLabel: 'Resume',
      onCtaPressed: controller.resumeFocus,
      presets: SessionController.presets,
      selectedPreset: state.preset,
    );
  }
}
