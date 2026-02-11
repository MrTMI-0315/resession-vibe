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
      presetLabelBuilder: controller.presetDisplayLabel,
      extraContent: _EndSummary(
        title: state.sessionTitle,
        presetLabel: controller.presetDisplayLabel(state.preset),
        plannedFocusSeconds: state.preset.focusSeconds,
        plannedBreakSeconds: state.preset.breakSeconds,
        actualFocusSeconds: controller.actualFocusElapsedSeconds,
        actualBreakSeconds: controller.actualBreakElapsedSeconds,
        startedAt: state.startedAt,
        endedAt: state.endedAt,
        lastDriftCategory: controller.currentLastDriftCategory,
      ),
    );
  }
}

class _EndSummary extends StatelessWidget {
  const _EndSummary({
    required this.title,
    required this.presetLabel,
    required this.plannedFocusSeconds,
    required this.plannedBreakSeconds,
    required this.actualFocusSeconds,
    required this.actualBreakSeconds,
    required this.startedAt,
    required this.endedAt,
    required this.lastDriftCategory,
  });

  final String? title;
  final String presetLabel;
  final int plannedFocusSeconds;
  final int plannedBreakSeconds;
  final int actualFocusSeconds;
  final int actualBreakSeconds;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? lastDriftCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Summary',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Title: ${SessionController.displayTitle(title)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text('Preset: $presetLabel', style: const TextStyle(fontSize: 12)),
          Text(
            'Planned: Focus ${SessionController.formatDurationMMSS(plannedFocusSeconds)} • Break ${SessionController.formatDurationMMSS(plannedBreakSeconds)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Actual: Focus ${SessionController.formatDurationMMSS(actualFocusSeconds)} • Break ${SessionController.formatDurationMMSS(actualBreakSeconds)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (lastDriftCategory != null)
            Text(
              'Last drift: $lastDriftCategory',
              style: const TextStyle(fontSize: 12),
            ),
          Text(
            'Start: ${_formatDateTime(startedAt)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'End: ${_formatDateTime(endedAt)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}
