import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum for navigation tabs
enum NavigationTab {
  home(0, 'Home', Icons.home),
  messages(1, 'Messages', Icons.message),
  mentors(2, 'Mentors', Icons.people),
  calls(3, 'Calls', Icons.video_call),
  settings(4, 'Settings', Icons.settings);

  const NavigationTab(this.tabIndex, this.label, this.icon);

  final int tabIndex;
  final String label;
  final IconData icon;

  static NavigationTab fromIndex(int index) {
    return NavigationTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => NavigationTab.home,
    );
  }
}

/// Simple navigation controller using ValueNotifier
final navigationController = ValueNotifier<int>(0);

/// Provider for current tab index
final currentTabIndexProvider = Provider<int>((ref) {
  // This will be updated by the navigation wrapper
  return 0;
});

/// Provider for current navigation tab
final currentNavigationTabProvider = Provider<NavigationTab>((ref) {
  final index = ref.watch(currentTabIndexProvider);
  return NavigationTab.fromIndex(index);
});
