// Create a new file: screen_wrapper.dart
import 'package:flutter/material.dart';

class ScreenWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;

  const ScreenWrapper({
    super.key,
    required this.child,
    required this.screenName,
  });

  @override
  State<ScreenWrapper> createState() => _ScreenWrapperState();
}

class _ScreenWrapperState extends State<ScreenWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // Don't keep alive by default

  @override
  void dispose() {
    // Clean up any controllers, streams, timers here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
