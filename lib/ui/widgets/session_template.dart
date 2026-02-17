import 'package:flutter/material.dart';

import '../../features/session/session_controller.dart';
import '../../ui/theme/app_copy.dart';
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
    this.useMonolithicSurface = false,
    this.statusDotColor,
    this.onPresetSelected,
    this.extraContent,
    this.presetLabelBuilder,
    this.focusTimerTextKey,
    this.focusCtaKey,
    this.timerTapTargetKey,
    this.onTimerTap,
    this.showStatusLabel = true,
  });

  final String statusLabel;
  final String timeText;
  final String description;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;
  final List<SessionPreset> presets;
  final SessionPreset selectedPreset;
  final bool useMonolithicSurface;
  final Color? statusDotColor;
  final ValueChanged<SessionPreset>? onPresetSelected;
  final Widget? extraContent;
  final String Function(SessionPreset)? presetLabelBuilder;
  final Key? focusTimerTextKey;
  final Key? focusCtaKey;
  final Key? timerTapTargetKey;
  final VoidCallback? onTimerTap;
  final bool showStatusLabel;

  @override
  Widget build(BuildContext context) {
    if (useMonolithicSurface) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1D22),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 8),
                            const Text(
                              'Resession',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppCopy.appSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA6A6A6),
                              ),
                            ),
                            const SizedBox(height: 48),
                            if (showStatusLabel) ...<Widget>[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: Text(
                                  statusLabel,
                                  key: const ValueKey<String>(
                                    'focus-status-label',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0x80FFFFFF),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            GestureDetector(
                              key: timerTapTargetKey,
                              behavior: HitTestBehavior.opaque,
                              onTap: onTimerTap,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: Text(
                                    timeText,
                                    key: focusTimerTextKey,
                                    style: const TextStyle(
                                      fontSize: 84,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -2,
                                      color: Colors.white,
                                      height: 0.95,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFB5B5B5),
                              ),
                            ),
                            const SizedBox(height: 28),
                            PresetSelector(
                              presets: presets,
                              selectedPreset: selectedPreset,
                              onSelected: onPresetSelected,
                              labelBuilder: presetLabelBuilder,
                            ),
                            if (extraContent != null) ...[
                              const SizedBox(height: 12),
                              extraContent!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryCtaButton(
                    ctaKey: focusCtaKey,
                    label: ctaLabel,
                    onPressed: onCtaPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                            AppCopy.appSubtitle,
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
                  PrimaryCtaButton(
                    ctaKey: focusCtaKey,
                    label: ctaLabel,
                    onPressed: onCtaPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
