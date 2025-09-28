import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message.dart';

/// Messages in a chat (only for participants)
final messagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      chatId,
    ) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    });

/// Real-time stream of messages for a specific chat
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: false) // Ascending for chat display
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Message.fromMap(doc.id, doc.data()))
            .toList();
      });
});

/// Provider to send a message to a chat
final sendMessageProvider = Provider((ref) {
  return (
    String chatId,
    String message,
    String senderId,
    String receiverId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'message': message,
            'senderId': senderId,
            'receiverId': receiverId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

      // Update the chat's timestamp to reflect latest activity
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  };
});
