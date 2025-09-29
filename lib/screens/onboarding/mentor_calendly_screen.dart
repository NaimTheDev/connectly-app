import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../providers/onboarding_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Mentor Calendly setup screen for onboarding
class MentorCalendlyScreen extends ConsumerStatefulWidget {
  final OnboardingState currentState;
  final Function(OnboardingState) onCalendlyCompleted;
  final VoidCallback onBack;

  const MentorCalendlyScreen({
    super.key,
    required this.currentState,
    required this.onCalendlyCompleted,
    required this.onBack,
  });

  @override
  ConsumerState<MentorCalendlyScreen> createState() =>
      _MentorCalendlyScreenState();
}

class _MentorCalendlyScreenState extends ConsumerState<MentorCalendlyScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isCalendlySetup = false;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data
    _isCalendlySetup = widget.currentState.isCalendlySetup;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _setupCalendly() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual Calendly integration
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      setState(() {
        _isCalendlySetup = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Calendly integration coming soon!'),
          backgroundColor: Theme.of(context).extension<AppBrand>()!.info,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to setup Calendly: $e'),
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

  Future<void> _skipCalendly() async {
    print('🔄 SKIP CALENDLY: Starting skip process...');
    print('📊 Current state: ${widget.currentState.toMap()}');

    setState(() {
      _isLoading = true;
    });

    try {
      final onboardingService = ref.read(onboardingServiceProvider);

      print('⏭️ STEP 1: Updating Calendly setup to false...');
      // Mark Calendly as not setup
      final updatedState = await onboardingService.updateCalendlySetup(
        widget.currentState,
        false,
      );
      print('✅ STEP 1 Complete: ${updatedState.toMap()}');

      print('⏭️ STEP 2: Marking onboarding as complete...');
      // Mark onboarding as complete (OnboardingFlowScreen will handle the actual completion)
      final completedState = updatedState.copyWith(
        isComplete: true,
        currentStep: updatedState.totalStepsForRole,
      );
      print('📋 Final state: ${completedState.toMap()}');
      print(
        '✅ STEP 2 Complete: Passing to OnboardingFlowScreen for completion...',
      );

      widget.onCalendlyCompleted(completedState);
    } catch (e) {
      print('❌ SKIP CALENDLY ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to continue: $e'),
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

  Future<void> _continueWithCalendly() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final onboardingService = ref.read(onboardingServiceProvider);

      // Update Calendly setup status
      final updatedState = await onboardingService.updateCalendlySetup(
        widget.currentState,
        _isCalendlySetup,
      );

      // Mark onboarding as complete (OnboardingFlowScreen will handle the actual completion)
      final completedState = updatedState.copyWith(
        isComplete: true,
        currentStep: updatedState.totalStepsForRole,
      );

      widget.onCalendlyCompleted(completedState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to continue: $e'),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calendar Integration',
                              style: textTheme.headlineSmall?.copyWith(
                                color: brand.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect your calendar for easy scheduling',
                              style: textTheme.bodyMedium?.copyWith(
                                color: brand.graphite,
                              ),
                            ),
                          ],
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
                        // Calendly logo/icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: brand.brand.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            size: 50,
                            color: brand.brand,
                          ),
                        ),

                        Spacers.h24,

                        // Title and description
                        Text(
                          'Connect with Calendly',
                          style: textTheme.headlineSmall?.copyWith(
                            color: brand.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Spacers.h12,

                        Text(
                          'Integrate your Calendly account to let mentees easily book sessions with you. This streamlines the scheduling process and reduces back-and-forth communication.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: brand.graphite,
                            height: 1.5,
                          ),
                        ),

                        Spacers.h32,

                        // Benefits list
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: brand.surfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: brand.softGrey),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Benefits of Calendar Integration:',
                                style: textTheme.titleMedium?.copyWith(
                                  color: brand.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacers.h16,
                              ...[
                                    'Automated scheduling without conflicts',
                                    'Mentees can book available time slots',
                                    'Automatic reminders and notifications',
                                    'Sync with your existing calendar',
                                    'Professional booking experience',
                                  ]
                                  .map(
                                    (benefit) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            color: brand.success,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              benefit,
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

                        Spacers.h24,

                        // Status indicator
                        if (_isCalendlySetup)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: brand.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: brand.success.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: brand.success,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Calendly integration setup complete!',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: brand.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Add bottom padding for safe scrolling
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Setup Calendly button
                      if (!_isCalendlySetup)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _setupCalendly,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.link),
                            label: const Text('Connect Calendly'),
                          ),
                        ),

                      // Continue button (when setup is complete)
                      if (_isCalendlySetup)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _continueWithCalendly,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Continue'),
                          ),
                        ),

                      // Skip button
                      if (!_isCalendlySetup) ...[
                        Spacers.h12,
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _isLoading ? null : _skipCalendly,
                            child: const Text('Skip for now'),
                          ),
                        ),
                      ],

                      // Info text
                      Spacers.h8,
                      Text(
                        _isCalendlySetup
                            ? 'You can manage your calendar settings later in your profile.'
                            : 'You can set up calendar integration later in your settings.',
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
