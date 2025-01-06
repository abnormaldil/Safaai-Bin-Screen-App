import 'dart:async';
import 'package:flutter/material.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;

  const InactivityWrapper({
    Key? key,
    required this.child,
    this.timeoutDuration = const Duration(seconds: 10),
  }) : super(key: key);

  @override
  _InactivityWrapperState createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  late Timer _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer = Timer(widget.timeoutDuration, _navigateToScreensaver);
  }

  void _resetInactivityTimer() {
    if (_inactivityTimer.isActive) {
      _inactivityTimer.cancel();
    }
    _startInactivityTimer();
  }

  void _navigateToScreensaver() {
    Navigator.pushReplacementNamed(context, '/screensaver');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetInactivityTimer, // Reset on user interaction
      onPanDown: (_) => _resetInactivityTimer(), // Detect touch gestures
      child: widget.child,
    );
  }
}
