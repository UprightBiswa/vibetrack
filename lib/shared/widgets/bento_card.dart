import 'package:flutter/material.dart';
import 'package:vibetreck/core/theme/app_theme.dart';

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.accent = AppTheme.primary,
    this.trailing,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 110;
        final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              fontSize: isCompact ? 11 : 12,
              letterSpacing: 0.4,
            );
        final valueStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 18 : 28,
              height: 1,
              letterSpacing: -0.6,
            );
        final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white60,
              fontSize: isCompact ? 10 : 11,
            );

        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surface,
                accent.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: -10,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.55),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: valueStyle),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
