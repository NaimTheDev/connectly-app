import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/chat.dart';
import '../../models/message.dart';

part 'chats_providers.g.dart';

class ChatWithLatestMessage {
  final Chat chat;
  final Message? latestMessage;

  const ChatWithLatestMessage({required this.chat, this.latestMessage});
}

typedef DeleteChatCallback = Future<void> Function(String chatId);

@Riverpod(keepAlive: true)
DeleteChatCallback deleteChat(DeleteChatRef ref) {
  return (chatId) async {
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);
    final messagesSnapshot = await chatRef.collection('messages').get();
    final batch = firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(chatRef);
    await batch.commit();
  };
}

@riverpod
Future<List<ChatWithLatestMessage>> chatsWithLatestMessage(
  ChatsWithLatestMessageRef ref,
  String uid,
) async {
  final mentorSnap = await FirebaseFirestore.instance
      .collection('chats')
      .where('mentorId', isEqualTo: uid)
      .get();

  final menteeSnap = await FirebaseFirestore.instance
      .collection('chats')
      .where('menteeId', isEqualTo: uid)
      .get();

  final results = <ChatWithLatestMessage>[];

  for (final doc in [...mentorSnap.docs, ...menteeSnap.docs]) {
    final chat = Chat.fromMap(doc.id, doc.data());
    final latest = await _getLatestMessage(chat.chatId);
    results.add(ChatWithLatestMessage(chat: chat, latestMessage: latest));
  }

  results.sort((a, b) {
    final aTs = a.latestMessage?.timestamp ?? a.chat.timestamp;
    final bTs = b.latestMessage?.timestamp ?? b.chat.timestamp;
    return bTs.compareTo(aTs);
  });

  return results;
}

@riverpod
Stream<List<ChatWithLatestMessage>> chatsStream(
  ChatsStreamRef ref,
  String uid,
) {
  final controller = StreamController<List<ChatWithLatestMessage>>();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> mentorDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> menteeDocs = [];

  Future<void> emit() async {
    try {
      final results = <ChatWithLatestMessage>[];
      for (final doc in [...mentorDocs, ...menteeDocs]) {
        final chat = Chat.fromMap(doc.id, doc.data());
        final latest = await _getLatestMessage(chat.chatId);
        results.add(ChatWithLatestMessage(chat: chat, latestMessage: latest));
      }
      results.sort((a, b) {
        final aTs = a.latestMessage?.timestamp ?? a.chat.timestamp;
        final bTs = b.latestMessage?.timestamp ?? b.chat.timestamp;
        return bTs.compareTo(aTs);
      });
      if (!controller.isClosed) controller.add(results);
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  final mentorSub = FirebaseFirestore.instance
      .collection('chats')
      .where('mentorId', isEqualTo: uid)
      .snapshots()
      .listen((snap) {
    mentorDocs = snap.docs;
    emit();
  });

  final menteeSub = FirebaseFirestore.instance
      .collection('chats')
      .where('menteeId', isEqualTo: uid)
      .snapshots()
      .listen((snap) {
    menteeDocs = snap.docs;
    emit();
  });

  ref.onDispose(() {
    mentorSub.cancel();
    menteeSub.cancel();
    controller.close();
  });

  return controller.stream;
}

Future<Message?> _getLatestMessage(String chatId) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return Message.fromMap(snap.docs.first.id, snap.docs.first.data());
    }
  } catch (e) {
    debugPrint('_getLatestMessage($chatId): $e');
  }
  return null;
}
