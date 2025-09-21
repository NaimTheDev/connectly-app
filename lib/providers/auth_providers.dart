import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firebaseUserStreamProvider = StreamProvider((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.firebaseUserStream;
});

final appUserProvider = StateProvider<AppUser?>((ref) => null);
