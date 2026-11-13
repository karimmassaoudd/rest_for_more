import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';

/// Read-only list of apps: one card per app with its icon and name.
/// Falls back to a generic icon when the app has none.
class AppInfoList extends StatelessWidget {
  const AppInfoList({super.key, required this.apps});

  final List<AppInfo> apps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final app in apps)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: app.icon != null
                  ? Image.memory(app.icon!, width: 32, height: 32)
                  : const Icon(Icons.apps),
              title: Text(app.appName),
            ),
          ),
      ],
    );
  }
}
