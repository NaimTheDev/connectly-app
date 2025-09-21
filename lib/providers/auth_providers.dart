import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../models/mentor.dart';
import '../models/scheduled_call.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firebaseUserStreamProvider = StreamProvider((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.firebaseUserStream;
});

final appUserProvider = StateProvider<AppUser?>((ref) => null);

final isSignedInProvider = StreamProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.firebaseUserStream.map((user) => user != null);
});

/// Replace with real async data source (e.g. Firestore, REST API)
final mentorsProvider = FutureProvider<List<Mentor>>((ref) async {
  // TODO: Replace with real data fetch
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    Mentor(
      id: 'm1',
      name: 'Jane Smith',
      bio: 'Flutter expert',
      expertise: 'Flutter, Dart',
      imageUrl: null,
      categories: ['Flutter', 'Dart'],
      firstName: 'Jane',
      lastName: 'Smith',
    ),
    Mentor(
      id: 'm2',
      name: 'John Lee',
      bio: 'Firebase & UI/UX',
      expertise: 'Firebase, UI/UX',
      imageUrl: null,
      categories: ['Firebase', 'UI/UX'],
      firstName: 'John',
      lastName: 'Lee',
    ),
    Mentor(
      id: 'm3',
      name: 'Sara Kim',
      bio: 'Backend & APIs',
      expertise: 'Backend, APIs',
      imageUrl: null,
      categories: ['Backend', 'APIs'],
      firstName: 'Sara',
      lastName: 'Kim',
    ),
  ];
});

final scheduledCallsProvider = FutureProvider<List<ScheduledCall>>((ref) async {
  // TODO: Replace with real data fetch
  await Future.delayed(const Duration(milliseconds: 500));
  return [];
});
