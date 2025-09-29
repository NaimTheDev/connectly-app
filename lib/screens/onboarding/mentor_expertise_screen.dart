import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../providers/onboarding_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Mentor expertise setup screen for onboarding
class MentorExpertiseScreen extends ConsumerStatefulWidget {
  final OnboardingState currentState;
  final Function(OnboardingState) onExpertiseCompleted;
  final VoidCallback onBack;

  const MentorExpertiseScreen({
    super.key,
    required this.currentState,
    required this.onExpertiseCompleted,
    required this.onBack,
  });

  @override
  ConsumerState<MentorExpertiseScreen> createState() =>
      _MentorExpertiseScreenState();
}

class _MentorExpertiseScreenState extends ConsumerState<MentorExpertiseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _expertiseController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controller with existing data
    _expertiseController.text = widget.currentState.expertise ?? '';

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
    _expertiseController.dispose();
    super.dispose();
  }

  Future<void> _saveExpertise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final onboardingService = ref.read(onboardingServiceProvider);
      final newState = await onboardingService.updateExpertise(
        widget.currentState,
        _expertiseController.text.trim(),
      );

      widget.onExpertiseCompleted(newState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expertise: $e'),
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

  bool get _canContinue {
    return _expertiseController.text.trim().isNotEmpty;
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
                              'Share your expertise',
                              style: textTheme.headlineSmall?.copyWith(
                                color: brand.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tell mentees about your professional background',
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

                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon and description
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: brand.brand.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                size: 40,
                                color: brand.brand,
                              ),
                            ),
                          ),

                          Spacers.h24,

                          // Expertise field
                          Text(
                            'Professional Expertise *',
                            style: textTheme.titleSmall?.copyWith(
                              color: brand.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacers.h8,
                          TextFormField(
                            controller: _expertiseController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Describe your professional background, skills, and experience...',
                            ),
                            maxLines: 6,
                            maxLength: 500,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please describe your expertise';
                              }
                              if (value.trim().length < 50) {
                                return 'Please provide at least 50 characters';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          Spacers.h24,

                          // Tips card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: brand.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: brand.softGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: brand.brand,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tips for a great expertise description:',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: brand.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...[
                                      '• Mention your years of experience',
                                      '• Include specific skills and technologies',
                                      '• Highlight notable achievements or projects',
                                      '• Describe your mentoring philosophy',
                                      '• Share what makes you unique',
                                    ]
                                    .map(
                                      (tip) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          tip,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: brand.graphite,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),
                          ),

                          Spacers.h20,

                          // Example card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: brand.info.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: brand.info.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_quote,
                                      color: brand.info,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Example:',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: brand.info,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '"I\'m a Senior Software Engineer with 8+ years of experience in full-stack development. I specialize in React, Node.js, and cloud architecture. I\'ve led teams at startups and Fortune 500 companies, and I\'m passionate about helping junior developers navigate their career growth and technical challenges."',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: brand.graphite,
                                    fontStyle: FontStyle.italic,
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
                ),

                // Continue button
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canContinue && !_isLoading
                          ? _saveExpertise
                          : null,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
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
