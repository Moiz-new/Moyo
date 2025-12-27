import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_nats/dart_nats.dart';

import '../../../../NATS Service/NatsService.dart';

class ProviderChatProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _chatId;
  List<ChatMessage> _messages = [];
  Subscription? _chatSubscription;
  final NatsService _natsService = NatsService();

  // ✅ Track if currently active on chat screen
  bool _isScreenActive = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get chatId => _chatId;
  List<ChatMessage> get messages => _messages;

  // ✅ Call this when user enters chat screen
  void setScreenActive(bool isActive) {
    _isScreenActive = isActive;
    if (!isActive) {
      print("📴 Chat screen inactive - stopping real-time updates");
    } else {
      print("📱 Chat screen active - real-time updates enabled");
    }
  }

  // ✅ Modified fetchChatHistory to support silent mode (no loading indicator)
  Future<bool> fetchChatHistory({required String chatId, bool silent = false}) async {
    print("=== FETCHING CHAT HISTORY ${silent ? '(SILENT)' : ''} ===");
    print("Chat ID: $chatId");

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      if (!_natsService.isConnected) {
        print("NATS not connected, attempting to connect...");
        final connected = await _natsService.connect();
        if (!connected) {
          _error = 'Failed to connect to messaging service';
          if (!silent) {
            _isLoading = false;
            notifyListeners();
          }
          return false;
        }
      }

      final requestPayload = {'chat_id': int.parse(chatId)};
      print("📩 Sending NATS request: $requestPayload");

      final responseStr = await _natsService.request(
        'chat.history.request',
        json.encode(requestPayload),
        timeout: Duration(seconds: 5),
      );

      if (responseStr == null) {
        if (!silent) {
          _error = 'No response from chat service';
          _isLoading = false;
          notifyListeners();
        }
        return false;
      }

      final responseData = json.decode(responseStr);
      print("✅ Received NATS Response: ${responseData['success']}");

      if (responseData['success'] == true && responseData['data'] != null) {
        List<dynamic> messagesData = responseData['data'];

        // ✅ Track existing message IDs
        Set<String> existingIds = _messages.map((m) => m.id).toSet();
        bool hasNewMessages = false;

        for (var msgData in messagesData) {
          try {
            final chatMessage = ChatMessage.fromJson(msgData);
            if (!existingIds.contains(chatMessage.id)) {
              _messages.add(chatMessage);
              hasNewMessages = true;
            } else {
              // ✅ Update existing message (e.g., read status)
              int index = _messages.indexWhere((m) => m.id == chatMessage.id);
              if (index != -1) {
                _messages[index] = chatMessage;
              }
            }
          } catch (e) {
            print("Error parsing message: $e");
          }
        }

        _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (hasNewMessages || !silent) {
          print("✅ Loaded ${_messages.length} messages (${hasNewMessages ? 'NEW DATA' : 'NO CHANGES'})");
        }

        if (!silent) {
          _isLoading = false;
        }

        // ✅ Only notify listeners if there are changes or it's not a silent fetch
        if (hasNewMessages || !silent) {
          notifyListeners();
        }

        return true;
      } else {
        if (!silent) {
          _error = responseData['message'] ?? 'Failed to fetch chat history';
          _isLoading = false;
          notifyListeners();
        }
        return false;
      }
    } catch (e, stackTrace) {
      print("Error in fetchChatHistory: $e");
      if (!silent) {
        print("Stack: $stackTrace");
        _error = 'Failed to load chat history: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  Future<void> subscribeToMessages({required String chatId}) async {
    try {
      print("=== Subscribing to chat messages ===");
      if (!_natsService.isConnected) {
        await _natsService.connect();
      }

      _chatSubscription = _natsService.subscribe('chat.message.$chatId', (message) {
        // ✅ Only process if screen is active
        if (!_isScreenActive) {
          print("⏸️ Message received but screen inactive, skipping UI update");
          return;
        }

        try {
          final msgData = json.decode(message);
          print("📨 New message: $msgData");

          final chatMessage = ChatMessage.fromJson(msgData);
          bool exists = _messages.any((m) => m.id == chatMessage.id);
          if (!exists) {
            _messages.add(chatMessage);
            _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            notifyListeners();
            print("✅ New message added (sorted newest first)");
          }
        } catch (e) {
          print("Error processing message: $e");
        }
      });
      print("✅ Subscribed successfully");
    } catch (e) {
      print("Subscription error: $e");
    }
  }

  Future<bool> initiateChat({required String serviceId, required String providerId, int retryCount = 0}) async {
    print("=== INITIATE CHAT (Attempt ${retryCount + 1}) ===");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');
      if (token == null) {
        _error = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final requestBody = {
        'service_id': int.tryParse(serviceId) ?? serviceId,
        'user_id': int.tryParse(providerId) ?? providerId,
      };

      final response = await http.post(
        Uri.parse('$base_url/bid/api/chat/provider/initiate'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 10));

      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['chat'] != null) {
          final chatData = data['chat'];
          _chatId = chatData['id']?.toString() ?? chatData['chat_id']?.toString();

          if (_chatId != null && _chatId!.isNotEmpty) {
            bool natsConnected = false;
            try {
              if (!_natsService.isConnected) {
                natsConnected = await _natsService.connect();
              } else {
                natsConnected = true;
              }
            } catch (e) {
              print("NATS error: $e");
            }

            if (natsConnected) {
              final historySuccess = await fetchChatHistory(chatId: _chatId!);
              if (historySuccess) {
                await subscribeToMessages(chatId: _chatId!);
              }
            }
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
        _error = data['message'] ?? 'Failed to initiate chat';
      } else {
        _error = 'Server error (${response.statusCode})';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print("Exception in initiateChat: $e");
      _error = 'Connection error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMessage({required String message}) async {
    if (_chatId == null) {
      _error = 'Chat not initialized';
      notifyListeners();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');
      if (token == null) {
        _error = 'Authentication token not found';
        notifyListeners();
        return false;
      }

      final requestBody = {'chat_id': _chatId, 'message': message};
      final response = await http.post(
        Uri.parse('$base_url/bid/api/chat/provider/send-message'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody),
      );

      print("Send message status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          final chatMessage = ChatMessage.fromJson(data['message']);
          bool exists = _messages.any((m) => m.id == chatMessage.id);
          if (!exists) {
            _messages.add(chatMessage);
            _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            notifyListeners();
          }
        }
        return true;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _error = errorData['message'] ?? 'Failed to send message';
        } catch (e) {
          _error = 'Failed to send message (${response.statusCode})';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("Error sending message: $e");
      _error = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _error = null;
    _chatId = null;
    _messages = [];
    _isScreenActive = false;
    if (_chatSubscription != null && _chatId != null) {
      _natsService.unsubscribe('chat.message.$_chatId');
      _chatSubscription = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_chatSubscription != null && _chatId != null) {
      _natsService.unsubscribe('chat.message.$_chatId');
    }
    super.dispose();
  }
}

class ChatMessage {
  final String id;
  final String message;
  final String chatId;
  final String senderId;
  final String senderType;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.message,
    required this.chatId,
    required this.senderId,
    required this.senderType,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String messageId = json['id']?.toString() ?? '';
    if (json['id'] is Map) {
      messageId = json['id']['id']?.toString() ?? '';
    }

    String messageText = '';
    if (json['message'] is Map) {
      messageText = json['message']['text']?.toString() ?? '';
    } else {
      messageText = json['message']?.toString() ?? '';
    }

    final chatId = json['chat_id']?.toString() ?? '';
    final senderId = json['sender_id']?.toString() ?? '';
    final senderType = json['sender_type']?.toString().toLowerCase() ?? '';
    final isRead = json['is_read'] == true || json['is_read'] == 1;

    DateTime createdAt;
    try {
      createdAt = json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }

    return ChatMessage(
      id: messageId,
      message: messageText,
      chatId: chatId,
      senderId: senderId,
      senderType: senderType,
      isRead: isRead,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_type': senderType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}