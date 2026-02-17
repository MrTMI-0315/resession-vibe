import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/widgets/session_template.dart';
import '../../ui/theme/app_tone.dart';
import '../session/session_controller.dart';
import '../session/session_record.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final SessionPreset preset = controller.selectedPreset;
    final List<SessionRecord> recentRecords = controller.records.reversed
        .take(3)
        .toList();
    final bool canStartSession = controller.canStartSession;
    final String? guardrailMessage = controller.startGuardrailMessage;
    final VoidCallback? handleStart = canStartSession
        ? () => controller.startSession(title: controller.pendingSessionTitle)
        : null;

    return SessionTemplate(
      useMonolithicSurface: true,
      focusTimerTextKey: const ValueKey<String>('focus-timer-text'),
      focusCtaKey: const ValueKey<String>('focus-primary-cta'),
      timerTapTargetKey: const ValueKey<String>('idle-timer-tap-target'),
      onTimerTap: handleStart,
      showStatusLabel: false,
      statusLabel: 'Idle',
      timeText: SessionController.formatClock(preset.focusSeconds),
      description: 'Focus • Break ${preset.breakMinutes}m',
      ctaLabel: 'Start session',
      onCtaPressed: handleStart,
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
      extraContent: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: const ValueKey<String>('session-title-input'),
              initialValue: controller.pendingSessionTitle,
              onChanged: controller.updatePendingSessionTitle,
              maxLength: SessionController.maxSessionTitleLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                hintText: '지금 할 일(선택)',
                hintStyle: const TextStyle(color: AppTone.textSecondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: AppTone.surfaceStrong,
                focusColor: AppTone.textPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTone.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTone.textSecondary),
                ),
              ),
              style: const TextStyle(color: AppTone.textPrimary),
            ),
            const SizedBox(height: 10),
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
      key: const ValueKey<String>('recent-sessions-card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTone.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Sessions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTone.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            const Text(
              'No saved sessions yet.',
              style: TextStyle(fontSize: 12, color: AppTone.textMuted),
            )
          else
            ...records.asMap().entries.map((
              MapEntry<int, SessionRecord> entry,
            ) {
              final int index = entry.key;
              final SessionRecord record = entry.value;
              return _RecentSessionRow(
                key: ValueKey<String>('recent-session-row-$index'),
                record: record,
                showDivider: index != records.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _RecentSessionRow extends StatelessWidget {
  const _RecentSessionRow({
    super.key,
    required this.record,
    required this.showDivider,
  });

  final SessionRecord record;
  final bool showDivider;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.22,
    color: AppTone.textPrimary,
  );

  static const TextStyle _titleUntitledStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.22,
    color: AppTone.textMuted,
  );

  static const TextStyle _metaStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppTone.textSecondary,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    final String title = SessionController.displayTitle(record.title);
    final String? lastDriftSummary =
        SessionController.summarizeLastDriftSummary(record.drifts);
    final String presetLabel = _normalizePresetLabel(record.presetLabel);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: title == 'Untitled'
                          ? _titleUntitledStyle
                          : _titleStyle,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 0,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$presetLabel • Focus ${SessionController.formatDurationMMSS(record.actualFocusSeconds)} • ${_formatRecordDateTime(record.endedAt)}',
                          style: _metaStyle,
                        ),
                        if (lastDriftSummary != null)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTone.surfaceStrong,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTone.surfaceBorder),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                lastDriftSummary,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTone.textSecondary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.7,
            color: AppTone.surfaceBorder,
            indent: 2,
            endIndent: 2,
          ),
      ],
    );
  }

  String _formatRecordDateTime(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  String _normalizePresetLabel(String presetLabel) {
    final String trimmedLabel = presetLabel.trim();
    if (trimmedLabel.startsWith('Custom') || trimmedLabel == 'custom') {
      return 'Custom';
    }
    return trimmedLabel;
  }
}
