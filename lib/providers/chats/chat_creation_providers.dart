import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/chat.dart';

part 'chat_creation_providers.g.dart';

@riverpod
Stream<Chat?> existingChatStream(
  ExistingChatStreamRef ref,
  ({String mentorId, String menteeId}) params,
) {
  final chatId = '${params.menteeId}_${params.mentorId}';
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return Chat.fromMap(snap.id, snap.data()!);
  });
}

typedef CreateOrFindChatCallback = Future<Chat> Function(
    String mentorId, String menteeId);

@Riverpod(keepAlive: true)
CreateOrFindChatCallback createOrFindChat(CreateOrFindChatRef ref) {
  return (String mentorId, String menteeId) async {
    final chatId = '${menteeId}_$mentorId';
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) throw Exception('User not authenticated');
    if (user.uid != mentorId && user.uid != menteeId) {
      throw Exception('User not authorized to create this chat');
    }

    final existing = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();

    if (existing.exists) {
      return Chat.fromMap(existing.id, existing.data()!);
    }

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'mentorId': mentorId,
      'menteeId': menteeId,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTimestamp': null,
    });

    return Chat(
      chatId: chatId,
      mentorId: mentorId,
      menteeId: menteeId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  };
}
