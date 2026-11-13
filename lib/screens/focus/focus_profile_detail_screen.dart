import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/focus/focus_profile_meta.dart';
import '../../models/focus/hard_always_available_apps.dart';

import '../../services/focus/always_available_apps_store.dart';
import '../../services/focus/installed_apps_service.dart';
import '../../services/focus/profile_edit_guard.dart';
import '../../services/focus/profile_events.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/text_input_dialog.dart';
import '../../widgets/focus/app_info_list.dart';

/// Detail page for one focus profile: rename or delete it, and see and
/// edit its blocked apps and always-available apps.
///
/// Nothing can be changed while a focus session is running.
/// Core profiles (focus, read, morning, evening) can't be renamed or deleted.
class FocusProfileDetailScreen extends StatefulWidget {
  const FocusProfileDetailScreen({super.key, required this.profile});

  final BlockProfile profile;

  @override
  State<FocusProfileDetailScreen> createState() =>
      _FocusProfileDetailScreenState();
}

class _FocusProfileDetailScreenState extends State<FocusProfileDetailScreen> {
  final _blocker = AppBlocker.instance;
  final _store = AlwaysAvailableAppsStore();

  /// All installed apps, used to turn package names into names + icons.
  List<AppInfo> _allApps = [];
  Set<String> _alwaysAvailableApps = {};

  /// Updated after a rename or a change in blocked apps.
  late BlockProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadData();
  }

  // ------------------------------------------------------------------
  // Loading
  // ------------------------------------------------------------------

  Future<void> _loadData() async {
    final apps = await InstalledAppsService.getApps();
    if (!mounted) return;
    setState(() => _allApps = apps);
    await _loadAlwaysAvailableApps();
  }

  Future<void> _loadAlwaysAvailableApps() async {
    final alwaysAvailable = await _store.getAlwaysAvailableApps(_profile.id);
    if (!mounted) return;
    setState(() {
      _alwaysAvailableApps = getHardAlwaysAvailableApps(
        alwaysAvailable.toSet(),
      );
    });
  }

  /// Reloads this profile from the blocker (after a rename or app change).
  Future<void> _refreshProfile() async {
    final all = await _blocker.getProfiles();
    final updated = all.firstWhere(
      (p) => p.id == _profile.id,
      orElse: () => _profile,
    );
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  /// The installed apps for these package names (uninstalled ones are skipped).
  List<AppInfo> _resolveApps(Iterable<String> packageNames) {
    return _allApps
        .where((app) => packageNames.contains(app.packageName))
        .toList();
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  Future<void> _renameProfile() async {
    if (!await profileEditingAllowed(context)) return;
    if (!mounted) return;

    if (metaFor(_profile.id).isCore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Core profiles cannot be renamed')),
      );
      return;
    }

    final newName = await showTextInputDialog(
      context,
      title: 'Rename Profile',
      initialValue: _profile.name,
      confirmLabel: 'Save',
      autofocus: true,
    );
    if (newName == null || newName.trim().isEmpty) return;

    await _blocker.updateProfile(
      BlockProfile(
        id: _profile.id,
        name: newName.trim(),
        appIdentifiers: _profile.appIdentifiers,
      ),
    );
    profilesChanged.value++;
    await _refreshProfile();
  }

  Future<void> _deleteProfile() async {
    if (!await profileEditingAllowed(context)) return;
    if (!mounted) return;

    if (metaFor(_profile.id).isCore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${_profile.name} is built into Rest For More and can't be deleted. You can still customize which apps it blocks.",
          ),
        ),
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete profile?',
      message:
          'This will permanently delete the ${_profile.name} profile. '
          'Are you sure?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;

    await _blocker.deleteProfile(_profile.id);
    await _store.removeProfile(_profile.id);
    profilesChanged.value++;

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _editBlockedApps() async {
    if (!await profileEditingAllowed(context)) return;
    if (!mounted) return;

    final changed = await context.push<bool>(
      '/settings/focus-profiles/detail/blocked-apps',
      extra: _profile,
    );
    if (changed != true) return;

    await _refreshProfile();
    profilesChanged.value++;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blocked apps updated successfully')),
      );
    }
  }

  Future<void> _editAlwaysAvailableApps() async {
    if (!await profileEditingAllowed(context)) return;
    if (!mounted) return;

    final changed = await context.push<bool>(
      '/settings/focus-profiles/detail/always-available',
      extra: _profile,
    );
    if (changed != true) return;

    await _loadAlwaysAvailableApps();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Always available apps updated successfully'),
        ),
      );
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final blockedApps = _resolveApps(_profile.appIdentifiers);
    final alwaysAvailableApps = _resolveApps(_alwaysAvailableApps);
    final meta = metaFor(_profile.id);
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(_profile.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Icon(meta.icon, size: 40, color: palette.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _profile.name,
                  style: AppFonts.cormorant(
                    size: 24,
                    weight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _renameProfile,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteProfile,
              ),
            ],
          ),
          const Divider(height: 32),
          _SectionHeader(
            title: 'Blocked apps · ${blockedApps.length} blocked',
            onEdit: _editBlockedApps,
          ),
          AppInfoList(apps: blockedApps),
          const Divider(height: 32),
          _SectionHeader(
            title:
                'Always available apps · ${alwaysAvailableApps.length} available',
            onEdit: _editAlwaysAvailableApps,
          ),
          AppInfoList(apps: alwaysAvailableApps),
        ],
      ),
    );
  }
}

/// Section title with an "edit" button on the right.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onEdit});

  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppFonts.manrope(
              size: 15,
              weight: FontWeight.w600,
              color: context.palette.text,
            ),
          ),
        ),
        TextButton(onPressed: onEdit, child: const Text('edit')),
      ],
    );
  }
}
