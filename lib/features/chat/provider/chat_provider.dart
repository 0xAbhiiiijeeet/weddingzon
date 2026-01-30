import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/socket_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../repository/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final SocketService _socketService;
  final AuthRepository _authRepository;

  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  Conversation? _currentChat;
  String? _currentChatUserId;
  String? _myUserId;
  bool _isLoading = false;
  bool _isSending = false;
  final Set<String> _typingUsers = {};
  Timer? _typingTimer;
  bool _isTyping = false;

  ChatProvider(
    this._chatRepository,
    this._socketService,
    this._authRepository,
  ) {
    _setupSocketListeners();
  }

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  Conversation? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isOtherUserTyping => _typingUsers.contains(_currentChatUserId);
  Set<String> get typingUsers => _typingUsers;
  bool get isSocketConnected => _socketService.isConnected;
  String? get myUserId => _myUserId;

  int _chatPage = 1;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  static const int _limit = 20;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreMessages => _hasMoreMessages;

  void _setupSocketListeners() {
    _socketService.onMessageReceived = _handleIncomingMessage;
    _socketService.onUserTyping = _handleUserTyping;
    _socketService.onUserStoppedTyping = _handleUserStoppedTyping;
    _socketService.onUnauthorized =
        _handleSocketUnauthorized;
  }

  Future<void> _handleSocketUnauthorized() async {
    debugPrint('[CHAT] Socket unauthorized! Attempting token refresh...');

    disconnectSocket();

    final newToken = await _authRepository.refreshToken();

    if (newToken != null && newToken.isNotEmpty) {
      debugPrint('[CHAT] Token refreshed, reconnecting socket...');
      connectSocket(newToken);
    } else {
      debugPrint(
        '[CHAT] Failed to refresh token, socket remains disconnected.',
      );
    }
  }

  void setCurrentUserId(String userId) {
    if (_myUserId != userId) {
      debugPrint(
        '[CHAT] User changed from $_myUserId to $userId - Clearing state',
      );
      _conversations = [];
      _messages = [];
      _currentChat = null;
      _currentChatUserId = null;
      _typingUsers.clear();
      _isTyping = false;
      _typingTimer?.cancel();
    }
    _myUserId = userId;
    debugPrint('[CHAT] Current user ID set to: $userId');
  }

  void connectSocket(String token, {String cookieString = ''}) {
    debugPrint('[CHAT] Connecting socket with token...');
    _socketService.connect(token, cookieString: cookieString);
  }

  void disconnectSocket() {
    _socketService.disconnect();
  }


  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    final response = await _chatRepository.getConversations();

    if (response.success && response.data != null) {
      _conversations = response.data!;
    }

    _isLoading = false;
    notifyListeners();
  }

  void _updateConversationWithMessage(Message message) {
    final otherUserId = message.senderId == _myUserId
        ? message.receiverId
        : message.senderId;

    final index = _conversations.indexWhere((c) => c.userId == otherUserId);

    final isCurrentChat = _currentChat?.userId == otherUserId;

    debugPrint('[CHAT] Updating conversation for user: $otherUserId');
    debugPrint('[CHAT] Current chat userId: ${_currentChat?.userId}');
    debugPrint('[CHAT] Is current chat: $isCurrentChat');

    if (index != -1) {
      final existing = _conversations[index];
      final newUnreadCount = isCurrentChat ? 0 : existing.unreadCount + 1;

      debugPrint(
        '[CHAT] Existing unread: ${existing.unreadCount}, New unread: $newUnreadCount',
      );

      _conversations[index] = Conversation(
        userId: existing.userId,
        username: existing.username,
        firstName: existing.firstName,
        lastName: existing.lastName,
        profilePhoto: existing.profilePhoto,
        lastMessage: message.message,
        unreadCount: newUnreadCount,
        updatedAt: message.createdAt,
      );

      if (index > 0) {
        final updated = _conversations.removeAt(index);
        _conversations.insert(0, updated);
      }
    } else {
      debugPrint('[CHAT] New conversation created from incoming message');
      _conversations.insert(
        0,
        Conversation(
          userId: otherUserId,
          username: 'User',
          firstName: '',
          lastName: '',
          profilePhoto: null,
          lastMessage: message.message,
          unreadCount: isCurrentChat
              ? 0
              : 1,
          updatedAt: message.createdAt,
        ),
      );
    }

    notifyListeners();
    debugPrint('[CHAT] Total unread count: $totalUnreadCount');
  }


  Future<void> openChat(
    String chatWithUserId, {
    String? username,
    String? profilePhoto,
  }) async {
    _currentChatUserId = chatWithUserId;
    _messages = [];
    _isLoading = true;
    notifyListeners();

    final existingConversation = _conversations
        .where((c) => c.userId == chatWithUserId)
        .firstOrNull;
    _currentChat =
        existingConversation ??
        Conversation(
          userId: chatWithUserId,
          username: username ?? 'User',
          profilePhoto: profilePhoto,
        );

    _chatPage = 1;
    _hasMoreMessages = true;
    _isLoadingMore = false;

    final response = await _chatRepository.getChatHistory(
      chatWithUserId,
      page: _chatPage,
      limit: _limit,
    );

    if (response.success && response.data != null) {
      _messages = response.data!;
      if (response.data!.length < _limit) {
        _hasMoreMessages = false;
      }
    }

    await markAsRead(chatWithUserId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreMessages() async {
    if (_currentChatUserId == null || !_hasMoreMessages || _isLoadingMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _chatPage + 1;
    final response = await _chatRepository.getChatHistory(
      _currentChatUserId!,
      page: nextPage,
      limit: _limit,
    );

    if (response.success && response.data != null) {
      final newMessages = response.data!;

      if (newMessages.isNotEmpty) {
        final uniqueMessages = newMessages
            .where(
              (newMsg) =>
                  !_messages.any((existing) => existing.id == newMsg.id),
            )
            .toList();

        _messages.insertAll(0, uniqueMessages);
        _chatPage = nextPage;

        if (newMessages.length < _limit) {
          _hasMoreMessages = false;
        }
      } else {
        _hasMoreMessages = false;
      }
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  void closeChat() {
    _currentChat = null;
    _currentChatUserId = null;
    _messages = [];
    _typingTimer?.cancel();

    notifyListeners();

    debugPrint('[CHAT] Chat closed, badge should update');
  }


  void sendMessage(
    String receiverId,
    String message, {
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    debugPrint(
      '[CHAT] sendMessage called: receiverId=$receiverId, message="$message", type=${type.value}, mediaUrl=$mediaUrl',
    );

    if (type == MessageType.text) {
      if (message.trim().isEmpty) {
        debugPrint('[CHAT] Text message is empty, ignoring');
        return;
      }
    } else if (type == MessageType.image) {
      if (mediaUrl == null || mediaUrl.isEmpty) {
        debugPrint('[CHAT] Image message missing mediaUrl, ignoring');
        return;
      }
    }

    final newMessage = Message(
      senderId: _myUserId ?? 'unknown',
      receiverId: receiverId,
      message: message,
      type: type,
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
    );

    _messages.add(newMessage);
    _updateConversationWithMessage(newMessage);
    debugPrint(
      '[CHAT] Message added locally: ${_messages.length} total messages',
    );
    notifyListeners();

    if (_socketService.isConnected) {
      debugPrint('[CHAT] Socket connected, sending message via socket...');
      _socketService.sendMessage(
        receiverId: receiverId,
        message: message,
        type: type,
        mediaUrl: mediaUrl,
      );
      debugPrint('[CHAT] Message sent via socket');
    } else {
      debugPrint(
        '[CHAT] WARNING: Socket not connected! Message added locally but NOT sent to server.',
      );
    }

    stopTyping();
  }

  Future<bool> sendImages(String receiverId, List<File> files) async {
    if (files.isEmpty) return false;

    _isSending = true;
    notifyListeners();

    int successCount = 0;

    await Future.wait(
      files.map((file) async {
        final success = await _uploadAndSendImage(receiverId, file);
        if (success) successCount++;
      }),
    );

    _isSending = false;
    notifyListeners();

    return successCount == files.length;
  }

  Future<bool> sendImage(String receiverId, File file) async {
    _isSending = true;
    notifyListeners();

    final success = await _uploadAndSendImage(receiverId, file);

    _isSending = false;
    notifyListeners();
    return success;
  }

  Future<bool> _uploadAndSendImage(String receiverId, File file) async {
    try {
      debugPrint('[CHAT] Starting image upload...');
      final response = await _chatRepository.uploadChatImage(file);

      if (response.success && response.data != null) {
        debugPrint('[CHAT] Image uploaded successfully: ${response.data}');

        final newMessage = Message(
          senderId: _myUserId ?? 'unknown',
          receiverId: receiverId,
          message: '',
          type: MessageType.image,
          mediaUrl: response.data,
          createdAt: DateTime.now(),
        );

        _messages.add(newMessage);
        _updateConversationWithMessage(newMessage);

        if (_socketService.isConnected) {
          debugPrint('[CHAT] Sending image message via socket...');
          _socketService.sendMessage(
            receiverId: receiverId,
            message: '',
            type: MessageType.image,
            mediaUrl: response.data,
          );
          debugPrint('[CHAT] Image message sent via socket');
        } else {
          debugPrint('[CHAT] WARNING: Socket not connected!');
        }

        return true;
      } else {
        debugPrint('[CHAT] Image upload failed: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('[CHAT] Error sending image: $e');
      return false;
    }
  }

  void _handleIncomingMessage(Message message) {
    debugPrint('[CHAT] Incoming message from ${message.senderId}');

    if (message.senderId == _myUserId) {
      final index = _messages.lastIndexWhere(
        (m) =>
            m.id == null &&
            m.message == message.message &&
            m.type == message.type &&
            m.createdAt.difference(message.createdAt).inSeconds.abs() < 5,
      );

      if (index != -1) {
        debugPrint(
          '[CHAT] Deduplicated own message. Updating ID: ${message.id}',
        );
        _messages[index] = message;
        notifyListeners();
        _updateConversationWithMessage(message);
        return;
      }
    }

    if (_currentChatUserId == message.senderId ||
        _currentChatUserId == message.receiverId) {
      if (message.id != null && _messages.any((m) => m.id == message.id)) {
        debugPrint(
          '[CHAT] Duplicate message ID ${message.id} received, ignoring',
        );
        return;
      }

      _messages.add(message);

      if (_currentChat != null && message.senderId == _currentChatUserId) {
        markAsRead(message.senderId);
      }
    }

    _updateConversationWithMessage(message);

    _typingUsers.remove(message.senderId);

    notifyListeners();
  }


  void startTyping() {
    if (_currentChatUserId == null || _isTyping) return;

    _isTyping = true;
    _socketService.sendTyping(_currentChatUserId!);

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), stopTyping);
  }

  void stopTyping() {
    if (_currentChatUserId == null || !_isTyping) return;

    _isTyping = false;
    _typingTimer?.cancel();
    _socketService.sendStopTyping(_currentChatUserId!);
  }

  void _handleUserTyping(String userId) {
    _typingUsers.add(userId.trim());
    notifyListeners();
  }

  void _handleUserStoppedTyping(String userId) {
    _typingUsers.remove(userId.trim());
    notifyListeners();
  }


  Future<void> markAsRead(String senderId) async {
    final response = await _chatRepository.markAsRead(senderId);

    if (response.success) {
      final index = _conversations.indexWhere((c) => c.userId == senderId);
      if (index != -1) {
        final existing = _conversations[index];
        _conversations[index] = Conversation(
          userId: existing.userId,
          username: existing.username,
          firstName: existing.firstName,
          lastName: existing.lastName,
          profilePhoto: existing.profilePhoto,
          lastMessage: existing.lastMessage,
          unreadCount: 0,
          updatedAt: existing.updatedAt,
        );
        notifyListeners();
      }
    }
  }


  int get totalUnreadCount {
    return _conversations.fold(0, (sum, item) => sum + item.unreadCount);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _socketService.dispose();
    super.dispose();
  }
}