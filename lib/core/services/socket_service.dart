import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import '../models/message_model.dart';

class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  Function(Message)? onMessageReceived;
  Function(String)? onUserTyping;
  Function(String)? onUserStoppedTyping;
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function()? onUnauthorized;
  Function(dynamic)? onError;

  bool get isConnected => _isConnected;

  void connect(String token, {String cookieString = ''}) {
    if (_socket != null && _isConnected) {
      debugPrint('[SOCKET] Already connected');
      return;
    }

    debugPrint('[SOCKET] Connecting to ${AppConstants.socketUrl}');
    debugPrint('[SOCKET] Using token: ${token.substring(0, 10)}...');
    if (cookieString.isNotEmpty) {
      debugPrint('[SOCKET] Using cookies for auth');
    }

    try {
      _socket = io.io(
        AppConstants.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .setExtraHeaders({
              if (cookieString.isNotEmpty) 'Cookie': cookieString,
            })
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build()
          ..['forceNew'] = true,
      );

      _setupListeners();
    } catch (e) {
      debugPrint('[SOCKET] Error creating socket: $e');
    }
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      _isConnected = true;
      debugPrint('[SOCKET] Connected successfully');
      onConnected?.call();
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[SOCKET] Disconnected');
      onDisconnected?.call();
    });

    _socket?.onConnectError((error) {
      debugPrint('[SOCKET] Connection error: $error');

      if (error.toString().toLowerCase().contains('unauthorized')) {
        debugPrint('[SOCKET] Unauthorized error detected in connect_error');
        onUnauthorized?.call();
      }

      onError?.call(error);
    });

    _socket?.onError((error) {
      debugPrint('[SOCKET] Error: $error');
      onError?.call(error);
    });

    _socket?.on('unauthorized', (_) {
      debugPrint('[SOCKET] Received unauthorized event from server');
      onUnauthorized?.call();
    });

    _socket?.on('receive_message', (data) {
      debugPrint('[SOCKET] Message received: $data');
      if (data != null) {
        try {
          final message = Message.fromJson(data as Map<String, dynamic>);
          onMessageReceived?.call(message);
        } catch (e) {
          debugPrint('[SOCKET] Error parsing message: $e');
        }
      }
    });

    _socket?.on('notification', (data) {
      debugPrint('[SOCKET] Notification received: $data');
      if (data != null && data is Map<String, dynamic>) {
        onNotificationReceived?.call(data);
      }
    });

    void handleTyping(dynamic data) {
      debugPrint('[SOCKET] User typing event: $data');
      if (data != null) {
        String? senderId;
        if (data is Map<String, dynamic>) {
          if (data['userId'] != null) {
            senderId = data['userId'].toString();
          } else if (data['senderId'] != null) {
            senderId = data['senderId'].toString();
          } else if (data['sender'] != null && data['sender'] is Map) {
            senderId =
                data['sender']['_id']?.toString() ??
                data['sender']['id']?.toString();
          }
        }
        if (senderId != null) {
          onUserTyping?.call(senderId);
        }
      }
    }

    void handleStopTyping(dynamic data) {
      debugPrint('[SOCKET] User stop typing event: $data');
      if (data != null) {
        String? senderId;
        if (data is Map<String, dynamic>) {
          if (data['userId'] != null) {
            senderId = data['userId'].toString();
          } else if (data['senderId'] != null) {
            senderId = data['senderId'].toString();
          } else if (data['sender'] != null && data['sender'] is Map) {
            senderId =
                data['sender']['_id']?.toString() ??
                data['sender']['id']?.toString();
          }
        }
        if (senderId != null) {
          onUserStoppedTyping?.call(senderId);
        }
      }
    }

    _socket?.on('typing', handleTyping);
    _socket?.on('user_typing', handleTyping);

    _socket?.on('stop_typing', handleStopTyping);
    _socket?.on('user_stop_typing', handleStopTyping);
  }

  void sendMessage({
    required String receiverId,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    if (!_isConnected) {
      debugPrint('[SOCKET] Cannot send message - not connected');
      return;
    }

    final data = {
      'receiverId': receiverId,
      'message': message,
      'type': type.value,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };

    debugPrint('[SOCKET] Sending message: $data');
    _socket?.emit('send_message', data);
  }

  void sendTyping(String receiverId) {
    if (!_isConnected) return;
    _socket?.emit('typing', {'receiverId': receiverId});
  }

  void sendStopTyping(String receiverId) {
    if (!_isConnected) return;
    _socket?.emit('stop_typing', {'receiverId': receiverId});
  }

  void disconnect() {
    debugPrint('[SOCKET] Disconnecting...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    onMessageReceived = null;
    onUserTyping = null;
    onUserStoppedTyping = null;
    onNotificationReceived = null;
    onConnected = null;
    onDisconnected = null;
    onError = null;
  }
}