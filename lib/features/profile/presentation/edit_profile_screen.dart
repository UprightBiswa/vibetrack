import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/features/profile/application/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _status;

  @override
  void dispose() {
    _usernameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          if (!_initialized) {
            _usernameController.text = profile.username;
            _cityController.text = profile.homeCity;
            _initialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Home City'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final router = GoRouter.of(context);
                        setState(() {
                          _saving = true;
                          _status = null;
                        });
                        try {
                          await ref.read(profileActionsProvider).updateProfile(
                            username: _usernameController.text.trim(),
                            homeCity: _cityController.text.trim(),
                          );
                          if (!mounted) {
                            return;
                          }
                          setState(() => _status = 'Profile updated');
                          router.pop();
                        } catch (error) {
                          setState(() => _status = error.toString());
                        } finally {
                          if (mounted) {
                            setState(() => _saving = false);
                          }
                        }
                      },
                child: Text(_saving ? 'Saving...' : 'Save Changes'),
              ),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!, style: const TextStyle(color: Colors.white70)),
              ],
            ],
          );
        },
      ),
    );
  }
}
