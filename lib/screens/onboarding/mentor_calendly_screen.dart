import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../providers/onboarding_providers.dart';
import '../../services/url_launcher_service.dart';
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

  /// Launches the Calendly OAuth flow.
  ///
  /// The backend Cloud Function `getCalendlyOAuthUrl` returns the OAuth
  /// redirect URL. After the user completes OAuth in the browser, Calendly
  /// calls back to our server which writes `isCalendlySetup: true` and
  /// `calendlyUserUri` to the `mentors/{uid}` Firestore document.
  /// Tapping "Check connection status" below polls that document to confirm.
  Future<void> _setupCalendly() async {
    setState(() => _isLoading = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('getCalendlyOAuthUrl');
      final result = await callable.call<Map<String, dynamic>>();
      final oauthUrl = result.data['url'] as String?;

      if (oauthUrl == null || oauthUrl.isEmpty) {
        throw Exception('No OAuth URL returned from server');
      }

      await UrlLauncherService.launchCalendlyUrl(context, oauthUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Complete the Calendly authorisation in your browser, '
              'then tap "Check connection status" below.',
            ),
            backgroundColor: Theme.of(context).extension<AppBrand>()!.info,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch Calendly setup: $e'),
            backgroundColor: Theme.of(context).extension<AppBrand>()!.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Polls the mentor's Firestore document to check whether Calendly OAuth
  /// completed successfully (i.e. the Cloud Function callback ran and wrote
  /// `isCalendlySetup: true`).
  Future<void> _checkCalendlyStatus() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final doc = await FirebaseFirestore.instance
          .collection('mentors')
          .doc(user.uid)
          .get();

      final isSetup = doc.data()?['isCalendlySetup'] as bool? ?? false;
      setState(() => _isCalendlySetup = isSetup);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSetup
                  ? 'Calendly connected successfully!'
                  : 'Calendly not yet connected. Complete the browser flow first.',
            ),
            backgroundColor: isSetup
                ? Theme.of(context).extension<AppBrand>()!.success
                : Theme.of(context).extension<AppBrand>()!.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not check status: $e'),
            backgroundColor: Theme.of(context).extension<AppBrand>()!.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipCalendly() async {
    setState(() => _isLoading = true);
    try {
      final onboardingService = ref.read(onboardingServiceProvider);
      final updatedState = await onboardingService.updateCalendlySetup(
        widget.currentState,
        false,
      );
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

                      // Check status button (shown after attempting OAuth)
                      if (!_isCalendlySetup) ...[
                        Spacers.h8,
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _checkCalendlyStatus,
                            child: const Text('Check connection status'),
                          ),
                        ),
                      ],

                      // Skip button
                      if (!_isCalendlySetup) ...[
                        Spacers.h8,
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
