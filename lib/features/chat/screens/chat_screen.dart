import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../provider/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

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
      final provider = context.read<ChatProvider>();
      final displayName = _getDisplayName();

      provider.openChat(
        widget.userId,
        username: displayName,
        profilePhoto: widget.profilePhoto,
      );

      // Debug socket connection
      debugPrint('[CHAT_SCREEN] Opened chat with ${widget.userId}');
      debugPrint(
        '[CHAT_SCREEN] Socket connected: ${provider.isSocketConnected}',
      );
      debugPrint('[CHAT_SCREEN] My user ID: ${provider.myUserId}');

      if (!provider.isSocketConnected) {
        debugPrint('[CHAT_SCREEN] ⚠️ WARNING: Socket is not connected!');
        debugPrint('[CHAT_SCREEN] ⚠️ WARNING: Socket is not connected!');
      }
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      // If we are near the top (pixels < 100) and scrolling up
      // Note: In a normal ListView (not reversed), top is 0.0.
      if (position.pixels < 100) {
        final provider = context.read<ChatProvider>();
        if (provider.hasMoreMessages && !provider.isLoadingMore) {
          debugPrint('[CHAT_SCREEN] 📜 Loading more messages...');
          provider.loadMoreMessages();
        }
      }
    }
  }

  String _getDisplayName() {
    final fullName = '${widget.firstName ?? ''} ${widget.lastName ?? ''}'
        .trim();
    return fullName.isNotEmpty ? fullName : widget.username;
  }

  @override
  void dispose() {
    // Reset current chat in provider so badges update correctly
    if (mounted) {
      context.read<ChatProvider>().closeChat();
    } else {
      // If not mounted (unlikely for dispose but possible if tree is being torn down),
      // we might not get context. But Provider might still be alive.
      // However, we can't access context easily if unmounted in some cases.
      // Actually, context is available in State dispose.
      context.read<ChatProvider>().closeChat();
    }
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
        title: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/profile/user',
              arguments: widget.username,
            );
          },
          child: Row(
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
                        debugPrint(
                          '[CHAT_SCREEN] Consumer rebuild. isOtherUserTyping: ${provider.isOtherUserTyping}',
                        );
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

                return Column(
                  children: [
                    if (provider.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          final message = provider.messages[index];
                          // Determine if message is from current user
                          final isMe = message.senderId == provider.myUserId;

                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            showTimestamp: _shouldShowTimestamp(
                              index,
                              provider,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
                  debugPrint('[CHAT_SCREEN] Sending text message');
                  provider.sendMessage(widget.userId, text);
                },
                onSendImages: (files) async {
                  debugPrint('[CHAT_SCREEN] Sending ${files.length} images');
                  final success = await provider.sendImages(
                    widget.userId,
                    files,
                  );
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to send some images'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
