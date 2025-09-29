import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../providers/onboarding_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Mentee completion screen for onboarding
class MenteeCompletionScreen extends ConsumerStatefulWidget {
  final OnboardingState currentState;
  final Function(OnboardingState) onCompletionFinished;
  final VoidCallback onBack;

  const MenteeCompletionScreen({
    super.key,
    required this.currentState,
    required this.onCompletionFinished,
    required this.onBack,
  });

  @override
  ConsumerState<MenteeCompletionScreen> createState() =>
      _MenteeCompletionScreenState();
}

class _MenteeCompletionScreenState extends ConsumerState<MenteeCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _celebrationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _celebrationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final onboardingService = ref.read(onboardingServiceProvider);
      final completedState = widget.currentState.copyWith(
        isComplete: true,
        currentStep: widget.currentState.totalStepsForRole,
      );

      await onboardingService.completeOnboarding(completedState);
      widget.onCompletionFinished(completedState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: $e'),
            backgroundColor: Theme.of(context).extension<AppBrand>()!.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: Icon(Icons.arrow_back, color: brand.ink),
                        padding: EdgeInsets.zero,
                      ),
                      Spacers.w16,
                      Expanded(
                        child: Text(
                          'Almost ready!',
                          style: textTheme.headlineSmall?.copyWith(
                            color: brand.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Spacers.h32,

                        // Celebration icon
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: brand.heroGradient,
                              shape: BoxShape.circle,
                              boxShadow: brand.softShadow,
                            ),
                            child: const Icon(
                              Icons.celebration_outlined,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        Spacers.h32,

                        // Welcome message
                        Text(
                          'Welcome to Connectly!',
                          style: textTheme.headlineMedium?.copyWith(
                            color: brand.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Spacers.h12,

                        Text(
                          'Your profile is all set up. You\'re ready to start connecting with amazing mentors and accelerate your career growth.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: brand.graphite,
                            height: 1.5,
                          ),
                        ),

                        Spacers.h32,

                        // Profile summary card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: brand.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: brand.softGrey),
                            boxShadow: brand.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Profile Summary',
                                style: textTheme.titleLarge?.copyWith(
                                  color: brand.ink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacers.h16,

                              // Name
                              _ProfileItem(
                                icon: Icons.person_outline,
                                label: 'Name',
                                value:
                                    '${widget.currentState.firstName} ${widget.currentState.lastName}',
                                brand: brand,
                              ),

                              // Role
                              _ProfileItem(
                                icon: Icons.school_outlined,
                                label: 'Role',
                                value: 'Mentee',
                                brand: brand,
                              ),

                              // Categories
                              _ProfileItem(
                                icon: Icons.category_outlined,
                                label: 'Areas of Interest',
                                value: widget.currentState.selectedCategories
                                    .join(', '),
                                brand: brand,
                              ),

                              // Goals
                              if (widget.currentState.goals?.isNotEmpty == true)
                                _ProfileItem(
                                  icon: Icons.flag_outlined,
                                  label: 'Goals',
                                  value: widget.currentState.goals!,
                                  brand: brand,
                                ),
                            ],
                          ),
                        ),

                        Spacers.h24,

                        // Next steps card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: brand.brand.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: brand.brand.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: brand.brand,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'What\'s next?',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: brand.brand,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Spacers.h16,
                              ...[
                                    'Browse and connect with mentors in your areas of interest',
                                    'Schedule your first mentoring session',
                                    'Join the community and start networking',
                                    'Set up your learning schedule and track progress',
                                  ]
                                  .map(
                                    (step) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.only(
                                              top: 8,
                                              right: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: brand.brand,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              step,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(color: brand.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                          ),
                        ),

                        // Add bottom padding for safe scrolling
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Complete button
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Start Your Journey'),
                        ),
                      ),
                      Spacers.h8,
                      Text(
                        'You can always update your profile later in settings',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: brand.graphite,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile item widget for displaying profile information
class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppBrand brand;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: brand.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: brand.graphite, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: brand.graphite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: brand.ink,
                    fontWeight: FontWeight.w500,
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
