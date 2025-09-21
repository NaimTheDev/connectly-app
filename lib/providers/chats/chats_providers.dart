import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Authenticated user's chats
final chatsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  },
);
