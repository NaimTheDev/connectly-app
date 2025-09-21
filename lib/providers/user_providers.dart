import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Authenticated user's profile
final appUserProvider = FutureProvider.family<AppUser?, String>((
  ref,
  uid,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  if (!doc.exists) return null;
  final data = doc.data()!;
  return AppUser(
    uid: doc.id,
    email: data['email'] ?? '',
    role: (data['role'] == 'mentor') ? UserRole.mentor : UserRole.mentee,
    imageUrl: data['imageUrl'],
    name: data['name'],
    firstName: data['firstName'],
    lastName: data['lastName'],
  );
});
