import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/service_type.dart';
import '../providers/auth_providers.dart';
import '../providers/onboarding_providers.dart';
import '../theme/theme.dart';
import '../widgets/spacers.dart';

/// Screen for editing user profile
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _calendlyUrlController = TextEditingController();
  final _virtualPriceController = TextEditingController();
  final _chatPriceController = TextEditingController();

  bool _isLoading = false;
  String? _profileImageUrl;
  List<String> _selectedCategories = [];
  ServiceType? _selectedService;
  UserRole? _userRole;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nicknameController.dispose();
    _calendlyUrlController.dispose();
    _virtualPriceController.dispose();
    _chatPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final firebaseUser = ref.read(firebaseUserStreamProvider).value;
    if (firebaseUser == null) return;

    _userId = firebaseUser.uid;

    try {
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId!)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _userRole = userData['role'] == 'mentor'
              ? UserRole.mentor
              : UserRole.mentee;
          _bioController.text = userData['bio'] ?? '';
          _nicknameController.text = userData['firstName'] ?? '';
          _profileImageUrl = userData['imageUrl'];
          _selectedCategories = List<String>.from(userData['interests'] ?? []);
        });
      }

      // If mentor, load mentor-specific data
      if (_userRole == UserRole.mentor) {
        final mentorDoc = await FirebaseFirestore.instance
            .collection('mentors')
            .doc(_userId!)
            .get();

        if (mentorDoc.exists) {
          final mentorData = mentorDoc.data()!;
          setState(() {
            _calendlyUrlController.text = mentorData['calendlyUrl'] ?? '';
            _virtualPriceController.text =
                mentorData['virtualAppointmentPrice']?.toString() ?? '';
            _chatPriceController.text =
                mentorData['chatPrice']?.toString() ?? '';
            _selectedService = mentorData['services'] != null
                ? ServiceType.fromString(mentorData['services'])
                : null;
            _selectedCategories = List<String>.from(
              mentorData['categories'] ?? [],
            );
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update user document
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId!);
      final userData = <String, dynamic>{
        'bio': _bioController.text.trim(),
        'firstName': _nicknameController.text.trim(),
        'imageUrl': _profileImageUrl,
      };

      if (_userRole == UserRole.mentee) {
        userData['interests'] = _selectedCategories;
      }

      batch.set(userRef, userData, SetOptions(merge: true));

      // If mentor, update mentor document
      if (_userRole == UserRole.mentor) {
        final mentorRef = FirebaseFirestore.instance
            .collection('mentors')
            .doc(_userId!);
        final mentorData = <String, dynamic>{
          'bio': _bioController.text.trim(),
          'firstName': _nicknameController.text.trim(),
          'imageUrl': _profileImageUrl,
          'calendlyUrl': _calendlyUrlController.text.trim().isEmpty
              ? null
              : _calendlyUrlController.text.trim(),
          'categories': _selectedCategories,
          'isHidden': false,
        };

        if (_selectedService != null) {
          mentorData['services'] = _selectedService!.toString();
        }

        if (_virtualPriceController.text.isNotEmpty) {
          mentorData['virtualAppointmentPrice'] = double.tryParse(
            _virtualPriceController.text,
          );
        }

        if (_chatPriceController.text.isNotEmpty) {
          mentorData['chatPrice'] = double.tryParse(_chatPriceController.text);
        }

        batch.set(mentorRef, mentorData, SetOptions(merge: true));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Theme.of(context).extension<AppBrand>()!.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
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

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider);

    if (_userRole == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: textTheme.headlineSmall?.copyWith(
            color: brand.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: brand.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              _ProfilePictureSection(
                imageUrl: _profileImageUrl,
                onImageChanged: (url) => setState(() => _profileImageUrl = url),
                brand: brand,
              ),

              Spacers.h32,

              // Basic Info Section
              _SectionHeader(title: 'Basic Information', brand: brand),
              Spacers.h16,

              // Nickname/First Name
              _buildTextField(
                controller: _nicknameController,
                label: _userRole == UserRole.mentor ? 'First Name' : 'Nickname',
                hint: _userRole == UserRole.mentor
                    ? 'Enter your first name'
                    : 'How would you like to be called?',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),

              Spacers.h20,

              // Bio
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Tell others about yourself...',
                maxLines: 3,
                maxLength: 200,
              ),

              Spacers.h32,

              // Categories Section
              _SectionHeader(
                title: _userRole == UserRole.mentor
                    ? 'Areas of Expertise'
                    : 'Areas of Interest',
                brand: brand,
              ),
              Spacers.h16,

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return _CategoryChip(
                    category: category,
                    isSelected: isSelected,
                    onTap: () => _toggleCategory(category),
                    brand: brand,
                  );
                }).toList(),
              ),

              // Mentor-specific sections
              if (_userRole == UserRole.mentor) ...[
                Spacers.h32,

                // Calendly URL Section
                _SectionHeader(title: 'Calendar Integration', brand: brand),
                Spacers.h16,

                _buildTextField(
                  controller: _calendlyUrlController,
                  label: 'Calendly URL (Optional)',
                  hint: 'https://calendly.com/your-username',
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!value.startsWith('https://calendly.com/')) {
                        return 'Please enter a valid Calendly URL';
                      }
                    }
                    return null;
                  },
                ),

                Spacers.h32,

                // Pricing Section
                _SectionHeader(title: 'Pricing & Services', brand: brand),
                Spacers.h16,

                // Service Type Selection
                Text(
                  'Service Type',
                  style: textTheme.titleSmall?.copyWith(
                    color: brand.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacers.h8,

                ...ServiceType.values.map((service) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ServiceTypeCard(
                      serviceType: service,
                      isSelected: _selectedService == service,
                      onTap: () => setState(() => _selectedService = service),
                      brand: brand,
                    ),
                  );
                }).toList(),

                Spacers.h20,

                // Pricing fields
                if (_selectedService == ServiceType.virtualAppointments ||
                    _selectedService == ServiceType.both) ...[
                  _buildTextField(
                    controller: _virtualPriceController,
                    label: 'Virtual Appointments (per hour)',
                    hint: '50',
                    prefixText: '\$ ',
                    suffixText: '/hour',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                  Spacers.h16,
                ],

                if (_selectedService == ServiceType.chats ||
                    _selectedService == ServiceType.both) ...[
                  _buildTextField(
                    controller: _chatPriceController,
                    label: 'Chat Sessions (per hour)',
                    hint: '30',
                    prefixText: '\$ ',
                    suffixText: '/hour',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ],
              ],

              // Bottom padding
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    String? suffixText,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            color: brand.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        Spacers.h8,
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            suffixText: suffixText,
          ),
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final AppBrand brand;

  const _SectionHeader({required this.title, required this.brand});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        color: brand.ink,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Profile picture section widget
