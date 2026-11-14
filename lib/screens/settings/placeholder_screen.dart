import 'package:flutter/material.dart';

/// Temporary "coming soon" page for features that aren't built yet.
///
/// Used in router.dart for the 14-day plan and the Progress tab.
/// Delete it once those screens exist.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  /// Shown in the app bar and in the "coming soon" text.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title – coming soon')),
    );
  }
}
