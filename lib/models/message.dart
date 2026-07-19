import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
abstract class Message with _$Message {
  const Message._();

  const factory Message({
    required String messageId,
    required String message,
    required String receiverId,
    required String senderId,
    required int timestamp,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  static Message fromMap(String id, Map<String, dynamic> data) {
    return Message(
      messageId: id,
      message: data['message'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      timestamp: data['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'message': message,
    'receiverId': receiverId,
    'senderId': senderId,
    'timestamp': timestamp,
  };

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  bool isSentByUser(String currentUserId) => senderId == currentUserId;
}
