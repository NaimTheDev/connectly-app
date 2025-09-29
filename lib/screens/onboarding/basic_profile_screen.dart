import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../providers/onboarding_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Basic profile setup screen for onboarding
class BasicProfileScreen extends ConsumerStatefulWidget {
  final OnboardingState currentState;
  final Function(OnboardingState) onProfileCompleted;
  final VoidCallback onBack;

  const BasicProfileScreen({
    super.key,
    required this.currentState,
    required this.onProfileCompleted,
    required this.onBack,
  });

  @override
  ConsumerState<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends ConsumerState<BasicProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _firstNameController.text = widget.currentState.firstName ?? '';
    _lastNameController.text = widget.currentState.lastName ?? '';
    _bioController.text = widget.currentState.bio ?? '';

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final onboardingService = ref.read(onboardingServiceProvider);
      final newState = await onboardingService.updateBasicProfile(
        widget.currentState,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      widget.onProfileCompleted(newState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
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
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
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
                              'Tell us about yourself',
                              style: textTheme.headlineSmall?.copyWith(
                                color: brand.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Let\'s set up your basic profile',
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
                          // Profile image placeholder
                          Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: brand.surfaceAlt,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: brand.softGrey,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 48,
                                color: brand.graphite,
                              ),
                            ),
                          ),

                          Spacers.h8,

                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                // TODO: Implement image picker
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Photo upload coming soon!'),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.camera_alt_outlined,
                                color: brand.brand,
                              ),
                              label: Text(
                                'Add Photo',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: brand.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          Spacers.h32,

                          // First Name
                          Text(
                            'First Name *',
                            style: textTheme.titleSmall?.copyWith(
                              color: brand.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacers.h8,
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your first name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          Spacers.h20,

                          // Last Name
                          Text(
                            'Last Name *',
                            style: textTheme.titleSmall?.copyWith(
                              color: brand.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacers.h8,
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your last name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          Spacers.h20,

                          // Bio (Optional)
                          Text(
                            'Bio (Optional)',
                            style: textTheme.titleSmall?.copyWith(
                              color: brand.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacers.h8,
                          TextFormField(
                            controller: _bioController,
                            decoration: const InputDecoration(
                              hintText: 'Tell us a bit about yourself...',
                            ),
                            maxLines: 3,
                            maxLength: 200,
                          ),

                          Spacers.h24,

                          // Info card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: brand.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: brand.softGrey),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: brand.info,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This information will be visible to other users on the platform',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: brand.graphite,
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
                ),

                // Continue button
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canContinue && !_isLoading
                          ? _saveProfile
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
