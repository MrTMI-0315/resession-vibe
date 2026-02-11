import 'package:flutter/material.dart';

import '../../features/session/session_controller.dart';
import 'preset_selector.dart';
import 'primary_cta_button.dart';
import 'session_status_card.dart';

class SessionTemplate extends StatelessWidget {
  const SessionTemplate({
    super.key,
    required this.statusLabel,
    required this.timeText,
    required this.description,
    required this.ctaLabel,
    required this.onCtaPressed,
    required this.presets,
    required this.selectedPreset,
    this.statusDotColor,
    this.onPresetSelected,
    this.extraContent,
    this.presetLabelBuilder,
  });

  final String statusLabel;
  final String timeText;
  final String description;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;
  final List<SessionPreset> presets;
  final SessionPreset selectedPreset;
  final Color? statusDotColor;
  final ValueChanged<SessionPreset>? onPresetSelected;
  final Widget? extraContent;
  final String Function(SessionPreset)? presetLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1D20),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resession',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'See your focus patterns',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8B8B8B),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SessionStatusCard(
                            statusLabel: statusLabel,
                            timeText: timeText,
                            description: description,
                            dotColor: statusDotColor,
                          ),
                          const SizedBox(height: 16),
                          PresetSelector(
                            presets: presets,
                            selectedPreset: selectedPreset,
                            onSelected: onPresetSelected,
                            labelBuilder: presetLabelBuilder,
                          ),
                          if (extraContent != null) ...[
                            const SizedBox(height: 16),
                            extraContent!,
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryCtaButton(label: ctaLabel, onPressed: onCtaPressed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
