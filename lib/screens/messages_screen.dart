import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/chats/chats_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/mentors_providers.dart';
import '../models/mentor.dart';
import '../theme/theme.dart';
import '../widgets/spacers.dart';
import '../routing/app_router.dart';

/// Screen displaying user's chat conversations
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUserAsync = ref.watch(firebaseUserStreamProvider);
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: textTheme.headlineSmall?.copyWith(
            color: brand.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: firebaseUserAsync.when(
          data: (firebaseUser) {
            if (firebaseUser == null) {
              return Center(
                child: Text(
                  'Please sign in to view your messages',
                  style: textTheme.bodyLarge?.copyWith(color: brand.graphite),
                ),
              );
            }

            final deleteChat = ref.read(deleteChatProvider);
            final chatsAsync = ref.watch(chatsStreamProvider(firebaseUser.uid));

            return chatsAsync.when(
              data: (chatsWithMessages) {
                if (chatsWithMessages.isEmpty) {
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
                          'No conversations yet',
                          style: textTheme.headlineSmall?.copyWith(
                            color: brand.graphite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacers.h8,
                        Text(
                          'Start a conversation with a mentor',
                          style: textTheme.bodyMedium?.copyWith(
                            color: brand.graphite.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SlidableAutoCloseBehavior(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatsWithMessages.length,
                    separatorBuilder: (context, index) => Spacers.h8,
                    itemBuilder: (context, index) {
                      final chatWithMessage = chatsWithMessages[index];
                      return _ChatListItem(
                        chatWithMessage: chatWithMessage,
                        currentUserId: firebaseUser.uid,
                        onDeleteChat: deleteChat,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: brand.danger),
                    Spacers.h16,
                    Text(
                      'Failed to load messages',
                      style: textTheme.bodyLarge?.copyWith(color: brand.danger),
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
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              'Authentication error',
              style: textTheme.bodyLarge?.copyWith(color: brand.danger),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual chat list item widget
class _ChatListItem extends ConsumerWidget {
  final ChatWithLatestMessage chatWithMessage;
  final String currentUserId;
  final DeleteChatCallback onDeleteChat;

  const _ChatListItem({
    required this.chatWithMessage,
    required this.currentUserId,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = Theme.of(context).extension<AppBrand>()!;
    final textTheme = Theme.of(context).textTheme;
    final chat = chatWithMessage.chat;
    final latestMessage = chatWithMessage.latestMessage;

    // Determine the other participant (mentor or mentee)
    final otherUserId = chat.mentorId == currentUserId
        ? chat.menteeId
        : chat.mentorId;

    // Get mentor info if available
    final mentorsAsync = ref.watch(mentorsProvider);
    Mentor? otherParticipant;

    mentorsAsync.whenData((mentors) {
      otherParticipant = mentors.firstWhere(
        (mentor) => mentor.id == otherUserId,
        orElse: () => Mentor(
          id: otherUserId,
          name: 'Unknown User',
          expertise: '',
          bio: '',
          imageUrl: null,
        ),
      );
    });

    // Format timestamp
    String timeDisplay = '';
    if (latestMessage != null) {
      final messageTime = latestMessage.dateTime;
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
      } else if (messageDay.isAfter(today.subtract(const Duration(days: 7)))) {
        // This week - show day name
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        timeDisplay = weekdays[messageTime.weekday - 1];
      } else {
        // Older - show date
        timeDisplay =
            '${messageTime.month}/${messageTime.day}/${messageTime.year}';
      }
    }

    // Truncate message preview
    String messagePreview = '';
    if (latestMessage != null) {
      messagePreview = latestMessage.message.length > 50
          ? '${latestMessage.message.substring(0, 50)}...'
          : latestMessage.message;
    }

    return Slidable(
      key: ValueKey(chat.chatId),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (actionContext) async {
              final confirmed =
                  await showDialog<bool>(
                    context: actionContext,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete Chat'),
                      content: const Text(
                        'Are you sure you want to delete this chat? '
                        'This will remove the chat and all messages.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: brand.danger,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (!confirmed) {
                if (!actionContext.mounted) return;
                Slidable.of(actionContext)?.close();
                return;
              }

              try {
                await onDeleteChat(chat.chatId);
                if (!actionContext.mounted) return;
                ScaffoldMessenger.of(actionContext).showSnackBar(
                  SnackBar(
                    content: const Text('Chat deleted'),
                    backgroundColor: brand.danger,
                  ),
                );
              } catch (error) {
                if (!actionContext.mounted) return;
                ScaffoldMessenger.of(actionContext).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete chat: $error'),
                    backgroundColor: brand.danger,
                  ),
                );
              }
            },
            backgroundColor: brand.danger,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: brand.softGrey, width: 1),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to individual chat screen
            Navigator.of(context).pushNamed(
              AppRouter.chat,
              arguments: ChatScreenArguments(
                chat: chat,
                otherParticipantId: otherUserId,
                otherParticipantName: otherParticipant?.name,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: brand.brand.withOpacity(0.1),
                  backgroundImage: otherParticipant?.imageUrl != null
                      ? NetworkImage(otherParticipant!.imageUrl!)
                      : null,
                  child: otherParticipant?.imageUrl == null
                      ? Icon(Icons.person, color: brand.brand, size: 24)
                      : null,
                ),
                Spacers.w12,

                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and timestamp row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              otherParticipant?.name ?? 'Unknown User',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: brand.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeDisplay.isNotEmpty) ...[
                            Spacers.w8,
                            Text(
                              timeDisplay,
                              style: textTheme.bodySmall?.copyWith(
                                color: brand.graphite.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (messagePreview.isNotEmpty) ...[
                        Spacers.h4,
                        Row(
                          children: [
                            // Show "You:" if current user sent the message
                            if (latestMessage?.senderId == currentUserId)
                              Text(
                                'You: ',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: brand.graphite.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                messagePreview,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: brand.graphite.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Spacers.h4,
                        Text(
                          'No messages yet',
                          style: textTheme.bodyMedium?.copyWith(
                            color: brand.graphite.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  color: brand.graphite.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
