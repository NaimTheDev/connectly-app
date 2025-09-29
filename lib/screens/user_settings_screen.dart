import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/spacers.dart';
import 'edit_profile_screen.dart';

/// Screen for user settings and profile management
class UserSettingsScreen extends ConsumerWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUserAsync = ref.watch(firebaseUserStreamProvider);
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
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
                  'Please sign in to view settings',
                  style: textTheme.bodyLarge?.copyWith(color: brand.graphite),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _ProfileSection(
                    user: firebaseUser,
                    brand: brand,
                    textTheme: textTheme,
                  ),
                  Spacers.h32,

                  // Settings Sections
                  _SettingsSection(
                    title: 'Account',
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Spacers.h24,

                  Spacers.h32,

                  // Sign Out Section
                  _SignOutSection(ref: ref),
                ],
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

/// Profile section widget
class _ProfileSection extends StatelessWidget {
  final dynamic user;
  final AppBrand brand;
  final TextTheme textTheme;

  const _ProfileSection({
    required this.user,
    required this.brand,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brand.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.softGrey, width: 1),
      ),
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 40,
            backgroundColor: brand.brand,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Text(
                    _getInitials(user.displayName ?? user.email ?? ''),
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          Spacers.h16,

          // User Name
          Text(
            user.displayName ?? 'User',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: brand.ink,
            ),
          ),
          Spacers.h4,

          // User Email
          Text(
            user.email ?? '',
            style: textTheme.bodyMedium?.copyWith(color: brand.graphite),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

/// Settings section widget
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: brand.ink,
          ),
        ),
        Spacers.h12,
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brand.softGrey, width: 1),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(height: 1, color: brand.softGrey, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Individual settings item widget
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: brand.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: brand.brand, size: 20),
            ),
            Spacers.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: brand.ink,
                    ),
                  ),
                  Spacers.h4,
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(color: brand.graphite),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: brand.graphite.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign out section widget
class _SignOutSection extends StatelessWidget {
  final WidgetRef ref;

  const _SignOutSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: brand.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.danger.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: () => _showSignOutDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brand.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout, color: brand.danger, size: 20),
              ),
              Spacers.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign Out',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: brand.danger,
                      ),
                    ),
                    Spacers.h4,
                    Text(
                      'Sign out of your account',
                      style: textTheme.bodySmall?.copyWith(
                        color: brand.danger.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: brand.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: textTheme.bodyMedium?.copyWith(color: brand.graphite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: brand.graphite)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign out: $e'),
                      backgroundColor: brand.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brand.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
