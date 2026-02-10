import 'package:flutter/material.dart';

import '../../features/session/session_controller.dart';

class PresetSelector extends StatelessWidget {
  const PresetSelector({
    super.key,
    required this.presets,
    required this.selectedPreset,
    this.onSelected,
  });

  final List<SessionPreset> presets;
  final SessionPreset selectedPreset;
  final ValueChanged<SessionPreset>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: presets
            .map(
              (SessionPreset preset) => Expanded(
                child: _PresetPill(
                  key: ValueKey<String>('preset-${preset.label}'),
                  preset: preset,
                  selected: preset.label == selectedPreset.label,
                  onTap: onSelected == null ? null : () => onSelected!(preset),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final SessionPreset preset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? const Color(0xFFE8E7E5) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                preset.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF111111)
                      : const Color(0xFFB7B7B7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
