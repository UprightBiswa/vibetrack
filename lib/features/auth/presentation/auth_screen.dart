import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  String? _info;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (!email.contains('@') || password.length < 6) {
      setState(
        () => _error = 'Enter a valid email and password (min 6 chars).',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final actions = ref.read(authActionsProvider);
      if (_isSignUp) {
        await actions.signUp(email, password);
        if (!mounted) return;
        setState(() {
          _info =
              'Account created. If email confirmation is enabled, verify your email to continue.';
        });
      } else {
        await actions.signIn(email, password);
      }
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(err));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object err) {
    final message = err.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) return 'Authentication failed. Please try again.';
    return message;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            if (_info != null) ...[
              const SizedBox(height: 12),
              Text(
                _info!,
                style: const TextStyle(color: Colors.lightGreenAccent),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(
                  _loading
                      ? 'Please wait...'
                      : (_isSignUp ? 'Create account' : 'Sign in'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        try {
                          await ref
                              .read(authActionsProvider)
                              .signInWithGoogle();
                        } catch (err) {
                          if (!mounted) return;
                          setState(() => _error = _friendlyError(err));
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Continue with Google'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
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
  }
}
