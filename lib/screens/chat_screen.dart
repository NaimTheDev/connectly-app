import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chats/messages_providers.dart';
import '../providers/auth_providers.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../theme/theme.dart';
import '../widgets/spacers.dart';

/// Individual chat screen for viewing and sending messages
class ChatScreen extends ConsumerStatefulWidget {
  final Chat chat;
  final String otherParticipantId;
  final String? otherParticipantName;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.otherParticipantId,
    this.otherParticipantName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    final firebaseUser = ref.read(firebaseUserStreamProvider).value;
    if (firebaseUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final sendMessage = ref.read(sendMessageProvider);
      await sendMessage(
        widget.chat.chatId,
        messageText,
        firebaseUser.uid,
        widget.otherParticipantId,
      );

      _messageController.clear();

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;
    final firebaseUserAsync = ref.watch(firebaseUserStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: brand.brand.withOpacity(0.1),
              child: Icon(Icons.person, color: brand.brand, size: 20),
            ),
            Spacers.w12,
            Expanded(
              child: Text(
                widget.otherParticipantName ?? 'Chat',
                style: textTheme.titleMedium?.copyWith(
                  color: brand.ink,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: brand.softGrey,
      ),
      body: firebaseUserAsync.when(
        data: (firebaseUser) {
          if (firebaseUser == null) {
            return const Center(child: Text('Please sign in to view messages'));
          }

          final messagesAsync = ref.watch(
            messagesStreamProvider(widget.chat.chatId),
          );

          return Column(
            children: [
              // Messages list
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 64,
                              color: brand.graphite.withOpacity(0.5),
                            ),
                            Spacers.h16,
                            Text(
                              'No messages yet',
                              style: textTheme.titleMedium?.copyWith(
                                color: brand.graphite,
                              ),
                            ),
                            Spacers.h8,
                            Text(
                              'Start the conversation!',
                              style: textTheme.bodyMedium?.copyWith(
                                color: brand.graphite.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Auto-scroll to bottom when new messages arrive
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isCurrentUser =
                            message.senderId == firebaseUser.uid;

                        return _MessageBubble(
                          message: message,
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: brand.danger,
                        ),
                        Spacers.h16,
                        Text(
                          'Failed to load messages',
                          style: textTheme.bodyLarge?.copyWith(
                            color: brand.danger,
                          ),
                        ),
                        Spacers.h8,
                        Text(
                          'Please try again later',
                          style: textTheme.bodyMedium?.copyWith(
                            color: brand.graphite.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Message input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: brand.softGrey, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: brand.graphite.withOpacity(0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: brand.softGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: brand.softGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: brand.brand),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      Spacers.w12,
                      Container(
                        decoration: BoxDecoration(
                          color: brand.brand,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      brand.ink,
                                    ),
                                  ),
                                )
                              : Icon(Icons.send, color: brand.ink, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Authentication error')),
      ),
    );
  }
}

/// Individual message bubble widget
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const _MessageBubble({required this.message, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    // Format timestamp
    String timeDisplay = '';
    try {
      final messageTime = message.dateTime;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(
        messageTime.year,
        messageTime.month,
        messageTime.day,
      );

      if (messageDay == today) {
        // Today - show time
        final hour = messageTime.hour % 12 == 0 ? 12 : messageTime.hour % 12;
        final minute = messageTime.minute.toString().padLeft(2, '0');
        final amPm = messageTime.hour >= 12 ? 'PM' : 'AM';
        timeDisplay = '$hour:$minute $amPm';
      } else if (messageDay == today.subtract(const Duration(days: 1))) {
        // Yesterday
        timeDisplay = 'Yesterday';
      } else {
        // Older - show date
        timeDisplay = '${messageTime.month}/${messageTime.day}';
      }
    } catch (e) {
      timeDisplay = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: brand.brand.withOpacity(0.1),
              child: Icon(Icons.person, color: brand.brand, size: 16),
            ),
            Spacers.w8,
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? brand.brand
                    : brand.softGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isCurrentUser ? brand.ink : brand.ink,
                    ),
                  ),
                  if (timeDisplay.isNotEmpty) ...[
                    Spacers.h4,
                    Text(
                      timeDisplay,
                      style: textTheme.bodySmall?.copyWith(
                        color: isCurrentUser
                            ? brand.ink.withOpacity(0.7)
                            : brand.graphite.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            Spacers.w8,
            CircleAvatar(
              radius: 16,
              backgroundColor: brand.brand.withOpacity(0.1),
              child: Icon(Icons.person, color: brand.brand, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
