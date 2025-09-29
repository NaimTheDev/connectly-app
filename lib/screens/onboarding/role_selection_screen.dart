import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../models/app_user.dart';
import '../../providers/onboarding_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Role selection screen for choosing between mentor and mentee
class RoleSelectionScreen extends ConsumerStatefulWidget {
  final OnboardingState currentState;
  final Function(OnboardingState) onRoleSelected;
  final VoidCallback onBack;

  const RoleSelectionScreen({
    super.key,
    required this.currentState,
    required this.onRoleSelected,
    required this.onBack,
  });

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with TickerProviderStateMixin {
  UserRole? _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentState.selectedRole;

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

  Future<void> _selectRole(UserRole role) async {
    setState(() {
      _selectedRole = role;
    });

    // Add a small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 200));

    final onboardingService = ref.read(onboardingServiceProvider);
    final newState = await onboardingService.updateRole(
      widget.currentState,
      role,
    );
    widget.onRoleSelected(newState);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back, color: brand.ink),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),

                  Spacers.h16,

                  // Title
                  Text(
                    'Choose Your Role',
                    style: textTheme.headlineMedium?.copyWith(
                      color: brand.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Spacers.h8,

                  Text(
                    'Select how you\'d like to use Connectly',
                    style: textTheme.titleMedium?.copyWith(
                      color: brand.graphite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  Spacers.h32,

                  // Mentor Role Card
                  _RoleCard(
                    role: UserRole.mentor,
                    title: 'I\'m a Mentor',
                    subtitle: 'Share your expertise and guide others',
                    icon: Icons.school_outlined,
                    features: [
                      'Offer mentoring sessions',
                      'Set your own pricing',
                      'Build your professional network',
                      'Share knowledge and experience',
                    ],
                    isSelected: _selectedRole == UserRole.mentor,
                    onTap: () => _selectRole(UserRole.mentor),
                    brand: brand,
                  ),

                  Spacers.h20,

                  // Mentee Role Card
                  _RoleCard(
                    role: UserRole.mentee,
                    title: 'I\'m a Mentee',
                    subtitle: 'Learn from experienced professionals',
                    icon: Icons.person_outline,
                    features: [
                      'Connect with expert mentors',
                      'Schedule learning sessions',
                      'Accelerate your career growth',
                      'Get personalized guidance',
                    ],
                    isSelected: _selectedRole == UserRole.mentee,
                    onTap: () => _selectRole(UserRole.mentee),
                    brand: brand,
                  ),

                  Spacers.h20,

                  // Help text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: brand.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: brand.softGrey),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: brand.info, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can always switch roles later in your settings',
                            style: textTheme.bodyMedium?.copyWith(
                              color: brand.graphite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add bottom padding for safe scrolling
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Role selection card widget
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;
  final AppBrand brand;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.features,
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? brand.brand.withOpacity(0.1)
                : brand.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? brand.brand : brand.softGrey,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? brand.softShadow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? brand.brand : brand.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : brand.graphite,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleLarge?.copyWith(
                            color: brand.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: brand.graphite,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: brand.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Features list
              ...features
                  .map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: isSelected ? brand.brand : brand.graphite,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: textTheme.bodyMedium?.copyWith(
                                color: brand.ink,
                              ),
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
      ),
    );
  }
}
