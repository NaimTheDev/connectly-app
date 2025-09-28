/// Message data model for representing individual messages in a chat.
class Message {
  final String messageId;
  final String message;
  final String receiverId;
  final String senderId;
  final int timestamp;

  const Message({
    required this.messageId,
    required this.message,
    required this.receiverId,
    required this.senderId,
    required this.timestamp,
  });

  /// Creates a Message from a Firestore document ID and data.
  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      messageId: id,
      message: data['message'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      timestamp: data['timestamp'] as int? ?? 0,
    );
  }

  /// Converts the Message to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'receiverId': receiverId,
      'senderId': senderId,
      'timestamp': timestamp,
    };
  }

  /// Returns a formatted timestamp for display.
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Returns true if the current user is the sender.
  bool isSentByUser(String currentUserId) => senderId == currentUserId;
}
