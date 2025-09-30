import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mentor.dart';
import '../models/service_type.dart';
import '../providers/mentors_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/chats/chat_creation_providers.dart';
import '../routing/app_router.dart';
import '../screens/home_screen.dart'; // For MentorAvatar
import '../services/url_launcher_service.dart';
import '../theme/theme.dart';
import '../widgets/spacers.dart';
import '../widgets/brand_chip.dart';

/// Screen displaying detailed information about a specific mentor
class MentorDetailScreen extends ConsumerWidget {
  final String mentorId;

  const MentorDetailScreen({super.key, required this.mentorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentorAsync = ref.watch(mentorByIdProvider(mentorId));
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: mentorAsync.when(
        data: (mentor) {
          if (mentor == null) {
            return _buildNotFound(context, brand, textTheme);
          }
          return _buildMentorDetail(context, ref, mentor, brand, textTheme);
        },
        loading: () => _buildLoading(brand),
        error: (error, stackTrace) =>
            _buildError(context, brand, textTheme, error),
      ),
    );
  }

  Widget _buildNotFound(
    BuildContext context,
    AppBrand brand,
    TextTheme textTheme,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mentor Not Found'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: brand.graphite.withOpacity(0.5),
            ),
            Spacers.h16,
            Text(
              'Mentor not found',
              style: textTheme.titleLarge?.copyWith(
                color: brand.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacers.h8,
            Text(
              'The mentor you\'re looking for doesn\'t exist.',
              style: textTheme.bodyMedium?.copyWith(color: brand.graphite),
            ),
            Spacers.h24,
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(AppBrand brand) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loading...'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(
    BuildContext context,
    AppBrand brand,
    TextTheme textTheme,
    Object error,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Error'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: brand.danger),
            Spacers.h16,
            Text(
              'Failed to load mentor',
              style: textTheme.titleLarge?.copyWith(
                color: brand.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacers.h8,
            Text(
              'Please try again later.',
              style: textTheme.bodyMedium?.copyWith(color: brand.graphite),
            ),
            Spacers.h24,
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorDetail(
    BuildContext context,
    WidgetRef ref,
    Mentor mentor,
    AppBrand brand,
    TextTheme textTheme,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          title: Text(
            mentor.name,
            style: textTheme.titleLarge?.copyWith(
              color: brand.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: brand.ink,
          elevation: 0,
          floating: true,
          snap: true,
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Section
                _buildProfileHeader(mentor, brand, textTheme),
                Spacers.h32,

                // Categories Section
                if (mentor.categories != null &&
                    mentor.categories!.isNotEmpty) ...[
                  _buildCategoriesSection(mentor, brand, textTheme),
                  Spacers.h32,
                ],

                // Services Section
                _buildServicesSection(mentor, brand, textTheme),
                Spacers.h32,

                // Action Buttons
                _buildActionButtons(context, ref, mentor, brand, textTheme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    Mentor mentor,
    AppBrand brand,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        children: [
          // Large Avatar
          MentorAvatar(
            name: mentor.name,
            imageUrl: mentor.imageUrl,
            size: 120,
            backgroundColor: brand.brand,
            textColor: Colors.white,
          ),
          Spacers.h20,

          // Name
          Text(
            mentor.name,
            style: textTheme.headlineMedium?.copyWith(
              color: brand.ink,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          // Expertise
          if (mentor.expertise.isNotEmpty) ...[
            Spacers.h8,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: brand.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                mentor.expertise,
                style: textTheme.bodyLarge?.copyWith(
                  color: brand.brand,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Bio
          if (mentor.bio.isNotEmpty) ...[
            Spacers.h20,
            Text(
              mentor.bio,
              style: textTheme.bodyLarge?.copyWith(
                color: brand.graphite,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(
    Mentor mentor,
    AppBrand brand,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialties',
          style: textTheme.titleLarge?.copyWith(
            color: brand.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacers.h16,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mentor.categories!.map((category) {
            return BrandChip(category);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServicesSection(
    Mentor mentor,
    AppBrand brand,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services Offered',
          style: textTheme.titleLarge?.copyWith(
            color: brand.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacers.h16,

        // Service Cards
        if (mentor.services != null) ...[
          _buildServiceCard(
            icon: Icons.video_call,
            title: 'Virtual Appointments',
            description: 'Schedule video calls for personalized mentoring',
            price: mentor.virtualAppointmentPrice,
            isAvailable:
                mentor.services == ServiceType.virtualAppointments ||
                mentor.services == ServiceType.both,
            brand: brand,
            textTheme: textTheme,
          ),
          Spacers.h12,
          _buildServiceCard(
            icon: Icons.chat,
            title: 'Chat Sessions',
            description: 'Get guidance through text-based conversations',
            price: mentor.chatPrice,
            isAvailable:
                mentor.services == ServiceType.chats ||
                mentor.services == ServiceType.both,
            brand: brand,
            textTheme: textTheme,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: brand.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brand.softGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: brand.graphite),
                Spacers.w12,
                Expanded(
                  child: Text(
                    'Service information not available',
                    style: textTheme.bodyMedium?.copyWith(
                      color: brand.graphite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required double? price,
    required bool isAvailable,
    required AppBrand brand,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : brand.surfaceAlt.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? brand.softGrey : brand.softGrey.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAvailable
                  ? brand.brand.withOpacity(0.1)
                  : brand.graphite.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isAvailable
                  ? brand.brand
                  : brand.graphite.withOpacity(0.6),
              size: 24,
            ),
          ),
          Spacers.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: isAvailable
                        ? brand.ink
                        : brand.graphite.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacers.h4,
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: isAvailable
                        ? brand.graphite
                        : brand.graphite.withOpacity(0.6),
                  ),
                ),
                if (price != null && isAvailable) ...[
                  Spacers.h8,
                  Text(
                    '\$${price.toStringAsFixed(0)}/session',
                    style: textTheme.bodyMedium?.copyWith(
                      color: brand.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: brand.graphite.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Not Available',
                style: textTheme.bodySmall?.copyWith(
                  color: brand.graphite.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Mentor mentor,
    AppBrand brand,
    TextTheme textTheme,
  ) {
    final canScheduleCall =
        (mentor.services == ServiceType.virtualAppointments ||
            mentor.services == ServiceType.both) &&
        mentor.calendlyUrl != null &&
        mentor.calendlyUrl!.isNotEmpty;

    final canStartChat =
        mentor.services == ServiceType.chats ||
        mentor.services == ServiceType.both;

    // Get current user to check for existing chat
    final firebaseUserAsync = ref.watch(firebaseUserStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Schedule Call Button
        if (canScheduleCall)
          ElevatedButton.icon(
            onPressed: () => UrlLauncherService.launchCalendlyUrl(
              context,
              mentor.calendlyUrl!,
            ),
            icon: const Icon(Icons.video_call),
            label: const Text('Schedule Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: brand.brand,
              foregroundColor: brand.ink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

        if (canScheduleCall && canStartChat) Spacers.h12,

        // Start Chat Button - check if chat exists
        if (canStartChat)
          firebaseUserAsync.when(
            data: (firebaseUser) {
              if (firebaseUser == null) {
                return OutlinedButton.icon(
                  onPressed: () => _startChat(context, ref, mentor),
                  icon: const Icon(Icons.chat),
                  label: const Text('Start Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brand.brand,
                    side: BorderSide(color: brand.brand),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }

              // Check if chat already exists
              final existingChatAsync = ref.watch(
                existingChatProvider((
                  mentorId: mentor.id,
                  menteeId: firebaseUser.uid,
                )),
              );

              return existingChatAsync.when(
                data: (existingChat) {
                  final hasExistingChat = existingChat != null;
                  return OutlinedButton.icon(
                    onPressed: () => _startChat(context, ref, mentor),
                    icon: const Icon(Icons.chat),
                    label: Text(
                      hasExistingChat ? 'Continue Conversation' : 'Start Chat',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brand.brand,
                      side: BorderSide(color: brand.brand),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                loading: () => OutlinedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: const Text('Loading...'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brand.brand,
                    side: BorderSide(color: brand.brand),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                error: (_, __) => OutlinedButton.icon(
                  onPressed: () => _startChat(context, ref, mentor),
                  icon: const Icon(Icons.chat),
                  label: const Text('Start Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brand.brand,
                    side: BorderSide(color: brand.brand),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
            loading: () => OutlinedButton.icon(
              onPressed: null,
              icon: const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Loading...'),
              style: OutlinedButton.styleFrom(
                foregroundColor: brand.brand,
                side: BorderSide(color: brand.brand),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            error: (_, __) => OutlinedButton.icon(
              onPressed: () => _startChat(context, ref, mentor),
              icon: const Icon(Icons.chat),
              label: const Text('Start Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: brand.brand,
                side: BorderSide(color: brand.brand),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // No services available message
        if (!canScheduleCall && !canStartChat)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: brand.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brand.softGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: brand.graphite),
                Spacers.w12,
                Expanded(
                  child: Text(
                    'This mentor is not currently accepting new sessions.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: brand.graphite,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _startChat(
    BuildContext context,
    WidgetRef ref,
    Mentor mentor,
  ) async {
    try {
      // Use FirebaseAuth.instance.currentUser for reliable, synchronous access
      final firebaseUser = FirebaseAuth.instance.currentUser;

      // Log authentication status
      print(
        '🔐 AUTH CHECK: User is ${firebaseUser != null ? 'authenticated' : 'not authenticated'}',
      );
      if (firebaseUser != null) {
        print('🔐 User ID: ${firebaseUser.uid}');
        print('🔐 User Email: ${firebaseUser.email}');
        print('🔐 User Display Name: ${firebaseUser.displayName}');
      }

      if (firebaseUser == null) {
        print('❌ CHAT CREATION FAILED: User not authenticated');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to start a chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Log chat creation attempt details
      print('💬 STARTING CHAT CREATION:');
      print('💬 Mentor ID: ${mentor.id}');
      print('💬 Mentee ID: ${firebaseUser.uid}');
      print('💬 Chat ID will be: ${firebaseUser.uid}_${mentor.id}');

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Create or find existing chat using the provider
      print('💬 Calling createOrFindChat...');
      final createOrFindChat = ref.watch(createOrFindChatProvider);
      final chat = await createOrFindChat(mentor.id, firebaseUser.uid);

      print(
        '✅ CHAT CREATION SUCCESS: Chat created/found with ID: ${chat.chatId}',
      );

      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to chat screen
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          AppRouter.chat,
          arguments: ChatScreenArguments(
            chat: chat,
            otherParticipantId: mentor.id,
            otherParticipantName: mentor.name,
          ),
        );
      }
    } catch (e, stackTrace) {
      // Log the full error details
      print('❌ CHAT CREATION ERROR:');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace: $stackTrace');

      // Hide loading indicator if still showing
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        // Show the actual error in development, user-friendly message in production
        const bool isDebugMode =
            true; // You can make this dynamic based on build mode

        String errorMessage;
        if (isDebugMode) {
          errorMessage = 'DEBUG: $e'; // Show actual error in debug
        } else if (e.toString().contains('Permission denied')) {
          errorMessage =
              'Unable to start chat. Please ensure you\'re signed in and try again.';
        } else if (e.toString().contains('Network error')) {
          errorMessage =
              'Network connection issue. Please check your internet and try again.';
        } else if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Please sign in again to start a chat.';
        } else {
          errorMessage = 'Failed to start chat. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(
              seconds: 6,
            ), // Longer duration for debug messages
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }
}
