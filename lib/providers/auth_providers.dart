import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => AuthService();

@riverpod
Stream<User?> firebaseUserStream(Ref ref) {
  return ref.watch(authServiceProvider).firebaseUserStream;
}

@riverpod
Stream<bool> isSignedIn(Ref ref) {
  return ref
      .watch(authServiceProvider)
      .firebaseUserStream
      .map((user) => user != null);
}
