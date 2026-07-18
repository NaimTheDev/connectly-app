import 'package:freezed_annotation/freezed_annotation.dart';
import 'mentor.dart';

part 'chat.freezed.dart';
part 'chat.g.dart';

@freezed
class Chat with _$Chat {
  const Chat._();

  const factory Chat({
    required String chatId,
    required String mentorId,
    required String menteeId,
    required int timestamp,
    Mentor? mentor,
  }) = _Chat;

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);

  static Chat fromMap(String id, Map<String, dynamic> data) {
    return Chat(
      chatId: id,
      mentorId: data['mentorId'] as String? ?? '',
      menteeId: data['menteeId'] as String? ?? '',
      timestamp: data['timestamp'] as int? ?? 0,
      mentor: data['mentor'] != null
          ? Mentor.fromMap(
              data['mentorId'] as String? ?? '',
              data['mentor'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'mentorId': mentorId,
    'menteeId': menteeId,
    'timestamp': timestamp,
  };
}
