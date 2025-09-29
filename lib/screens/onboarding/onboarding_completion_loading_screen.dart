import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Loading screen shown during onboarding completion
class OnboardingCompletionLoadingScreen extends StatefulWidget {
  const OnboardingCompletionLoadingScreen({super.key});

  @override
  State<OnboardingCompletionLoadingScreen> createState() =>
      _OnboardingCompletionLoadingScreenState();
}

class _OnboardingCompletionLoadingScreenState
    extends State<OnboardingCompletionLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: brand.heroGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo/icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.connect_without_contact,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              Spacers.h32,

              // Loading text
              Text(
                'Setting up your profile...',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Spacers.h12,

              Text(
                'This will only take a moment',
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

              Spacers.h32,

              // Loading indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ),

              Spacers.h16,

              // Loading steps
              Column(
                children: [
                  _LoadingStep(
                    text: 'Saving your profile',
                    isActive: true,
                    brand: brand,
                  ),
                  Spacers.h8,
                  _LoadingStep(
                    text: 'Setting up your account',
                    isActive: true,
                    brand: brand,
                  ),
                  Spacers.h8,
                  _LoadingStep(
                    text: 'Preparing your dashboard',
                    isActive: false,
                    brand: brand,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading step indicator widget
class _LoadingStep extends StatelessWidget {
  final String text;
  final bool isActive;
  final AppBrand brand;

  const _LoadingStep({
    required this.text,
    required this.isActive,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: isActive
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.transparent,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
