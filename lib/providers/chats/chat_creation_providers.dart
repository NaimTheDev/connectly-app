import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      // Ensure we have proper authentication
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Verify the current user is either the mentor or mentee
      if (user.uid != mentorId && user.uid != menteeId) {
        throw Exception('User not authorized to create this chat');
      }

      // Check if chat already exists
      final existingChatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (existingChatDoc.exists) {
        // Return existing chat
        return Chat.fromMap(existingChatDoc.id, existingChatDoc.data()!);
      }

      // Create new chat document in Firestore with proper timestamp
      final newChatData = {
        'mentorId': mentorId,
        'menteeId': menteeId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTimestamp': null,
      };

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set(newChatData);

      // Return the newly created chat with current timestamp
      final chatDataForReturn = {
        ...newChatData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      return Chat.fromMap(chatId, chatDataForReturn);
    } catch (e) {
      // More specific error handling
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Permission denied: Check your authentication and try again',
        );
      } else if (e.toString().contains('network')) {
        throw Exception(
          'Network error: Please check your connection and try again',
        );
      } else {
        throw Exception('Failed to create or find chat: ${e.toString()}');
      }
    }
  };
});
