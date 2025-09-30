import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mentor.dart';
import '../models/scheduled_call.dart';
import '../providers/mentors_providers.dart';
import '../providers/scheduled_calls_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/onboarding_providers.dart';
import '../services/url_launcher_service.dart';
import '../theme/theme.dart';
import '../widgets/spacers.dart';
import '../widgets/main_navigation_wrapper.dart';
import 'sign_in_screen.dart';
import 'onboarding/onboarding_flow_screen.dart';

/// AuthGate widget that checks authentication and onboarding status to route users appropriately.
/// This enables reactive navigation logic with Riverpod.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedInAsync = ref.watch(isSignedInProvider);

    return isSignedInAsync.when(
      data: (signedIn) {
        if (!signedIn) {
          return const SignInScreen();
        }

        // User is signed in, check if they need onboarding
        final firebaseUserAsync = ref.watch(firebaseUserStreamProvider);
        return firebaseUserAsync.when(
          data: (firebaseUser) {
            if (firebaseUser == null) {
              return const SignInScreen();
            }

            // Check onboarding status
            final needsOnboardingAsync = ref.watch(
              needsOnboardingProvider(firebaseUser.uid),
            );
            return needsOnboardingAsync.when(
              data: (needsOnboarding) {
                if (needsOnboarding) {
                  return const OnboardingFlowScreen();
                } else {
                  return const MainNavigationWrapper();
                }
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) {
                // If error checking onboarding status, default to onboarding for safety
                return const OnboardingFlowScreen();
              },
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, _) =>
              Scaffold(body: Center(child: Text('Auth error: $err'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) =>
          Scaffold(body: Center(child: Text('Auth error: $err'))),
    );
  }
}

/// HomeScreen displays the main dashboard for the app.
/// TODO: Wire up real providers for user, mentors, and calls.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user UID from auth state
    final firebaseUserAsync = ref.watch(firebaseUserStreamProvider);
    return firebaseUserAsync.when(
      data: (firebaseUser) {
        final String uid = firebaseUser?.uid ?? '';
        final mentorsAsync = ref.watch(mentorsProvider);
        final callsAsync = ref.watch(scheduledCallsProvider(uid));

        final brand = Theme.of(context).extension<AppBrand>()!;
        final textTheme = Theme.of(context).textTheme;

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Title
                    Center(
                      child: Text(
                        'Connectly',
                        style: textTheme.headlineSmall?.copyWith(
                          color: brand.brand,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacers.h24,

                    // Featured Mentors Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Mentors',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: brand.ink,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to all mentors
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See All',
                                style: TextStyle(
                                  color: brand.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: brand.brand,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Spacers.h16,
                    // Mentors Horizontal List
                    mentorsAsync.when(
                      data: (mentors) => mentors.isEmpty
                          ? const _LoadingOrEmpty(
                              isLoading: false,
                              emptyMessage: 'No mentors available.',
                            )
                          : SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: mentors.length,
                                separatorBuilder: (_, __) => Spacers.w12,
                                itemBuilder: (context, i) => _MentorCard(
                                  mentor: mentors[i],
                                  cardIndex: i,
                                ),
                              ),
                            ),
                      loading: () => const _LoadingOrEmpty(
                        isLoading: true,
                        emptyMessage: '',
                      ),
                      error: (err, _) => _LoadingOrEmpty(
                        isLoading: false,
                        emptyMessage: 'Failed to load mentors.',
                      ),
                    ),
                    Spacers.h32,
                    // Upcoming Calls Section
                    Row(
                      children: [
                        Text(
                          'Upcoming Calls',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: brand.ink,
                          ),
                        ),
                        Spacers.w8,
                        Icon(
                          Icons.calendar_today,
                          color: brand.graphite,
                          size: 20,
                        ),
                      ],
                    ),
                    Spacers.h16,
                    // Calls Layout
                    callsAsync.when(
                      data: (calls) => calls.isEmpty
                          ? const _LoadingOrEmpty(
                              isLoading: false,
                              emptyMessage: 'No upcoming calls.',
                            )
                          : Column(
                              children: [
                                // Main featured call card
                                if (calls.isNotEmpty)
                                  _FeaturedCallCard(call: calls.first),
                                if (calls.length > 1) ...[
                                  Spacers.h16,
                                  // Additional calls row
                                  Row(
                                    children: [
                                      for (
                                        int i = 1;
                                        i < calls.length && i < 3;
                                        i++
                                      ) ...[
                                        Expanded(
                                          child: _SmallCallCard(call: calls[i]),
                                        ),
                                        if (i < calls.length - 1 && i < 2)
                                          Spacers.w12,
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                      loading: () => const _LoadingOrEmpty(
                        isLoading: true,
                        emptyMessage: '',
                      ),
                      error: (err, _) => _LoadingOrEmpty(
                        isLoading: false,
                        emptyMessage: 'Failed to load calls.',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) =>
          Scaffold(body: Center(child: Text('Auth error: $err'))),
    );
  }
}

/// Responsive avatar widget for mentors with proper image handling.
class MentorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color backgroundColor;
  final Color textColor;

  const MentorAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.backgroundColor = Colors.amber,
    this.textColor = Colors.white,
  });

  String get _initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildFallback();
                },
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Card for displaying mentor info and specialties.
class _MentorCard extends StatelessWidget {
  final Mentor mentor;
  final int cardIndex;
  const _MentorCard({required this.mentor, required this.cardIndex});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;

    // Define colors using theme-appropriate colors for device compatibility
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColors = isDark
        ? [
            brand.surfaceElevated, // Use theme surface
            brand.brand.withValues(alpha: 0.15), // Subtle brand
            brand.accentPurple.withValues(alpha: 0.1), // Subtle purple
            brand.info.withValues(alpha: 0.1), // Subtle info
          ]
        : [
            brand.surfaceAlt, // Light theme surface alt
            brand.brand.withValues(alpha: 0.08), // Very subtle brand
            brand.accentPurple.withValues(alpha: 0.06), // Very subtle purple
            brand.info.withValues(alpha: 0.06), // Very subtle info
          ];

    final cardColor = cardColors[cardIndex % cardColors.length];

    return Semantics(
      label: 'Featured mentor ${mentor.name}',
      button: true,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/mentor/${mentor.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? brand.graphite.withValues(alpha: 0.4)
                  : brand.softGrey.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Profile Picture
              MentorAvatar(
                name: mentor.name,
                imageUrl: mentor.imageUrl,
                size: 56,
                backgroundColor: brand.brand,
                textColor: Colors.white,
              ),
              Spacers.w16,
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mentor.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: brand.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (mentor.expertise.isNotEmpty) ...[
                      Spacers.h4,
                      Text(
                        mentor.expertise,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: brand.ink.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Featured call card with purple background (matches mockup)
class _FeaturedCallCard extends StatelessWidget {
  final ScheduledCall call;
  const _FeaturedCallCard({required this.call});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;

    // Parse ISO8601 start time (fallback to raw if parse fails)
    DateTime? start;
    try {
      start = DateTime.tryParse(call.startTime)?.toLocal();
    } catch (_) {
      start = null;
    }
    // Compute relative day label (TODAY / TOMORROW / weekday)
    String dayLabel;
    if (start != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thatDay = DateTime(start.year, start.month, start.day);
      final diffDays = thatDay.difference(today).inDays;
      if (diffDays == 0) {
        dayLabel = 'TODAY';
      } else if (diffDays == 1) {
        dayLabel = 'TOMORROW';
      } else {
        const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
        dayLabel = weekdays[start.weekday - 1];
      }
    } else {
      dayLabel = 'UPCOMING';
    }

    String timePart;
    if (start != null) {
      final hour = start.hour % 12 == 0 ? 12 : start.hour % 12;
      final minute = start.minute.toString().padLeft(2, '0');
      final amPm = start.hour >= 12 ? 'PM' : 'AM';
      timePart = '$hour:$minute $amPm';
    } else {
      timePart = call.startTime; // fallback raw
    }

    final timeText = '$dayLabel, $timePart';

    // Determine display name (mentor vs invitee). We only have inviteeName here; keep label generic.
    final mentorName =
        'Call with ${call.inviteeName.isNotEmpty ? call.inviteeName : "Mentor"}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brand
            .brand, // Purple color from mockup (could move to theme if standardized)
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacers.h8,
                Text(
                  mentorName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Spacers.w16,
          ElevatedButton(
            onPressed: (call.joinUrl != null && call.joinUrl!.isNotEmpty)
                ? () => UrlLauncherService.launchJoinUrl(context, call.joinUrl!)
                : null,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: brand.graphite, // primary action on accent card
              foregroundColor: brand.brand, // readable + on-brand accent
              disabledBackgroundColor: brand.graphite.withValues(alpha: 0.4),
              disabledForegroundColor: brand.brand.withValues(alpha: 0.4),
              overlayColor: brand.ink.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(brand.radius - 4),
              ),
            ),
            child: const Text('Join Call'),
          ),
        ],
      ),
    );
  }
}

/// Small call card for additional upcoming calls
class _SmallCallCard extends StatelessWidget {
  final ScheduledCall call;
  const _SmallCallCard({required this.call});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;

    // Format date - using placeholder for demo
    final dateText = call.startTime.contains('24')
        ? 'July 24, 2:00 PM'
        : 'July 30, 2:00 PM';
    final subText = call.startTime.contains('24')
        ? 'July 24, 2:00 PM'
        : 'July 30, 3 PM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.softGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.softGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateText.split(',').first, // "July 24" or "July 30"
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: brand.ink,
            ),
          ),
          Spacers.h4,
          Text(
            subText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: brand.graphite),
          ),
        ],
      ),
    );
  }
}

/// Widget for showing loading or empty state.
class _LoadingOrEmpty extends StatelessWidget {
  final bool isLoading;
  final String emptyMessage;
  const _LoadingOrEmpty({required this.isLoading, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
