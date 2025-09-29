import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../providers/onboarding_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Mentee goals and interests setup screen for onboarding
class MenteeGoalsScreen extends ConsumerStatefulWidget {
  final OnboardingState currentState;
  final Function(OnboardingState) onGoalsCompleted;
  final VoidCallback onBack;

  const MenteeGoalsScreen({
    super.key,
    required this.currentState,
    required this.onGoalsCompleted,
    required this.onBack,
  });

  @override
  ConsumerState<MenteeGoalsScreen> createState() => _MenteeGoalsScreenState();
}

class _MenteeGoalsScreenState extends ConsumerState<MenteeGoalsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _goalsController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<String> _selectedInterests = [];
  bool _isLoading = false;

  // Predefined interests for mentees
  final List<String> _availableInterests = [
    'Career Advancement',
    'Skill Development',
    'Leadership Training',
    'Industry Insights',
    'Networking',
    'Job Search Strategy',
    'Interview Preparation',
    'Salary Negotiation',
    'Work-Life Balance',
    'Entrepreneurship',
    'Technical Skills',
    'Soft Skills',
    'Public Speaking',
    'Project Management',
    'Team Management',
    'Strategic Thinking',
    'Problem Solving',
    'Communication Skills',
    'Time Management',
    'Goal Setting',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with existing data
    _goalsController.text = widget.currentState.goals ?? '';
    _selectedInterests = List.from(widget.currentState.interests);

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
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final onboardingService = ref.read(onboardingServiceProvider);
      final newState = await onboardingService.updateGoalsAndInterests(
        widget.currentState,
        goals: _goalsController.text.trim(),
        interests: _selectedInterests,
      );

      widget.onGoalsCompleted(newState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goals: $e'),
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

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  bool get _canContinue {
    return _goalsController.text.trim().isNotEmpty;
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
                              'Your learning goals',
                              style: textTheme.headlineSmall?.copyWith(
                                color: brand.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tell us what you want to achieve',
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
                                Icons.flag_outlined,
                                size: 40,
                                color: brand.brand,
                              ),
                            ),
                          ),

                          Spacers.h24,

                          // Goals field
                          Text(
                            'Career Goals *',
                            style: textTheme.titleSmall?.copyWith(
                              color: brand.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacers.h8,
                          TextFormField(
                            controller: _goalsController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Describe what you want to achieve in your career...',
                            ),
                            maxLines: 4,
                            maxLength: 300,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please describe your career goals';
                              }
                              if (value.trim().length < 20) {
                                return 'Please provide at least 20 characters';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          Spacers.h24,

                          // Interests section
                          Text(
                            'Areas of Interest (Optional)',
                            style: textTheme.titleSmall?.copyWith(
                              color: brand.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacers.h8,
                          Text(
                            'Select topics you\'d like to learn about',
                            style: textTheme.bodySmall?.copyWith(
                              color: brand.graphite,
                            ),
                          ),
                          Spacers.h16,

                          // Interests grid
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableInterests.map((interest) {
                              final isSelected = _selectedInterests.contains(
                                interest,
                              );
                              return _InterestChip(
                                interest: interest,
                                isSelected: isSelected,
                                onTap: () => _toggleInterest(interest),
                                brand: brand,
                              );
                            }).toList(),
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
                                      'Tips for setting goals:',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: brand.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...[
                                      '• Be specific about what you want to achieve',
                                      '• Include both short-term and long-term goals',
                                      '• Mention skills you want to develop',
                                      '• Consider your current career stage',
                                      '• Think about challenges you want to overcome',
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
                                  '"I want to transition from a junior to senior developer role within the next 2 years. I\'d like to improve my system design skills, learn about team leadership, and gain experience with cloud technologies. I\'m also interested in contributing to open source projects."',
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
                          ? _saveGoals
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

/// Interest selection chip widget
class _InterestChip extends StatelessWidget {
  final String interest;
  final bool isSelected;
  final VoidCallback onTap;
  final AppBrand brand;

  const _InterestChip({
    required this.interest,
    required this.isSelected,
    required this.onTap,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? brand.brand.withOpacity(0.1)
                : brand.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? brand.brand : brand.softGrey,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            interest,
            style: textTheme.bodySmall?.copyWith(
              color: isSelected ? brand.brand : brand.ink,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
