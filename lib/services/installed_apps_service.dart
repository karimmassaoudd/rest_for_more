import 'package:app_blocker/app_blocker.dart';

class InstalledAppsService {
  static List<AppInfo>? _cache;

  static Future<List<AppInfo>> getApps({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    _cache = await AppBlocker.instance.getApps();
    return _cache!;
  }
}
