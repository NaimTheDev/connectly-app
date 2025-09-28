import 'mentor.dart';

/// Chat data model for representing a chat between a mentor and mentee.
class Chat {
  final String chatId;
  final String mentorId;
  final String menteeId;
  final int timestamp;
  final Mentor? mentor;

  const Chat({
    required this.chatId,
    required this.mentorId,
    required this.menteeId,
    required this.timestamp,
    this.mentor,
  });

  /// Creates a Chat from a map and document ID.
  factory Chat.fromMap(String id, Map<String, dynamic> data) {
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

  /// Converts the Chat to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {'mentorId': mentorId, 'menteeId': menteeId, 'timestamp': timestamp};
  }
}
