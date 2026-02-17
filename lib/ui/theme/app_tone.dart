import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract class AppTone {
  static const Color accent = Color(0xFF6E76FF);
  static const Color focusTone = accent;
  static const Color breakTone = Color(0xFFC2A87A);
  static const Color ringTrack = Color(0x1FFFFFFF);
  static const Color surface = Color(0x14FFFFFF);
  static const Color surfaceStrong = Color(0x1FFFFFFF);
  static const Color surfaceBorder = Color(0x1AFFFFFF);
  static const Color tabBarBackground = Color(0xFF191B20);
  static const Color tabBarBorder = Color(0x1FFFFFFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xA6FFFFFF);
  static const Color textMuted = Color(0x73FFFFFF);
  static const double labelOpacity = 0.72;
  static const Color tabInactive = CupertinoColors.systemGrey;
}
