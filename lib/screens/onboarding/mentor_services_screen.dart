import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_state.dart';
import '../../models/service_type.dart';
import '../../providers/onboarding_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/spacers.dart';

/// Mentor services and pricing setup screen for onboarding
class MentorServicesScreen extends ConsumerStatefulWidget {
  final OnboardingState currentState;
  final Function(OnboardingState) onServicesCompleted;
  final VoidCallback onBack;

  const MentorServicesScreen({
    super.key,
    required this.currentState,
    required this.onServicesCompleted,
    required this.onBack,
  });

  @override
  ConsumerState<MentorServicesScreen> createState() =>
      _MentorServicesScreenState();
}

class _MentorServicesScreenState extends ConsumerState<MentorServicesScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _virtualPriceController = TextEditingController();
  final _chatPriceController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ServiceType? _selectedService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data
    _selectedService = widget.currentState.selectedService;
    _virtualPriceController.text =
        widget.currentState.virtualAppointmentPrice?.toString() ?? '';
    _chatPriceController.text = widget.currentState.chatPrice?.toString() ?? '';

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
    _virtualPriceController.dispose();
    _chatPriceController.dispose();
    super.dispose();
  }

  Future<void> _saveServices() async {
    if (!_formKey.currentState!.validate() || _selectedService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final onboardingService = ref.read(onboardingServiceProvider);

      double? virtualPrice;
      double? chatPrice;

      if (_selectedService == ServiceType.virtualAppointments ||
          _selectedService == ServiceType.both) {
        virtualPrice = double.tryParse(_virtualPriceController.text);
      }

      if (_selectedService == ServiceType.chats ||
          _selectedService == ServiceType.both) {
        chatPrice = double.tryParse(_chatPriceController.text);
      }

      final newState = await onboardingService.updateServices(
        widget.currentState,
        service: _selectedService!,
        virtualAppointmentPrice: virtualPrice,
        chatPrice: chatPrice,
      );

      widget.onServicesCompleted(newState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save services: $e'),
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
    if (_selectedService == null) return false;

    switch (_selectedService!) {
      case ServiceType.virtualAppointments:
        return _virtualPriceController.text.isNotEmpty;
      case ServiceType.chats:
        return _chatPriceController.text.isNotEmpty;
      case ServiceType.both:
        return _virtualPriceController.text.isNotEmpty &&
            _chatPriceController.text.isNotEmpty;
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
                              'Set up your services',
                              style: textTheme.headlineSmall?.copyWith(
                                color: brand.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose what services you offer and set your pricing',
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
                          // Service type selection
                          Text(
                            'Service Type *',
                            style: textTheme.titleSmall?.copyWith(
                              color: brand.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacers.h12,

                          // Service type cards
                          ...ServiceType.values.map((service) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ServiceTypeCard(
                                serviceType: service,
                                isSelected: _selectedService == service,
                                onTap: () {
                                  setState(() {
                                    _selectedService = service;
                                  });
                                },
                                brand: brand,
                              ),
                            );
                          }).toList(),

                          Spacers.h24,

                          // Pricing section
                          if (_selectedService != null) ...[
                            Text(
                              'Pricing *',
                              style: textTheme.titleSmall?.copyWith(
                                color: brand.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacers.h8,
                            Text(
                              'Set your hourly rates in USD',
                              style: textTheme.bodySmall?.copyWith(
                                color: brand.graphite,
                              ),
                            ),
                            Spacers.h16,

                            // Virtual appointments pricing
                            if (_selectedService ==
                                    ServiceType.virtualAppointments ||
                                _selectedService == ServiceType.both) ...[
                              Text(
                                'Virtual Appointments (per hour)',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: brand.ink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacers.h8,
                              TextFormField(
                                controller: _virtualPriceController,
                                decoration: const InputDecoration(
                                  hintText: '50',
                                  prefixText: '\$ ',
                                  suffixText: '/hour',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your hourly rate';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return 'Please enter a valid price';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                              Spacers.h16,
                            ],

                            // Chat sessions pricing
                            if (_selectedService == ServiceType.chats ||
                                _selectedService == ServiceType.both) ...[
                              Text(
                                'Chat Sessions (per hour)',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: brand.ink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacers.h8,
                              TextFormField(
                                controller: _chatPriceController,
                                decoration: const InputDecoration(
                                  hintText: '30',
                                  prefixText: '\$ ',
                                  suffixText: '/hour',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your hourly rate';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return 'Please enter a valid price';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                              Spacers.h16,
                            ],

                            // Pricing tips
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
                                        'Pricing Tips:',
                                        style: textTheme.titleSmall?.copyWith(
                                          color: brand.ink,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Research market rates for your expertise level\n• Consider your experience and unique value\n• You can always adjust pricing later\n• Chat sessions are typically priced lower than video calls',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: brand.graphite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

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
                          ? _saveServices
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

/// Service type selection card widget
class _ServiceTypeCard extends StatelessWidget {
  final ServiceType serviceType;
  final bool isSelected;
  final VoidCallback onTap;
  final AppBrand brand;

  const _ServiceTypeCard({
    required this.serviceType,
    required this.isSelected,
    required this.onTap,
    required this.brand,
  });

  IconData get _icon {
    switch (serviceType) {
      case ServiceType.virtualAppointments:
        return Icons.video_call_outlined;
      case ServiceType.chats:
        return Icons.chat_outlined;
      case ServiceType.both:
        return Icons.all_inclusive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? brand.brand : brand.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon,
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
                      serviceType.displayName,
                      style: textTheme.titleMedium?.copyWith(
                        color: brand.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serviceType.description,
                      style: textTheme.bodySmall?.copyWith(
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
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
