import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';

import '../models/focus_profile_meta.dart';
import '../services/profile_events.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

import 'package:go_router/go_router.dart';

class FocusProfilesScreen extends StatefulWidget {
  const FocusProfilesScreen({super.key});

  @override
  State<FocusProfilesScreen> createState() => _FocusProfilesScreenState();
}

class _FocusProfilesScreenState extends State<FocusProfilesScreen> {
  final blocker = AppBlocker.instance;
  List<BlockProfile> profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final fetched = await blocker.getProfiles();
      if (!mounted) return;
      setState(() {
        profiles = fetched;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Loading profiles failed: $error');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _createProfile(BlockProfile profile) async {
    try {
      await blocker.createProfile(profile);
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

  Future<String?> _showNameProfileDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Profile Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Study'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (profiles.isEmpty) {
      return Center(
        child: Text(
          'No profiles yet.\nTap "Create Profile" to add one.',
          textAlign: TextAlign.center,
          style: AppFonts.manrope(size: 14, color: AppColors.lightbrown),
        ),
      );
    }

    return ListView.builder(
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final meta = metaFor(profile.id);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(meta.icon),
            title: Text(profile.name),
            subtitle: Text('${profile.appIdentifiers.length} apps blocked'),
            onTap: () async {
              await context.push(
                '/settings/focus-profiles/detail',
                extra: profile,
              );
              await _loadProfiles();
            },
          ),
        );
      },
    );
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
                  onPressed: () async {
                    final name = await _showNameProfileDialog(context);
                    if (name == null || name.trim().isEmpty) return;

                    await _createProfile(
                      BlockProfile(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name.trim(),
                        appIdentifiers: [],
                      ),
                    );
                  },
                  child: const Text('Create Profile'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
