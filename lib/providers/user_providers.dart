import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/app_user.dart';

part 'user_providers.g.dart';

/// Live view of `users/{uid}`.
///
/// Backed by a snapshot listener rather than a one-shot `get()` so screens
/// already on the stack (e.g. Settings behind Edit Profile) reflect writes such
/// as a changed avatar without the caller having to invalidate this provider.
@riverpod
Stream<AppUser?> appUser(Ref ref, String uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);
}
