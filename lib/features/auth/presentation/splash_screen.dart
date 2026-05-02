import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _timer = Timer(const Duration(milliseconds: 1600), _routeNext);
  }

  void _routeNext() {
    if (!mounted) return;
    final authState = context.read<AuthCubit>().state;
    context.go(authState.isAuthenticated ? AppRoutes.home : AppRoutes.auth);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulse = Curves.easeInOut.transform(_pulseController.value);
          return Stack(
            fit: StackFit.expand,
            children: [
              const _SplashBackground(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Center(
                        child: Column(
                          children: [
                            _LogoCore(pulse: pulse),
                            const SizedBox(height: 28),
                            Text(
                              'VIBETRACK',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontSize: 54,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -3.2,
                                color: AppTheme.primary,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.primary.withValues(alpha: 0.45),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _DataStrip(pulse: pulse),
                      const SizedBox(height: 28),
                      Column(
                        children: [
                          Container(
                            height: 1,
                            width: 56,
                            color: AppTheme.primary.withValues(alpha: 0.75),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'VIBETRACK // CONNECTED TO THE STREETS',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3.2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SignalDot(opacity: 1),
                              const SizedBox(width: 8),
                              _SignalDot(opacity: 0.45),
                              const SizedBox(width: 8),
                              _SignalDot(opacity: 0.18),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.24 + pulse * 0.16),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Text(
                            'INITIALIZING CORE...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
              const _CornerAccents(),
            ],
          );
        },
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF131313)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.15, -0.55),
              radius: 1.15,
              colors: [
                AppTheme.primary.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.03),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.42),
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: _GridPainter(),
        ),
        CustomPaint(
          painter: _CircuitPainter(),
        ),
      ],
    );
  }
}

class _LogoCore extends StatelessWidget {
  const _LogoCore({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: AppTheme.surface.withValues(alpha: 0.88),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12 + pulse * 0.18),
            blurRadius: 52,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.08,
            child: Icon(
              Icons.bolt_rounded,
              size: 82,
              color: AppTheme.primary,
              shadows: [
                Shadow(
                  color: AppTheme.primary.withValues(alpha: 0.65),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataStrip extends StatelessWidget {
  const _DataStrip({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _DataTile(
        label: 'Pulse_Rate',
        value: '142 BPM',
        highlighted: true,
      ),
      const _DataTile(
        label: 'Network_Status',
        value: 'CONNECTED',
      ),
      const _DataTile(
        label: 'Zone_Level',
        value: 'MAX_EXTREME',
      ),
      const _DataTile(
        label: 'Sync_Auth',
        value: 'VERIFIED',
        highlighted: true,
        alignEnd: true,
      ),
    ];

    return Opacity(
      opacity: 0.45 + pulse * 0.1,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: items,
      ),
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool highlighted;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 152,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: highlighted && !alignEnd
              ? BorderSide(color: AppTheme.primary, width: 2)
              : BorderSide.none,
          right: highlighted && alignEnd
              ? BorderSide(color: AppTheme.primary, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white54,
              letterSpacing: 2.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalDot extends StatelessWidget {
  const _SignalDot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withValues(alpha: opacity),
      ),
    );
  }
}

class _CornerAccents extends StatelessWidget {
  const _CornerAccents();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          _CornerAccent(top: 26, left: 26),
          _CornerAccent(top: 26, right: 26, mirrorX: true),
          _CornerAccent(bottom: 26, left: 26, mirrorY: true),
          _CornerAccent(bottom: 26, right: 26, mirrorX: true, mirrorY: true),
        ],
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  const _CornerAccent({
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.mirrorX = false,
    this.mirrorY = false,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final bool mirrorX;
  final bool mirrorY;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scaleByDouble (mirrorX ? -1.0 : 1.0, mirrorY ? -1.0 : 1.0, 1.0, 1.0),
        child: SizedBox(
          width: 44,
          height: 44,
          child: CustomPaint(
            painter: _CornerPainter(),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.32)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(0, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 40.0;
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.24)
      ..lineTo(size.width * 0.26, size.height * 0.24)
      ..lineTo(size.width * 0.26, size.height * 0.14)
      ..lineTo(size.width * 0.48, size.height * 0.14)
      ..moveTo(size.width * 0.68, size.height * 0.26)
      ..lineTo(size.width * 0.88, size.height * 0.26)
      ..lineTo(size.width * 0.88, size.height * 0.46)
      ..lineTo(size.width * 0.72, size.height * 0.46)
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..lineTo(size.width * 0.36, size.height * 0.72)
      ..lineTo(size.width * 0.36, size.height * 0.58)
      ..lineTo(size.width * 0.54, size.height * 0.58)
      ..moveTo(size.width * 0.62, size.height * 0.78)
      ..lineTo(size.width * 0.8, size.height * 0.78)
      ..lineTo(size.width * 0.8, size.height * 0.66);

    canvas.drawPath(path, paint);

    final nodePaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final nodes = [
      Offset(size.width * 0.26, size.height * 0.24),
      Offset(size.width * 0.48, size.height * 0.14),
      Offset(size.width * 0.72, size.height * 0.46),
      Offset(size.width * 0.36, size.height * 0.58),
      Offset(size.width * 0.8, size.height * 0.78),
    ];
    for (final node in nodes) {
      canvas.drawCircle(node, 3.2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
