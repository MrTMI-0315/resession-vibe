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
      extraContent: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          key: const ValueKey<String>('drift-open-button'),
          onPressed: () => _openDriftBottomSheet(context),
          child: const Text('Drift'),
        ),
      ),
    );
  }

  Future<void> _openDriftBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _DriftBottomSheet(
          categories: SessionController.driftCategories,
          onConfirm: (String category, String? note) {
            controller.logDrift(category: category, note: note);
          },
        );
      },
    );
  }
}

class _DriftBottomSheet extends StatefulWidget {
  const _DriftBottomSheet({required this.categories, required this.onConfirm});

  final List<String> categories;
  final void Function(String category, String? note) onConfirm;

  @override
  State<_DriftBottomSheet> createState() => _DriftBottomSheetState();
}

class _DriftBottomSheetState extends State<_DriftBottomSheet> {
  final TextEditingController _noteController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _noteController.dispose();
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
                'Drift log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.categories
                    .map((String category) {
                      return ChoiceChip(
                        key: ValueKey<String>('drift-category-$category'),
                        label: Text(category),
                        selected: category == _selectedCategory,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('drift-note-input'),
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey<String>('drift-cancel-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      key: const ValueKey<String>('drift-confirm-button'),
                      onPressed: _selectedCategory == null
                          ? null
                          : () {
                              widget.onConfirm(
                                _selectedCategory!,
                                _noteController.text.trim().isEmpty
                                    ? null
                                    : _noteController.text.trim(),
                              );
                              Navigator.of(context).pop();
                            },
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
}
