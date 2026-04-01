import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/di/app_services.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  Future<void> _submit(AuthCubit cubit) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (!email.contains('@') || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid email and password (min 6 chars).'),
        ),
      );
      return;
    }
    if (_isSignUp) {
      await cubit.signUp(email, password);
      return;
    }
    await cubit.signIn(email, password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final env = context.read<AppServices>().env;
    final authConfigured = env.hasSupabase;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.infoMessage != null && state.infoMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.infoMessage!)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('Sign in')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (!authConfigured)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Supabase auth is not configured for this build. Run the app with env.production.json.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting || !authConfigured
                        ? null
                        : () => _submit(cubit),
                    child: Text(
                      state.isSubmitting
                          ? 'Please wait...'
                          : (_isSignUp ? 'Create account' : 'Sign in'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.isSubmitting || !authConfigured
                        ? null
                        : cubit.signInWithGoogle,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Continue with Google'),
                  ),
                ),
                TextButton(
                  onPressed: authConfigured
                      ? () => setState(() => _isSignUp = !_isSignUp)
                      : null,
                  child: Text(
                    _isSignUp
                        ? 'Already have account? Sign in'
                        : 'No account? Create one',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
