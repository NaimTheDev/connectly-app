import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/message.dart';

part 'messages_providers.g.dart';

@riverpod
Stream<List<Message>> messagesStream(Ref ref, String chatId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => Message.fromMap(doc.id, doc.data())).toList());
}

typedef SendMessageCallback = Future<void> Function({
  required String chatId,
  required String message,
  required String senderId,
  required String receiverId,
});

@Riverpod(keepAlive: true)
SendMessageCallback sendMessage(Ref ref) {
  return ({
    required String chatId,
    required String message,
    required String senderId,
    required String receiverId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatRef.collection('messages').add({
      'message': message,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': now,
    });
    await chatRef.update({'timestamp': now});
  };
}
