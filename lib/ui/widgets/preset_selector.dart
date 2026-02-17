import 'package:flutter/material.dart';

import '../../features/session/session_controller.dart';
import '../theme/app_tone.dart';

class PresetSelector extends StatelessWidget {
  const PresetSelector({
    super.key,
    required this.presets,
    required this.selectedPreset,
    this.onSelected,
    this.labelBuilder,
  });

  final List<SessionPreset> presets;
  final SessionPreset selectedPreset;
  final ValueChanged<SessionPreset>? onSelected;
  final String Function(SessionPreset)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTone.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: presets
            .map(
              (SessionPreset preset) => Expanded(
                child: _PresetPill(
                  key: ValueKey<String>('preset-${preset.label}'),
                  label: labelBuilder == null
                      ? preset.label
                      : labelBuilder!(preset),
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
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTone.surfaceBorder : Colors.transparent,
          ),
        ),
        child: Material(
          color: selected ? AppTone.surfaceStrong : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected)
                      Icon(
                        Icons.check,
                        key: ValueKey<String>('preset-check-$label'),
                        size: 14,
                        color: AppTone.textPrimary,
                      ),
                    if (selected) const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppTone.textPrimary
                              : AppTone.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
