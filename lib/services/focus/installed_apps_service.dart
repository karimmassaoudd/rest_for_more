import 'package:app_blocker/app_blocker.dart';

/// The apps installed on this phone, loaded once and then kept in memory
/// (loading them with icons is slow).
class InstalledAppsService {
  InstalledAppsService._();

  static List<AppInfo>? _cache;

  static Future<List<AppInfo>> getApps() async =>
      _cache ??= await AppBlocker.instance.getApps();
}
