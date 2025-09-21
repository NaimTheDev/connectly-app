import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firebaseUserStreamProvider = StreamProvider((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.firebaseUserStream;
});

final isSignedInProvider = StreamProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.firebaseUserStream.map((user) => user != null);
});
