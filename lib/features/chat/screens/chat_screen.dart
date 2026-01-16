import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../provider/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final displayName = _getDisplayName();
      context.read<ChatProvider>().openChat(
        widget.userId,
        username: displayName,
        profilePhoto: widget.profilePhoto,
      );
    });
  }

  String _getDisplayName() {
    final fullName = '${widget.firstName ?? ''} ${widget.lastName ?? ''}'
        .trim();
    return fullName.isNotEmpty ? fullName : widget.username;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: widget.profilePhoto != null
                  ? CachedNetworkImageProvider(widget.profilePhoto!)
                  : null,
              child: widget.profilePhoto == null
                  ? Text(
                      _getDisplayName().isNotEmpty
                          ? _getDisplayName()[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayName(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, provider, _) {
                      if (provider.isOtherUserTyping) {
                        return Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.more_vert),
        //     onPressed: null, // TODO: Show options menu
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount:
                      provider.messages.length +
                      (provider.isOtherUserTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator at the bottom
                    if (index == provider.messages.length &&
                        provider.isOtherUserTyping) {
                      return const TypingIndicator();
                    }

                    final message = provider.messages[index];
                    // Determine if message is from current user
                    final isMe = message.senderId == provider.myUserId;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      showTimestamp: _shouldShowTimestamp(index, provider),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return MessageInput(
                isSending: provider.isSending,
                onSendMessage: (text) {
                  provider.sendMessage(widget.userId, text);
                },
                onSendImage: (file) {
                  provider.sendImage(widget.userId, file);
                },
                onTypingStarted: () => provider.startTyping(),
                onTypingStopped: () => provider.stopTyping(),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(int index, ChatProvider provider) {
    if (index == 0) return true;

    final current = provider.messages[index];
    final previous = provider.messages[index - 1];

    // Show timestamp if messages are more than 5 minutes apart
    return current.createdAt.difference(previous.createdAt).inMinutes > 5;
  }
}
