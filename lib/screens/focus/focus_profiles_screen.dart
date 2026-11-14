import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/focus/focus_profile_meta.dart';
import '../../services/focus/profile_events.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/common/text_input_dialog.dart';

/// All focus profiles, opened from Settings → Edit profiles.
///
/// Tap a profile to open its detail page; "Create Profile" adds a new,
/// empty profile with the name the user types.
class FocusProfilesScreen extends StatefulWidget {
  const FocusProfilesScreen({super.key});

  @override
  State<FocusProfilesScreen> createState() => _FocusProfilesScreenState();
}

class _FocusProfilesScreenState extends State<FocusProfilesScreen> {
  final _blocker = AppBlocker.instance;
  List<BlockProfile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final fetched = await _blocker.getProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = fetched;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Loading profiles failed: $error');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Asks for a name and creates an empty profile with it.
  Future<void> _onCreatePressed() async {
    final name = await showTextInputDialog(
      context,
      title: 'Enter Profile Name',
      hint: 'e.g. Study',
      confirmLabel: 'Create',
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      await _blocker.createProfile(
        BlockProfile(
          // The creation time is unique enough as an id.
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.trim(),
          appIdentifiers: [],
        ),
      );
      profilesChanged.value++;
      await _loadProfiles();
    } catch (error) {
      debugPrint('Creating profile failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't create the profile. Try again."),
        ),
      );
    }
  }

  /// Opens the detail page and reloads afterwards (it may have been renamed or deleted).
  Future<void> _openProfile(BlockProfile profile) async {
    await context.push('/settings/focus-profiles/detail', extra: profile);
    await _loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Profiles')),
      body: Column(
        children: [
          Expanded(child: _buildList()),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onCreatePressed,
                  child: const Text('Create Profile'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_profiles.isEmpty) {
      return Center(
        child: Text(
          'No profiles yet.\nTap "Create Profile" to add one.',
          textAlign: TextAlign.center,
          style: AppFonts.manrope(size: 14, color: context.palette.muted),
        ),
      );
    }

    return ListView.builder(
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(metaFor(profile.id).icon),
            title: Text(profile.name),
            subtitle: Text('${profile.appIdentifiers.length} apps blocked'),
            onTap: () => _openProfile(profile),
          ),
        );
      },
    );
  }
}
