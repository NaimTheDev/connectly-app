import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat.dart';

/// Provider to check if a chat already exists between a mentor and mentee
final existingChatProvider =
    FutureProvider.family<Chat?, ({String mentorId, String menteeId})>((
      ref,
      params,
    ) async {
      final chatId = '${params.menteeId}_${params.mentorId}';

      try {
        final existingChatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();

        if (existingChatDoc.exists) {
          return Chat.fromMap(existingChatDoc.id, existingChatDoc.data()!);
        }

        return null;
      } catch (e) {
        return null;
      }
    });

/// Provider to create or find an existing chat between a mentor and mentee
final createOrFindChatProvider = Provider((ref) {
  return (String mentorId, String menteeId) async {
    final chatId = '${menteeId}_${mentorId}';

    try {
      // Check if chat already exists
      final existingChatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (existingChatDoc.exists) {
        // Return existing chat
        return Chat.fromMap(existingChatDoc.id, existingChatDoc.data()!);
      }

      // Create new chat document in Firestore
      final newChatData = {
        'mentorId': mentorId,
        'menteeId': menteeId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set(newChatData);

      // Return the newly created chat
      return Chat.fromMap(chatId, newChatData);
    } catch (e) {
      throw Exception('Failed to create or find chat: $e');
    }
  };
});
