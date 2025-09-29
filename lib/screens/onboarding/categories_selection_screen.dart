import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../models/app_user.dart';
import '../../providers/onboarding_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Categories selection screen for onboarding
class CategoriesSelectionScreen extends ConsumerStatefulWidget {
  final OnboardingState currentState;
  final Function(OnboardingState) onCategoriesSelected;
  final VoidCallback onBack;

  const CategoriesSelectionScreen({
    super.key,
    required this.currentState,
    required this.onCategoriesSelected,
    required this.onBack,
  });

  @override
  ConsumerState<CategoriesSelectionScreen> createState() =>
      _CategoriesSelectionScreenState();
}

class _CategoriesSelectionScreenState
    extends ConsumerState<CategoriesSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<String> _selectedCategories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with existing selections
    _selectedCategories = List.from(widget.currentState.selectedCategories);

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

  Future<void> _saveCategories() async {
    if (_selectedCategories.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final onboardingService = ref.read(onboardingServiceProvider);
      final newState = await onboardingService.updateCategories(
        widget.currentState,
        _selectedCategories,
      );

      widget.onCategoriesSelected(newState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save categories: $e'),
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

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  String get _titleText {
    if (widget.currentState.selectedRole == UserRole.mentor) {
      return 'What are your areas of expertise?';
    } else {
      return 'What areas interest you?';
    }
  }

  String get _subtitleText {
    if (widget.currentState.selectedRole == UserRole.mentor) {
      return 'Select the categories where you can provide mentorship';
    } else {
      return 'Choose areas where you\'d like to learn and grow';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider);

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
                              _titleText,
                              style: textTheme.headlineSmall?.copyWith(
                                color: brand.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _subtitleText,
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

                // Categories grid
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selection count
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
                                  'Selected ${_selectedCategories.length} categories. Choose at least 1 to continue.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: brand.graphite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Spacers.h24,

                        // Categories grid
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: categories.map((category) {
                            final isSelected = _selectedCategories.contains(
                              category,
                            );
                            return _CategoryChip(
                              category: category,
                              isSelected: isSelected,
                              onTap: () => _toggleCategory(category),
                              brand: brand,
                            );
                          }).toList(),
                        ),

                        // Add bottom padding for safe scrolling
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Continue button
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedCategories.isNotEmpty && !_isLoading
                          ? _saveCategories
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

/// Category selection chip widget
class _CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;
  final AppBrand brand;

  const _CategoryChip({
    required this.category,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? brand.brand.withOpacity(0.1)
                : brand.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? brand.brand : brand.softGrey,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? brand.softShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: brand.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              Text(
                category,
                style: textTheme.bodyMedium?.copyWith(
                  color: isSelected ? brand.brand : brand.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
