import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scheduled_call.dart';
import '../providers/scheduled_calls_providers.dart';
import '../providers/auth_providers.dart';
import '../services/url_launcher_service.dart';
import '../theme/theme.dart';
import '../widgets/spacers.dart';

/// Screen displaying scheduled calls
class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUserAsync = ref.watch(firebaseUserStreamProvider);
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Calls',
          style: textTheme.headlineSmall?.copyWith(
            color: brand.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: firebaseUserAsync.when(
          data: (firebaseUser) {
            if (firebaseUser == null) {
              return Center(
                child: Text(
                  'Please sign in to view your calls',
                  style: textTheme.bodyLarge?.copyWith(color: brand.graphite),
                ),
              );
            }

            final callsAsync = ref.watch(
              scheduledCallsProvider(firebaseUser.uid),
            );

            return callsAsync.when(
              data: (calls) {
                if (calls.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_call_outlined,
                          size: 64,
                          color: brand.graphite.withOpacity(0.5),
                        ),
                        Spacers.h16,
                        Text(
                          'No scheduled calls',
                          style: textTheme.headlineSmall?.copyWith(
                            color: brand.graphite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacers.h8,
                        Text(
                          'Your upcoming calls will appear here',
                          style: textTheme.bodyMedium?.copyWith(
                            color: brand.graphite.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Separate calls by status/time
                final now = DateTime.now();
                final upcomingCalls = <ScheduledCall>[];
                final pastCalls = <ScheduledCall>[];

                for (final call in calls) {
                  try {
                    final startTime = DateTime.parse(call.startTime);
                    if (startTime.isAfter(now)) {
                      upcomingCalls.add(call);
                    } else {
                      pastCalls.add(call);
                    }
                  } catch (e) {
                    // If parsing fails, treat as upcoming
                    upcomingCalls.add(call);
                  }
                }

                // Sort calls by start time
                upcomingCalls.sort((a, b) {
                  try {
                    return DateTime.parse(
                      a.startTime,
                    ).compareTo(DateTime.parse(b.startTime));
                  } catch (e) {
                    return 0;
                  }
                });

                pastCalls.sort((a, b) {
                  try {
                    return DateTime.parse(
                      b.startTime,
                    ).compareTo(DateTime.parse(a.startTime));
                  } catch (e) {
                    return 0;
                  }
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upcoming Calls Section
                      if (upcomingCalls.isNotEmpty) ...[
                        Text(
                          'Upcoming Calls',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: brand.ink,
                          ),
                        ),
                        Spacers.h16,
                        ...upcomingCalls.map(
                          (call) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CallCard(call: call, isUpcoming: true),
                          ),
                        ),
                        if (pastCalls.isNotEmpty) Spacers.h32,
                      ],

                      // Past Calls Section
                      if (pastCalls.isNotEmpty) ...[
                        Text(
                          'Past Calls',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: brand.ink,
                          ),
                        ),
                        Spacers.h16,
                        ...pastCalls.map(
                          (call) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CallCard(call: call, isUpcoming: false),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: brand.danger),
                    Spacers.h16,
                    Text(
                      'Failed to load calls',
                      style: textTheme.bodyLarge?.copyWith(color: brand.danger),
                    ),
                    Spacers.h8,
                    Text(
                      'Please try again later',
                      style: textTheme.bodyMedium?.copyWith(
                        color: brand.graphite.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              'Authentication error',
              style: textTheme.bodyLarge?.copyWith(color: brand.danger),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card widget for displaying individual calls
class _CallCard extends StatelessWidget {
  final ScheduledCall call;
  final bool isUpcoming;

  const _CallCard({required this.call, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    // Format the date and time
    String formattedDateTime = call.startTime;
    String dayLabel = '';

    try {
      final startTime = DateTime.parse(call.startTime).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final callDay = DateTime(startTime.year, startTime.month, startTime.day);
      final diffDays = callDay.difference(today).inDays;

      if (diffDays == 0) {
        dayLabel = 'Today';
      } else if (diffDays == 1) {
        dayLabel = 'Tomorrow';
      } else if (diffDays == -1) {
        dayLabel = 'Yesterday';
      } else {
        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        dayLabel = weekdays[startTime.weekday - 1];
      }

      final hour = startTime.hour % 12 == 0 ? 12 : startTime.hour % 12;
      final minute = startTime.minute.toString().padLeft(2, '0');
      final amPm = startTime.hour >= 12 ? 'PM' : 'AM';
      formattedDateTime = '$dayLabel, $hour:$minute $amPm';
    } catch (e) {
      // Keep original format if parsing fails
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUpcoming ? brand.brand.withOpacity(0.3) : brand.softGrey,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isUpcoming ? brand.brand.withOpacity(0.05) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with time and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formattedDateTime,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: brand.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? brand.success.withOpacity(0.1)
                          : brand.graphite.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUpcoming ? 'Upcoming' : 'Completed',
                      style: textTheme.bodySmall?.copyWith(
                        color: isUpcoming ? brand.success : brand.graphite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Spacers.h8,

              // Invitee name
              Text(
                'Call with ${call.inviteeName.isNotEmpty ? call.inviteeName : "Mentor"}',
                style: textTheme.bodyLarge?.copyWith(
                  color: brand.graphite,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Action buttons for upcoming calls
              if (isUpcoming &&
                  call.joinUrl != null &&
                  call.joinUrl!.isNotEmpty) ...[
                Spacers.h12,
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => UrlLauncherService.launchJoinUrl(
                        context,
                        call.joinUrl!,
                      ),
                      icon: const Icon(Icons.video_call, size: 18),
                      label: const Text('Join Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand.brand,
                        foregroundColor: brand.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        textStyle: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacers.w12,
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Show call details or reschedule options
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brand.graphite,
                        side: BorderSide(color: brand.softGrey),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        textStyle: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
