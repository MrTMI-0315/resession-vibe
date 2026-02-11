import 'dart:async';

import 'package:flutter/material.dart';

import '../history/history_screen.dart';
import '../../ui/widgets/session_template.dart';
import '../session/session_controller.dart';
import '../session/session_record.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final SessionPreset preset = controller.selectedPreset;
    final List<SessionRecord> recentRecords = controller.records.reversed
        .take(5)
        .toList();
    final bool canStartSession = controller.canStartSession;
    final String? guardrailMessage = controller.startGuardrailMessage;

    return SessionTemplate(
      statusLabel: 'Idle',
      timeText: SessionController.formatClock(preset.focusSeconds),
      description: 'Focus • Break ${preset.breakMinutes}m',
      ctaLabel: 'Start session',
      onCtaPressed: canStartSession
          ? () => controller.startSession(title: controller.pendingSessionTitle)
          : null,
      presets: SessionController.presets,
      selectedPreset: preset,
      onPresetSelected: (SessionPreset selected) {
        if (selected.label != SessionController.customPresetLabel) {
          controller.selectPreset(selected);
          return;
        }
        unawaited(_openCustomPresetSheet(context));
      },
      presetLabelBuilder: controller.presetDisplayLabel,
      extraContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const ValueKey<String>('session-title-input'),
            initialValue: controller.pendingSessionTitle,
            onChanged: controller.updatePendingSessionTitle,
            decoration: InputDecoration(
              hintText: '지금 할 일(선택)',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F1F1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey<String>('history-nav-button'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HistoryScreen(controller: controller),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
              ),
              child: const Text('History'),
            ),
          ),
          const SizedBox(height: 6),
          if (guardrailMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                guardrailMessage,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFAB3A3A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          _RecentSessionsSection(records: recentRecords),
        ],
      ),
    );
  }

  Future<void> _openCustomPresetSheet(BuildContext context) async {
    final int initialFocus =
        controller.configuredCustomFocusMinutes ??
        SessionController.presets.first.focusMinutes;
    final int initialBreak =
        controller.configuredCustomBreakMinutes ??
        SessionController.presets.first.breakMinutes;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _CustomPresetBottomSheet(
          initialFocus: initialFocus,
          initialBreak: initialBreak,
          onConfirm: (int focusMinutes, int breakMinutes) {
            controller.selectCustomPreset(focusMinutes, breakMinutes);
          },
        );
      },
    );
  }
}

class _CustomPresetBottomSheet extends StatefulWidget {
  const _CustomPresetBottomSheet({
    required this.initialFocus,
    required this.initialBreak,
    required this.onConfirm,
  });

  final int initialFocus;
  final int initialBreak;
  final void Function(int focusMinutes, int breakMinutes) onConfirm;

  @override
  State<_CustomPresetBottomSheet> createState() =>
      _CustomPresetBottomSheetState();
}

class _CustomPresetBottomSheetState extends State<_CustomPresetBottomSheet> {
  late final TextEditingController _focusController;
  late final TextEditingController _breakController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusController = TextEditingController(text: '${widget.initialFocus}');
    _breakController = TextEditingController(text: '${widget.initialBreak}');
  }

  @override
  void dispose() {
    _focusController.dispose();
    _breakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets bottomInset = EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    );

    return Padding(
      padding: bottomInset,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Custom preset',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('custom-focus-input'),
                controller: _focusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Focus minutes'),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('custom-break-input'),
                controller: _breakController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Break minutes'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAB3A3A),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey<String>('custom-cancel-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      key: const ValueKey<String>('custom-confirm-button'),
                      onPressed: _onConfirmPressed,
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onConfirmPressed() {
    final int? focus = int.tryParse(_focusController.text.trim());
    final int? rest = int.tryParse(_breakController.text.trim());

    if (focus == null || rest == null || focus <= 0 || rest <= 0) {
      setState(() {
        _errorText = 'Enter positive integers.';
      });
      return;
    }

    widget.onConfirm(focus, rest);
    Navigator.of(context).pop();
  }
}

class _RecentSessionsSection extends StatelessWidget {
  const _RecentSessionsSection({required this.records});

  final List<SessionRecord> records;

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
            'Recent Sessions',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            const Text(
              'No saved sessions yet.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6D6D6D)),
            )
          else
            ...records.map((SessionRecord record) {
              final String? lastDriftCategory =
                  SessionController.summarizeLastDriftCategory(record.drifts);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${SessionController.displayTitle(record.title)} • ${record.presetLabel} • Focus ${SessionController.formatDurationMMSS(record.actualFocusSeconds)}${lastDriftCategory == null ? '' : ' • Drift $lastDriftCategory'} • ${_formatDateTime(record.endedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}
