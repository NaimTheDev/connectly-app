import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) => AuthService();

@riverpod
Stream<User?> firebaseUserStream(FirebaseUserStreamRef ref) {
  return ref.watch(authServiceProvider).firebaseUserStream;
}

@riverpod
Stream<bool> isSignedIn(IsSignedInRef ref) {
  return ref
      .watch(authServiceProvider)
      .firebaseUserStream
      .map((user) => user != null);
}
