import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Welcome screen for onboarding flow
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: brand.heroGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo/Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: brand.softShadow,
                          ),
                          child: Icon(
                            Icons.connect_without_contact,
                            size: 50,
                            color: brand.brand,
                          ),
                        ),

                        Spacers.h24,

                        // Welcome Title
                        Text(
                          'Welcome to\nConnectly',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),

                        Spacers.h12,

                        // Subtitle
                        Text(
                          'Connect with mentors and mentees\nto grow your career',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),

                        Spacers.h32,

                        // Feature highlights
                        _FeatureHighlight(
                          icon: Icons.people_outline,
                          title: 'Expert Mentors',
                          description: 'Learn from industry professionals',
                          brand: brand,
                        ),

                        Spacers.h16,

                        _FeatureHighlight(
                          icon: Icons.video_call_outlined,
                          title: 'Virtual Sessions',
                          description: 'Schedule calls and chat sessions',
                          brand: brand,
                        ),

                        Spacers.h16,

                        _FeatureHighlight(
                          icon: Icons.trending_up_outlined,
                          title: 'Career Growth',
                          description: 'Accelerate your professional journey',
                          brand: brand,
                        ),
                      ],
                    ),
                  ),

                  Spacers.h32,

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: brand.brand,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get Started',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: brand.brand,
                        ),
                      ),
                    ),
                  ),

                  Spacers.h12,

                  // Skip option
                  TextButton(
                    onPressed: () {
                      // TODO: Implement skip for returning users
                    },
                    child: Text(
                      'Already have an account? Skip setup',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Feature highlight widget
class _FeatureHighlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final AppBrand brand;

  const _FeatureHighlight({
    required this.icon,
    required this.title,
    required this.description,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
