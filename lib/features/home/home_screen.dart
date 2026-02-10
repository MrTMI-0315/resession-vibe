import 'package:flutter/material.dart';

import '../../ui/widgets/session_template.dart';
import '../session/session_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final SessionPreset preset = controller.selectedPreset;

    return SessionTemplate(
      statusLabel: 'Idle',
      timeText: SessionController.formatClock(preset.focusSeconds),
      description: 'Focus • Break ${preset.breakMinutes}m',
      ctaLabel: 'Start session',
      onCtaPressed: controller.startSession,
      presets: SessionController.presets,
      selectedPreset: preset,
      onPresetSelected: controller.selectPreset,
    );
  }
}
