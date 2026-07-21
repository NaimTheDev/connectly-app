import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/app_user.dart';

part 'user_providers.g.dart';

@riverpod
Future<AppUser?> appUser(Ref ref, String uid) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return null;
  return AppUser.fromMap(doc.id, doc.data()!);
}
