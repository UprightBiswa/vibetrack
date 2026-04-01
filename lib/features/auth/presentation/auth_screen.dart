import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/di/app_services.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
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
  bool _obscurePassword = true;
  String? _localError;

  Future<void> _submit(AuthCubit cubit) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _localError = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _localError = null);
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
    final theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final statusMessage = _localError ?? state.errorMessage ?? state.infoMessage;
        final statusTone = _localError != null || state.errorMessage != null
            ? _StatusTone.error
            : _StatusTone.info;

        return Scaffold(
          body: Stack(
            children: [
              const _AuthBackground(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 980;
                          if (!wide) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BrandPanel(theme: theme),
                                const SizedBox(height: 20),
                                _AuthPanel(
                                  theme: theme,
                                  isSignUp: _isSignUp,
                                  obscurePassword: _obscurePassword,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  isSubmitting: state.isSubmitting,
                                  authConfigured: authConfigured,
                                  statusMessage: statusMessage,
                                  statusTone: statusTone,
                                  onModeChanged: (value) {
                                    setState(() {
                                      _isSignUp = value;
                                      _localError = null;
                                    });
                                  },
                                  onTogglePassword: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                  onSubmit: () => _submit(cubit),
                                  onGoogle: cubit.signInWithGoogle,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 24),
                                  child: _BrandPanel(theme: theme),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: _AuthPanel(
                                  theme: theme,
                                  isSignUp: _isSignUp,
                                  obscurePassword: _obscurePassword,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  isSubmitting: state.isSubmitting,
                                  authConfigured: authConfigured,
                                  statusMessage: statusMessage,
                                  statusTone: statusTone,
                                  onModeChanged: (value) {
                                    setState(() {
                                      _isSignUp = value;
                                      _localError = null;
                                    });
                                  },
                                  onTogglePassword: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                  onSubmit: () => _submit(cubit),
                                  onGoogle: cubit.signInWithGoogle,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF131313)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.95, -0.9),
              radius: 1,
              colors: [
                AppTheme.primary.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1, 1),
              radius: 0.9,
              colors: [
                AppTheme.secondary.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
        CustomPaint(painter: _DotGridPainter()),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.28)),
            ),
            child: Text(
              'NEXT GEN PERFORMANCE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'VIBETRACK',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 0.9,
              letterSpacing: -4,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              'The elite digital dashboard for high-octane athletes. Synchronize your biometrics, track your pulse, and join the global movement.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const [
              _HeroBento(
                icon: Icons.bolt_rounded,
                value: '184',
                label: 'AVG BPM',
                iconColor: AppTheme.secondary,
              ),
              _HeroBento(
                icon: Icons.auto_graph_rounded,
                value: '+24%',
                label: 'STAMINA GROWTH',
                iconColor: AppTheme.primary,
              ),
              _HeroBento(
                icon: Icons.flag_circle_rounded,
                value: 'LEAGUE',
                label: 'READY',
                iconColor: Colors.white,
                visualOnly: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBento extends StatelessWidget {
  const _HeroBento({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    this.visualOnly = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final bool visualOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      height: 160,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.22)),
      ),
      child: visualOnly
          ? Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          AppTheme.primary.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Icon(icon, color: iconColor, size: 34),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '$value\n$label',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 0.92,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 34),
                const Spacer(),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.theme,
    required this.isSignUp,
    required this.obscurePassword,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.authConfigured,
    required this.statusMessage,
    required this.statusTone,
    required this.onModeChanged,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onGoogle,
  });

  final ThemeData theme;
  final bool isSignUp;
  final bool obscurePassword;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final bool authConfigured;
  final String? statusMessage;
  final _StatusTone statusTone;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.18)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModeSwitcher(
                isSignUp: isSignUp,
                onChanged: onModeChanged,
              ),
              const SizedBox(height: 24),
              if (!authConfigured)
                _StatusBanner(
                  message:
                      'Supabase auth is not configured for this build. Run the app with env.production.json.',
                  tone: _StatusTone.warning,
                ),
              if (!authConfigured) const SizedBox(height: 16),
              if (statusMessage != null && statusMessage!.trim().isNotEmpty) ...[
                _StatusBanner(
                  message: statusMessage!,
                  tone: statusTone,
                ),
                const SizedBox(height: 16),
              ],
              _InputLabel(text: 'Email Address'),
              const SizedBox(height: 8),
              _CyberTextField(
                controller: emailController,
                hintText: 'athlete@vibetrack.io',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                enabled: !isSubmitting && authConfigured,
              ),
              const SizedBox(height: 18),
              _InputLabel(text: 'Access Code'),
              const SizedBox(height: 8),
              _CyberTextField(
                controller: passwordController,
                hintText: '��������',
                icon: Icons.lock_open_rounded,
                obscureText: obscurePassword,
                enabled: !isSubmitting && authConfigured,
                trailing: IconButton(
                  onPressed: authConfigured ? onTogglePassword : null,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: null,
                  child: Text(
                    'FORGOT?',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isSubmitting || !authConfigured ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(62),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isSubmitting
                          ? 'PROCESSING...'
                          : (isSignUp ? 'JOIN THE LEAGUE' : 'ENTER DASHBOARD'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isSubmitting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    else
                      const Icon(Icons.east_rounded, color: Colors.black),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR SYNC VIA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white12)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      icon: _GoogleGlyph(),
                      label: 'GOOGLE',
                      onTap: isSubmitting || !authConfigured ? null : onGoogle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SocialButton(
                      icon: const Icon(Icons.apple_rounded, color: Colors.white),
                      label: 'APPLE',
                      onTap: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'BY LOGGING IN, YOU AGREE TO OUR TERMS OF ENGAGEMENT AND SECURITY PROTOCOLS.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white54,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(
              child: _BottomInfoCard(
                icon: Icons.shield_outlined,
                iconColor: AppTheme.secondary,
                label: 'Encryption',
                value: '256-BIT SECURE',
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _BottomInfoCard(
                icon: Icons.public_rounded,
                iconColor: AppTheme.primary,
                label: 'Network',
                value: 'GLOBAL LEAGUE',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.isSignUp, required this.onChanged});

  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _ModeTab(
            label: 'LOG IN',
            active: !isSignUp,
            onTap: () => onChanged(false),
            theme: theme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeTab(
            label: 'JOIN THE LEAGUE',
            active: isSignUp,
            onTap: () => onChanged(true),
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.active,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: active ? AppTheme.primary : Colors.white60,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white60,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _CyberTextField extends StatelessWidget {
  const _CyberTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.trailing,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon),
          suffixIcon: trailing,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.tone});

  final String message;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _StatusTone.error => const Color(0xFFFF8F87),
      _StatusTone.warning => const Color(0xFFFFC857),
      _StatusTone.info => AppTheme.primary,
    };
    final icon = switch (tone) {
      _StatusTone.error => Icons.warning_amber_rounded,
      _StatusTone.warning => Icons.info_outline_rounded,
      _StatusTone.info => Icons.check_circle_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  const _BottomInfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _GooglePainter(),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Offset.zero & size;

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final red = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final yellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final green = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(stroke / 2), -0.2, 1.2, false, blue);
    canvas.drawArc(rect.deflate(stroke / 2), 1.05, 1.05, false, green);
    canvas.drawArc(rect.deflate(stroke / 2), 2.15, 0.92, false, yellow);
    canvas.drawArc(rect.deflate(stroke / 2), 3.08, 1.05, false, red);

    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.5),
      Offset(size.width * 0.94, size.height * 0.5),
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x + 2, y + 2), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _StatusTone { error, warning, info }
