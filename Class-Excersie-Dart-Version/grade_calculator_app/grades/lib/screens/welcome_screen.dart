import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'grade_calculator_screen.dart';

/// Onboarding screen – first thing the teacher sees.
/// Matches the "Grading made simple" mockup.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.softGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Top bar ─────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppTheme.radiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'GradeGenie',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      color: AppTheme.textMuted,
                      onPressed: () {},
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // ── Hero illustration ───────────────────────────
                Container(
                  width: size.width * 0.75,
                  height: size.width * 0.55,
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.radiusLg,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -15,
                        left: -15,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      // Icon composition
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.assignment_turned_in_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: ['A', 'B+', 'C', 'D', 'F']
                                .map(
                                  (g) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: AppTheme.radiusSm,
                                    ),
                                    child: Text(
                                      g,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // ── Tagline ─────────────────────────────────────
                Text(
                  'Grading made',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  'simple',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Automate your grading process instantly.\n'
                  'Upload Excel sheets and convert scores\n'
                  'to letter grades in seconds.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),

                const SizedBox(height: 24),

                // ── Feature badges ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FeatureBadge(
                      icon: Icons.bolt_rounded,
                      label: 'Fast',
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 16),
                    _FeatureBadge(
                      icon: Icons.verified_rounded,
                      label: 'Accurate',
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 16),
                    _FeatureBadge(
                      icon: Icons.table_chart_rounded,
                      label: 'Excel Support',
                      color: AppTheme.primary,
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // ── CTA Button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const GradeCalculatorScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusXl,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Get Started', style: TextStyle(fontSize: 17)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'By continuing, you agree to our Terms & Privacy Policy.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small reusable widgets ────────────────────────────────────────────────

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
    ],
  );
}
