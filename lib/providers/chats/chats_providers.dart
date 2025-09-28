import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat.dart';
import '../../models/message.dart';

/// Authenticated user's chats
final chatsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, uid) async {
    // Get chats where user is either mentor or mentee
    final mentorChatsSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('mentorId', isEqualTo: uid)
        .get();

    final menteeChatsSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('menteeId', isEqualTo: uid)
        .get();

    // Combine both results
    final allChats = <Map<String, dynamic>>[];
    allChats.addAll(mentorChatsSnapshot.docs.map((doc) => doc.data()));
    allChats.addAll(menteeChatsSnapshot.docs.map((doc) => doc.data()));

    return allChats;
  },
);

/// Chat data with latest message for chat list display
class ChatWithLatestMessage {
  final Chat chat;
  final Message? latestMessage;

  const ChatWithLatestMessage({required this.chat, this.latestMessage});
}

/// Enhanced provider that combines chat data with latest messages
final chatsWithLatestMessageProvider =
    FutureProvider.family<List<ChatWithLatestMessage>, String>((
      ref,
      uid,
    ) async {
      // Get chats where user is either mentor or mentee
      final mentorChatsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('mentorId', isEqualTo: uid)
          .get();

      final menteeChatsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('menteeId', isEqualTo: uid)
          .get();

      final List<ChatWithLatestMessage> chatsWithMessages = [];

      // Process mentor chats
      for (final chatDoc in mentorChatsSnapshot.docs) {
        final chat = Chat.fromMap(chatDoc.id, chatDoc.data());
        final latestMessage = await _getLatestMessage(chat.chatId);
        chatsWithMessages.add(
          ChatWithLatestMessage(chat: chat, latestMessage: latestMessage),
        );
      }

      // Process mentee chats
      for (final chatDoc in menteeChatsSnapshot.docs) {
        final chat = Chat.fromMap(chatDoc.id, chatDoc.data());
        final latestMessage = await _getLatestMessage(chat.chatId);
        chatsWithMessages.add(
          ChatWithLatestMessage(chat: chat, latestMessage: latestMessage),
        );
      }

      // Sort by latest message timestamp, then by chat timestamp
      chatsWithMessages.sort((a, b) {
        final aTimestamp = a.latestMessage?.timestamp ?? a.chat.timestamp;
        final bTimestamp = b.latestMessage?.timestamp ?? b.chat.timestamp;
        return bTimestamp.compareTo(aTimestamp);
      });

      return chatsWithMessages;
    });

/// Helper function to get the latest message for a chat
Future<Message?> _getLatestMessage(String chatId) async {
  try {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (messagesSnapshot.docs.isNotEmpty) {
      final messageDoc = messagesSnapshot.docs.first;
      return Message.fromMap(messageDoc.id, messageDoc.data());
    }
  } catch (e) {
    print('Error fetching latest message for chat $chatId: $e');
  }
  return null;
}
