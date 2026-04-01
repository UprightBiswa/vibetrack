import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_cubit.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_state.dart';
import 'package:vibetreck/core/bloc/view_status.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CurrentProfileCubit, CurrentProfileState>(
      listener: (context, state) {
        if (_saving && state.status == ViewStatus.success) {
          _saving = false;
          Navigator.of(context).pop();
        }
        if (state.status == ViewStatus.failure && state.errorMessage != null) {
          _saving = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final profile = state.profile;
        if (state.status == ViewStatus.loading && profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not found')),
          );
        }

        if (!_initialized) {
          _usernameController.text = profile.username;
          _cityController.text = profile.homeCity;
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: ListView(
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
                onPressed: state.status == ViewStatus.loading
                    ? null
                    : () {
                        _saving = true;
                        context.read<CurrentProfileCubit>().updateProfile(
                              username: _usernameController.text.trim(),
                              homeCity: _cityController.text.trim(),
                            );
                      },
                child: Text(
                  state.status == ViewStatus.loading ? 'Saving...' : 'Save Changes',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