class _ProfilePictureSection extends StatelessWidget {
  final String? imageUrl;
  final Function(String?) onImageChanged;
  final AppBrand brand;

  const _ProfilePictureSection({
    required this.imageUrl,
    required this.onImageChanged,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brand.surfaceAlt,
              border: Border.all(color: brand.softGrey, width: 2),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Icon(Icons.person_outline, size: 60, color: brand.graphite)
                : null,
          ),
          Spacers.h12,
          TextButton.icon(
            onPressed: () {
              // TODO: Implement image picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo upload coming soon!')),
              );
            },
            icon: Icon(Icons.camera_alt_outlined, color: brand.brand),
            label: Text(
              imageUrl == null ? 'Add Photo' : 'Change Photo',
              style: textTheme.bodyMedium?.copyWith(
                color: brand.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

    return InkWell(
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
          category,
          style: textTheme.bodySmall?.copyWith(
            color: isSelected ? brand.brand : brand.ink,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? brand.brand.withOpacity(0.1)
              : brand.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brand.brand : brand.softGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? brand.brand : brand.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _icon,
                color: isSelected ? Colors.white : brand.graphite,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceType.displayName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: brand.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    serviceType.description,
                    style: textTheme.bodySmall?.copyWith(color: brand.graphite),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: brand.brand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}
