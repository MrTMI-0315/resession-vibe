import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/session/session_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.timer,
              key: const ValueKey<String>('tab-focus'),
            ),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.chart_bar,
              key: const ValueKey<String>('tab-insights'),
            ),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.time,
              key: const ValueKey<String>('tab-history'),
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.gear,
              key: const ValueKey<String>('tab-settings'),
            ),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            return switch (index) {
              0 => HomeScreen(
                key: const ValueKey<String>('screen-focus'),
                controller: controller,
              ),
              1 => InsightsScreen(
                key: const ValueKey<String>('screen-insights'),
                controller: controller,
              ),
              2 => HistoryScreen(
                key: const ValueKey<String>('screen-history'),
                controller: controller,
              ),
              _ => const _SettingsScreen(),
            };
          },
        );
      },
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: ValueKey<String>('screen-settings'),
      backgroundColor: Color(0xFF1C1D20),
      body: Center(
        child: Text(
          'Settings coming soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
