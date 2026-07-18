import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_providers.g.dart';

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

  static NavigationTab fromIndex(int index) => NavigationTab.values.firstWhere(
        (tab) => tab.tabIndex == index,
        orElse: () => NavigationTab.home,
      );
}

@Riverpod(keepAlive: true)
class NavigationNotifier extends _$NavigationNotifier {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

// Keep the old ValueNotifier for widgets that still reference it directly
// TODO: migrate all consumers to navigationNotifierProvider
final navigationController = ValueNotifier<int>(0);

@riverpod
NavigationTab currentNavigationTab(CurrentNavigationTabRef ref) {
  final index = ref.watch(navigationNotifierProvider);
  return NavigationTab.fromIndex(index);
}
