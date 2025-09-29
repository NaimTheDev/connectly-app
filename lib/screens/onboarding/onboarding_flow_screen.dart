import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_providers.dart';
import '../../providers/auth_providers.dart';
import '../../models/onboarding_state.dart';
import '../../models/app_user.dart';
import '../../theme/theme.dart';
import 'welcome_screen.dart';
import 'role_selection_screen.dart';
import 'basic_profile_screen.dart';
import 'categories_selection_screen.dart';
import 'mentor_expertise_screen.dart';
import 'mentor_services_screen.dart';
import 'mentor_calendly_screen.dart';
import 'mentee_goals_screen.dart';
import 'mentee_completion_screen.dart';
import 'onboarding_completion_loading_screen.dart';

/// Main onboarding flow screen that manages navigation between steps
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late PageController _pageController;
  OnboardingState? _currentState;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeOnboarding() async {
    final firebaseUser = ref.read(firebaseUserStreamProvider).value;
    print('🔐 Firebase User: ${firebaseUser?.uid}'); // Debug auth state

    if (firebaseUser != null) {
      _userId = firebaseUser.uid;
      print('✅ User authenticated with ID: $_userId'); // Debug

      final onboardingService = ref.read(onboardingServiceProvider);
      final state = await onboardingService.initializeOnboarding(
        firebaseUser.uid,
      );
      setState(() {
        _currentState = state;
      });

      // Navigate to current step
      if (state.currentStep > 0) {
        _pageController.animateToPage(
          state.currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      print('❌ User not authenticated!'); // Debug
    }
  }

  Future<void> _onStepCompleted(OnboardingState newState) async {
    setState(() {
      _currentState = newState;
    });

    if (newState.isComplete) {
      print('🎯 Onboarding marked as complete, showing loading screen...');

      // Show loading screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OnboardingCompletionLoadingScreen(),
          ),
        );
      }

      // Complete onboarding in the service
      try {
        final onboardingService = ref.read(onboardingServiceProvider);
        await onboardingService.completeOnboarding(newState);
        print('✅ Onboarding completion successful!');

        // Wait a moment for the loading animation
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to main app - use pushNamedAndRemoveUntil to clear the stack
        if (mounted) {
          print('🏠 Navigating to home page...');
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        print('❌ Onboarding completion failed: $e');
        if (mounted) {
          // Show error and go back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete setup: $e'),
              backgroundColor: Theme.of(context).extension<AppBrand>()!.danger,
            ),
          );
          Navigator.of(context).pop(); // Go back to previous screen
        }
      }
    } else {
      // Move to next step
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onStepBack() {
    if (_currentState != null && _currentState!.currentStep > 0) {
      final onboardingService = ref.read(onboardingServiceProvider);
      onboardingService.previousStep(_currentState!).then((newState) {
        setState(() {
          _currentState = newState;
        });
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  List<Widget> _buildPages() {
    if (_currentState == null || _userId == null) {
      return [const Center(child: CircularProgressIndicator())];
    }

    final pages = <Widget>[
      // Step 0: Welcome
      WelcomeScreen(
        onContinue: () =>
            _onStepCompleted(_currentState!.copyWith(currentStep: 1)),
      ),

      // Step 1: Role Selection
      RoleSelectionScreen(
        currentState: _currentState!,
        onRoleSelected: _onStepCompleted,
        onBack: _onStepBack,
      ),

      // Step 2: Basic Profile Setup
      BasicProfileScreen(
        currentState: _currentState!,
        onProfileCompleted: _onStepCompleted,
        onBack: _onStepBack,
      ),

      // Step 3: Categories Selection
      CategoriesSelectionScreen(
        currentState: _currentState!,
        onCategoriesSelected: _onStepCompleted,
        onBack: _onStepBack,
      ),
    ];

    // Add role-specific screens
    if (_currentState!.selectedRole == UserRole.mentor) {
      pages.addAll([
        // Step 4: Mentor Expertise
        MentorExpertiseScreen(
          currentState: _currentState!,
          onExpertiseCompleted: _onStepCompleted,
          onBack: _onStepBack,
        ),

        // Step 5: Mentor Services & Pricing
        MentorServicesScreen(
          currentState: _currentState!,
          onServicesCompleted: _onStepCompleted,
          onBack: _onStepBack,
        ),

        // Step 6: Mentor Calendly Setup
        MentorCalendlyScreen(
          currentState: _currentState!,
          onCalendlyCompleted: _onStepCompleted,
          onBack: _onStepBack,
        ),
      ]);
    } else if (_currentState!.selectedRole == UserRole.mentee) {
      pages.addAll([
        // Step 4: Mentee Goals & Interests
        MenteeGoalsScreen(
          currentState: _currentState!,
          onGoalsCompleted: _onStepCompleted,
          onBack: _onStepBack,
        ),

        // Step 5: Mentee Completion
        MenteeCompletionScreen(
          currentState: _currentState!,
          onCompletionFinished: _onStepCompleted,
          onBack: _onStepBack,
        ),
      ]);
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            if (_currentState != null)
              _OnboardingProgressBar(
                currentStep: _currentState!.currentStep,
                totalSteps: _currentState!.totalStepsForRole,
                brand: brand,
              ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swipe navigation
                children: _buildPages(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress bar widget for onboarding
class _OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final AppBrand brand;

  const _OnboardingProgressBar({
    required this.currentStep,
    required this.totalSteps,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: brand.graphite,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: brand.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: brand.softGrey,
            valueColor: AlwaysStoppedAnimation<Color>(brand.brand),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
