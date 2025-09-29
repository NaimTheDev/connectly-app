import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';
import '../../models/onboarding_state.dart';
import '../../providers/onboarding_providers.dart';
import '../../providers/auth_providers.dart';

/// Loading screen shown during onboarding completion
class OnboardingCompletionLoadingScreen extends ConsumerStatefulWidget {
  const OnboardingCompletionLoadingScreen({super.key, required this.state});

  final OnboardingState state;

  @override
  ConsumerState<OnboardingCompletionLoadingScreen> createState() =>
      _OnboardingCompletionLoadingScreenState();
}

class _OnboardingCompletionLoadingScreenState
    extends ConsumerState<OnboardingCompletionLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  bool _started = false;
  bool _failed = false;
  String? _errorMessage;
  bool _isRetrying = false;

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

    // kick off completion after first frame to ensure context mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        _complete();
      }
    });
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
                  // Retry / error section (only visible if failed)
                  _buildRetrySection(brand, textTheme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete() async {
    setState(() {
      _failed = false;
      _errorMessage = null;
      _isRetrying = true;
    });
    final onboardingService = ref.read(onboardingServiceProvider);
    const maxAttempts = 3;
    bool success = false;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final attemptLabel = 'Attempt $attempt/$maxAttempts';
      try {
        // ignore: avoid_print
        print('🚀 Completing onboarding from loading screen... $attemptLabel');
        await onboardingService
            .completeOnboarding(widget.state)
            .timeout(const Duration(seconds: 20));
        success = true;
        // ignore: avoid_print
        print('✅ Completion successful ($attemptLabel)');
        break;
      } on TimeoutException catch (_) {
        if (attempt == maxAttempts) {
          _showError('Network timeout');
        } else {
          _showSnack('Network timeout. Retrying...');
        }
      } catch (e) {
        if (attempt == maxAttempts) {
          _showError('Failed: $e');
        } else {
          _showSnack('Error finishing setup. Retrying...');
        }
      }
      if (!success && attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    if (!mounted) return;
    if (success) {
      // Invalidate the needsOnboarding provider to force refetch of updated data
      final firebaseUser = ref.read(firebaseUserStreamProvider).value;
      if (firebaseUser != null) {
        ref.invalidate(needsOnboardingProvider(firebaseUser.uid));
        // ignore: avoid_print
        print(
          '🔄 Invalidated needsOnboardingProvider cache for ${firebaseUser.uid}',
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    } else {
      setState(() {
        _failed = true;
        _isRetrying = false;
      });
    }
    if (mounted && success) {
      setState(() {
        _isRetrying = false;
      });
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    final brand = Theme.of(context).extension<AppBrand>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: brand.warning),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    final brand = Theme.of(context).extension<AppBrand>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to complete setup: $msg'),
        backgroundColor: brand.danger,
      ),
    );
    setState(() {
      _errorMessage = msg;
    });
  }

  Widget _buildRetrySection(AppBrand brand, TextTheme textTheme) {
    if (!_failed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: brand.danger),
          const SizedBox(height: 16),
          Text(
            'We\'re having trouble finishing up',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isRetrying ? null : _complete,
                icon: _isRetrying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isRetrying ? 'Retrying...' : 'Retry now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
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
