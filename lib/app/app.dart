import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../features/session/break_screen.dart';
import '../features/session/end_screen.dart';
import '../features/session/session_controller.dart';
import '../features/session/session_screen.dart';

class ResessionApp extends StatefulWidget {
  const ResessionApp({super.key, this.controller});

  final SessionController? controller;

  @override
  State<ResessionApp> createState() => _ResessionAppState();
}

class _ResessionAppState extends State<ResessionApp> {
  late final SessionController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SessionController();
    _ownsController = widget.controller == null;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'SF Pro Text',
            scaffoldBackgroundColor: const Color(0xFF1C1D20),
          ),
          home: _buildScreen(),
        );
      },
    );
  }

  Widget _buildScreen() {
    switch (_controller.runState.phase) {
      case SessionPhase.idle:
        return HomeScreen(controller: _controller);
      case SessionPhase.focus:
        return SessionScreen(controller: _controller);
      case SessionPhase.breakTime:
        return BreakScreen(controller: _controller);
      case SessionPhase.ended:
        return EndScreen(controller: _controller);
    }
  }
}
