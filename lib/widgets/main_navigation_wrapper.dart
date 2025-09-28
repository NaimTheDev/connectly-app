import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_providers.dart';
import '../screens/home_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/mentors_screen.dart';
import '../screens/calls_screen.dart';
import '../screens/user_settings_screen.dart';
import '../theme/theme.dart';

/// Main navigation wrapper with bottom navigation bar
class MainNavigationWrapper extends ConsumerStatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  ConsumerState<MainNavigationWrapper> createState() =>
      _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends ConsumerState<MainNavigationWrapper> {
  int _currentIndex = 0;

  // Using IndexedStack to preserve state across tabs
  final List<Widget> _screens = [
    HomeScreen(),
    MessagesScreen(),
    MentorsScreen(),
    CallsScreen(),
    UserSettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        selectedItemColor: brand.brand,
        unselectedItemColor: brand.graphite.withOpacity(0.6),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 8,
        items: NavigationTab.values.map((tab) {
          return BottomNavigationBarItem(
            icon: Icon(tab.icon),
            activeIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: brand.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(tab.icon),
            ),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}
