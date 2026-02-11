import 'package:flutter/material.dart';

import '../../ui/widgets/session_template.dart';
import 'session_controller.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final SessionRunState state = controller.runState;

    return SessionTemplate(
      statusLabel: 'Focus',
      statusDotColor: const Color(0xFF89CBFD),
      timeText: SessionController.formatClock(
        controller.currentFocusRemainingSeconds,
      ),
      description: 'Focus • Break ${state.preset.breakMinutes}m',
      ctaLabel: 'Pause',
      onCtaPressed: controller.pauseForBreak,
      presets: SessionController.presets,
      selectedPreset: state.preset,
      presetLabelBuilder: controller.presetDisplayLabel,
    );
  }
}
