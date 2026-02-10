import 'package:flutter/material.dart';

import '../../ui/widgets/session_template.dart';
import 'session_controller.dart';

class EndScreen extends StatelessWidget {
  const EndScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final SessionRunState state = controller.runState;

    return SessionTemplate(
      statusLabel: 'End',
      timeText: '00:00',
      description: 'Session Complete',
      ctaLabel: 'Log / Save',
      onCtaPressed: controller.saveAndReset,
      presets: SessionController.presets,
      selectedPreset: state.preset,
    );
  }
}
