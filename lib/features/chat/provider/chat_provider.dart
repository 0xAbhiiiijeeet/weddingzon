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
  final AuthRepository _authRepository; // Add dependency

  // State
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  Conversation? _currentChat;
  String? _currentChatUserId; // The user we're chatting WITH
  String? _myUserId; // Current logged-in user ID
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

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  Conversation? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isOtherUserTyping => _typingUsers.contains(_currentChatUserId);
  Set<String> get typingUsers => _typingUsers;
  bool get isSocketConnected => _socketService.isConnected;
  String? get myUserId => _myUserId;

  void _setupSocketListeners() {
    _socketService.onMessageReceived = _handleIncomingMessage;
    _socketService.onUserTyping = _handleUserTyping;
    _socketService.onUserStoppedTyping = _handleUserStoppedTyping;
    _socketService.onUnauthorized =
        _handleSocketUnauthorized; // Register listener
  }

  Future<void> _handleSocketUnauthorized() async {
    debugPrint('[CHAT] Socket unauthorized! Attempting token refresh...');

    // 1. Disconnect current socket
    disconnectSocket();

    // 2. Refresh token (AuthRepository handles concurrency)
    final newToken = await _authRepository.refreshToken();

    if (newToken != null && newToken.isNotEmpty) {
      debugPrint('[CHAT] Token refreshed, reconnecting socket...');
      // 3. Reconnect with new token
      connectSocket(newToken);
    } else {
      debugPrint(
        '[CHAT] Failed to refresh token, socket remains disconnected.',
      );
      // Optionally notify user or logout if critical
    }
  }

  /// Set the current logged-in user ID - call this after auth
  void setCurrentUserId(String userId) {
    _myUserId = userId;
    debugPrint('[CHAT] Current user ID set to: $userId');
  }

  /// Connect to socket with auth token
  void connectSocket(String token, {String cookieString = ''}) {
    debugPrint('[CHAT] Connecting socket with token...');
    _socketService.connect(token, cookieString: cookieString);
  }

  /// Disconnect socket
  void disconnectSocket() {
    _socketService.disconnect();
  }

  // =====================================================
  // CONVERSATIONS
  // =====================================================

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

  /// Update conversation with new message (for list view)
  void _updateConversationWithMessage(Message message) {
    final otherUserId = message.senderId == _myUserId
        ? message.receiverId
        : message.senderId;

    final index = _conversations.indexWhere((c) => c.userId == otherUserId);

    if (index != -1) {
      final existing = _conversations[index];
      _conversations[index] = Conversation(
        userId: existing.userId,
        username: existing.username,
        firstName: existing.firstName,
        lastName: existing.lastName,
        profilePhoto: existing.profilePhoto,
        lastMessage: message.message,
        unreadCount: _currentChat?.userId == otherUserId
            ? 0
            : existing.unreadCount + 1,
        updatedAt: message.createdAt,
      );

      // Move to top of list
      if (index > 0) {
        final updated = _conversations.removeAt(index);
        _conversations.insert(0, updated);
      }

      notifyListeners();
    }
  }

  // =====================================================
  // CHAT
  // =====================================================

  Future<void> openChat(
    String chatWithUserId, {
    String? username,
    String? profilePhoto,
  }) async {
    _currentChatUserId = chatWithUserId;
    _messages = [];
    _isLoading = true;
    notifyListeners();

    // Set current chat
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

    // Load chat history
    final response = await _chatRepository.getChatHistory(chatWithUserId);

    if (response.success && response.data != null) {
      _messages = response.data!;
    }

    // Mark as read
    await markAsRead(chatWithUserId);

    _isLoading = false;
    notifyListeners();
  }

  void closeChat() {
    _currentChat = null;
    _currentChatUserId = null;
    _messages = [];
    _typingTimer?.cancel();
    notifyListeners();
  }

  // =====================================================
  // MESSAGING
  // =====================================================

  void sendMessage(
    String receiverId,
    String message, {
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    debugPrint(
      '[CHAT] sendMessage called: receiverId=$receiverId, message="$message", type=${type.value}, mediaUrl=$mediaUrl',
    );

    // Validation based on message type
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

    // Add to local state immediately (optimistic update)
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

    // Send via socket if connected
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

    // Stop typing indicator
    stopTyping();
  }

  Future<bool> sendImage(String receiverId, File file) async {
    _isSending = true;
    notifyListeners();

    try {
      debugPrint('[CHAT] Starting image upload...');
      final response = await _chatRepository.uploadChatImage(file);

      if (response.success && response.data != null) {
        debugPrint('[CHAT] Image uploaded successfully: ${response.data}');

        // Don't call sendMessage, handle it directly here
        final newMessage = Message(
          senderId: _myUserId ?? 'unknown',
          receiverId: receiverId,
          message: '', // Empty for images
          type: MessageType.image,
          mediaUrl: response.data,
          createdAt: DateTime.now(),
        );

        // Add to local state
        _messages.add(newMessage);
        _updateConversationWithMessage(newMessage);

        // Send via socket
        if (_socketService.isConnected) {
          debugPrint('[CHAT] Sending image message via socket...');
          _socketService.sendMessage(
            receiverId: receiverId,
            message: '', // Empty message for images
            type: MessageType.image,
            mediaUrl: response.data,
          );
          debugPrint('[CHAT] Image message sent via socket');
        } else {
          debugPrint('[CHAT] WARNING: Socket not connected!');
        }

        _isSending = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('[CHAT] Image upload failed: ${response.message}');
        _isSending = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[CHAT] Error sending image: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  void _handleIncomingMessage(Message message) {
    debugPrint('[CHAT] Incoming message from ${message.senderId}');

    // Add to messages if in current chat
    if (_currentChatUserId == message.senderId ||
        _currentChatUserId == message.receiverId) {
      _messages.add(message);

      // Mark as read if current chat
      if (_currentChat != null && message.senderId == _currentChatUserId) {
        markAsRead(message.senderId);
      }
    }

    // Update conversation list
    _updateConversationWithMessage(message);

    // Remove typing indicator for this user
    _typingUsers.remove(message.senderId);

    notifyListeners();
  }

  // =====================================================
  // TYPING INDICATORS
  // =====================================================

  void startTyping() {
    if (_currentChatUserId == null || _isTyping) return;

    _isTyping = true;
    _socketService.sendTyping(_currentChatUserId!);

    // Auto-stop typing after 3 seconds of no input
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
    _typingUsers.add(userId);
    notifyListeners();
  }

  void _handleUserStoppedTyping(String userId) {
    _typingUsers.remove(userId);
    notifyListeners();
  }

  // =====================================================
  // MARK AS READ
  // =====================================================

  Future<void> markAsRead(String senderId) async {
    final response = await _chatRepository.markAsRead(senderId);

    if (response.success) {
      // Update conversation unread count
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

  // =====================================================
  // CLEANUP
  // =====================================================

  @override
  void dispose() {
    _typingTimer?.cancel();
    _socketService.dispose();
    super.dispose();
  }
}
