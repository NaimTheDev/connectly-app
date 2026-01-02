import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat.dart';

/// Provider to check if a chat already exists between a mentor and mentee
// Real-time provider to observe whether a chat exists between mentor and mentee
// and return the Chat data if it does. Using StreamProvider ensures the UI
// reacts immediately after creation without requiring a hot restart.
final existingChatStreamProvider = StreamProvider.family
    .autoDispose<Chat?, ({String mentorId, String menteeId})>((ref, params) {
      final chatId = '${params.menteeId}_${params.mentorId}';

      return FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) return null;
            final data = snapshot.data();
            if (data == null) return null;
            return Chat.fromMap(snapshot.id, data);
          });
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
        throw Exception(e.toString());
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
