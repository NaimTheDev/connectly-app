import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart'; // TODO: Use context.push when go_router is available
import '../models/app_user.dart';
import '../models/mentor.dart';
import '../models/scheduled_call.dart';
import '../providers/auth_providers.dart';
import '../theme/theme.dart';
import '../widgets/brand_chip.dart';
import '../widgets/spacers.dart';
import 'sign_in_screen.dart';

/// AuthGate widget that uses isSignedInProvider to show HomeScreen or SignInScreen based on auth state.
/// This enables reactive navigation logic with Riverpod.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedInAsync = ref.watch(isSignedInProvider);
    return isSignedInAsync.when(
      data: (signedIn) {
        if (signedIn) {
          // User is signed in, show HomeScreen
          return const HomeScreen();
        } else {
          // Not signed in, show SignInScreen
          return const SignInScreen();
        }
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
    // TODO: Replace with real provider when available
    // Wire up real providers
    final AppUser? currentUser = ref.watch(appUserProvider);
    final mentorsAsync = ref.watch(mentorsProvider);
    final callsAsync = ref.watch(scheduledCallsProvider);

    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Connectly', // TODO: Use brand/app name from ThemeExtension if available
          style: textTheme.titleLarge?.copyWith(color: brand.brand),
        ),
        backgroundColor: brand.softGrey,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final mentorColumns = constraints.maxWidth >= 1200
              ? 4
              : constraints.maxWidth >= 800
              ? 3
              : 2;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GreetingCard(
                  user:
                      currentUser ??
                      AppUser(
                        uid: '0',
                        email: '',
                        role: UserRole.mentee,
                        name: 'User',
                      ),
                  brand: brand,
                ),
                Spacers.h16,
                Row(
                  children: [
                    const BrandChip('Flutter'),
                    Spacers.w8,
                    const BrandChip('Mentorship'),
                    Spacers.w8,
                    const BrandChip('Community'),
                  ],
                ),
                Spacers.h24,
                Text('Mentors', style: textTheme.titleMedium),
                Spacers.h8,
                mentorsAsync.when(
                  data: (mentors) => mentors.isEmpty
                      ? const _LoadingOrEmpty(
                          isLoading: false,
                          emptyMessage: 'No mentors available.',
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: mentorColumns,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: isWide ? 2.5 : 1.5,
                              ),
                          itemCount: mentors.length,
                          itemBuilder: (context, i) =>
                              _MentorCard(mentor: mentors[i]),
                        ),
                  loading: () =>
                      const _LoadingOrEmpty(isLoading: true, emptyMessage: ''),
                  error: (err, _) => _LoadingOrEmpty(
                    isLoading: false,
                    emptyMessage: 'Failed to load mentors.',
                  ),
                ),
                Spacers.h24,
                Text('Upcoming Calls', style: textTheme.titleMedium),
                Spacers.h8,
                callsAsync.when(
                  data: (calls) => calls.isEmpty
                      ? const _LoadingOrEmpty(
                          isLoading: false,
                          emptyMessage: 'No upcoming calls.',
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: calls.length,
                          separatorBuilder: (_, __) => Spacers.h8,
                          itemBuilder: (context, i) =>
                              _CallTile(call: calls[i]),
                        ),
                  loading: () =>
                      const _LoadingOrEmpty(isLoading: true, emptyMessage: ''),
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
  }
}

/// Card greeting the user by first name.
class _GreetingCard extends StatelessWidget {
  final AppUser user;
  final AppBrand brand;
  const _GreetingCard({required this.user, required this.brand});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: brand.softGrey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.waving_hand, color: brand.brand, size: 32),
            Spacers.w16,
            Expanded(
              child: Text(
                'Welcome, ${user.firstName ?? user.name ?? "User"}',
                style: textTheme.headlineSmall?.copyWith(color: brand.ink),
                semanticsLabel:
                    'Welcome, ${user.firstName ?? user.name ?? "User"}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for displaying mentor info and specialties.
class _MentorCard extends StatelessWidget {
  final Mentor mentor;
  const _MentorCard({required this.mentor});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    return Semantics(
      label: 'Mentor card for ${mentor.name}',
      button: true,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/mentor/${mentor.id}');
        },
        child: Card(
          color: brand.softGrey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: brand.brand,
                  backgroundImage: mentor.imageUrl != null
                      ? NetworkImage(mentor.imageUrl!)
                      : null,
                  child: mentor.imageUrl == null
                      ? Text(
                          mentor.name.isNotEmpty ? mentor.name[0] : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Spacers.w16,
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mentor.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacers.h4,
                        Text(
                          mentor.expertise,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
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

/// Tile for displaying a scheduled call.
class _CallTile extends StatelessWidget {
  final ScheduledCall call;
  const _CallTile({required this.call});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    // TODO: Format date/time from call.startTime
    final dateStr = call.startTime;
    return Semantics(
      label: 'Scheduled call on $dateStr',
      child: Card(
        color: brand.softGrey,
        child: ListTile(
          title: Text('Call on $dateStr'),
          trailing: ElevatedButton(
            onPressed: () {}, // TODO: Wire up join logic
            child: const Text('Join'),
          ),
        ),
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
