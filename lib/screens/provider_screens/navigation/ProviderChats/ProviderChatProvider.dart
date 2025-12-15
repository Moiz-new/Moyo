import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_nats/dart_nats.dart';

import '../../../../NATS Service/NatsService.dart';

class UserChatProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _chatId;
  List<ChatMessage> _messages = [];
  Subscription? _chatSubscription;
  final NatsService _natsService = NatsService();

  bool get isLoading => _isLoading;

  String? get error => _error;

  String? get chatId => _chatId;

  List<ChatMessage> get messages => _messages;

  // Fetch chat history from NATS
  Future<bool> fetchChatHistory({required String chatId}) async {
    print("=== FETCHING CHAT HISTORY ===");
    print("Chat ID: $chatId");

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ensure NATS is connected
      if (!_natsService.isConnected) {
        print("NATS not connected, attempting to connect...");
        final connected = await _natsService.connect();
        if (!connected) {
          _error = 'Failed to connect to messaging service';
          _isLoading = false;
          notifyListeners();
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
        _error = 'No response from chat service';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final responseData = json.decode(responseStr);
      print("✅ Received NATS Response:");
      print(responseData);

      if (responseData['success'] == true && responseData['messages'] != null) {
        _messages.clear();

        // Parse messages from NATS response
        List<dynamic> messagesData = responseData['messages'];
        for (var msgData in messagesData) {
          try {
            final chatMessage = ChatMessage.fromJson(msgData);
            _messages.add(chatMessage);
          } catch (e) {
            print("Error parsing message: $e");
          }
        }

        // Sort messages by timestamp (oldest first)
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        print("✅ Loaded ${_messages.length} messages from history");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = responseData['message'] ?? 'Failed to fetch chat history';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      print("=== EXCEPTION in fetchChatHistory ===");
      print("Error: $e");
      print("Stack Trace: $stackTrace");
      _error = 'Failed to load chat history: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Subscribe to new messages via NATS
  Future<void> subscribeToMessages({required String chatId}) async {
    try {
      print("=== Subscribing to chat messages ===");
      print("Chat ID: $chatId");

      // Ensure NATS is connected
      if (!_natsService.isConnected) {
        print("NATS not connected, attempting to connect...");
        await _natsService.connect();
      }

      // Subscribe to new messages for this specific chat
      _chatSubscription = _natsService.subscribe('chat.message.$chatId', (
        message,
      ) {
        try {
          final msgData = json.decode(message);
          print("📨 New message received: $msgData");

          final chatMessage = ChatMessage.fromJson(msgData);

          // Check if message already exists (avoid duplicates)
          bool exists = _messages.any((m) => m.id == chatMessage.id);
          if (!exists) {
            _messages.add(chatMessage);
            // Sort to maintain chronological order
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            notifyListeners();
            print("✅ New message added to list: ${chatMessage.id}");
          } else {
            print("⚠️ Message already exists: ${chatMessage.id}");
          }
        } catch (e) {
          print("Error processing incoming message: $e");
        }
      });

      print("✅ Subscribed to chat messages");
    } catch (e) {
      print("❌ Subscription Error: $e");
    }
  }

  // Initiate chat with provider
  // Initiate chat with provider
  Future<bool> initiateChat({
    required String serviceId,
    required String providerId,
    int retryCount = 0,
  }) async {
    print("=== INITIATE CHAT STARTED (Attempt ${retryCount + 1}) ===");
    print("Service ID: $serviceId");
    print("Provider ID: $providerId");

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print("ERROR: Token not found!");
        _error = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print("Token found: ${token.substring(0, 20)}...");

      // CHANGE 1: Validate inputs before API call
      if (serviceId.isEmpty || providerId.isEmpty) {
        print("ERROR: Service ID or Provider ID is empty");
        _error = 'Invalid service or provider information';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final requestBody = {
        'service_id': int.tryParse(serviceId) ?? serviceId,
        'provider_id': int.tryParse(providerId) ?? providerId,
      };

      print("Request URL: $base_url/bid/api/chat/initiate");
      print("Request Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse('$base_url/bid/api/chat/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Server took too long to respond');
        },
      );

      print("=== API RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("Parsed Response Data: $data");

        if (data['success'] == true && data['chat'] != null) {
          final chatData = data['chat'];
          if (chatData['id'] != null) {
            _chatId = chatData['id'].toString();
          } else if (chatData['chat_id'] != null) {
            _chatId = chatData['chat_id'].toString();
          }

          print("Chat ID: $_chatId");

          if (_chatId == null || _chatId!.isEmpty) {
            print("ERROR: Chat ID is empty or null");
            _error = 'Invalid chat ID received';
            _isLoading = false;
            notifyListeners();
            return false;
          }

          bool natsConnected = false;
          try {
            if (!_natsService.isConnected) {
              print("Initializing NATS connection...");
              natsConnected = await _natsService.connect();
            } else {
              natsConnected = true;
            }
          } catch (e) {
            print("NATS connection error (non-critical): $e");
            natsConnected = false;
          }

          if (natsConnected) {
            try {
              final historySuccess = await fetchChatHistory(chatId: _chatId!);
              if (historySuccess) {
                await subscribeToMessages(chatId: _chatId!);
              }
            } catch (e) {
              print("NATS operations error (non-critical): $e");
            }
          } else {
            print("NATS not available - chat initiated without real-time updates");
          }

          print("SUCCESS: Chat initiated successfully!");
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          print("ERROR: Response success is false or chat is null");
          _error = data['message'] ?? 'Failed to initiate chat';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      // CHANGE 2: Handle 500 error with retry mechanism
      else if (response.statusCode == 500 && retryCount < 2) {
        print("⚠️ Server error 500 - Retrying after 2 seconds...");
        await Future.delayed(Duration(seconds: 2));
        return await initiateChat(
          serviceId: serviceId,
          providerId: providerId,
          retryCount: retryCount + 1,
        );
      }
      // CHANGE 3: Better error messages for different status codes
      else {
        print("ERROR: API returned error status code ${response.statusCode}");
        String errorMessage;

        switch (response.statusCode) {
          case 400:
            errorMessage = 'Invalid request - Please check service details';
            break;
          case 401:
            errorMessage = 'Session expired - Please login again';
            break;
          case 403:
            errorMessage = 'Access denied - You do not have permission';
            break;
          case 404:
            errorMessage = 'Service or provider not found';
            break;
          case 500:
            errorMessage = 'Server error - Please try again later';
            break;
          case 503:
            errorMessage = 'Service temporarily unavailable';
            break;
          default:
            errorMessage = 'Failed to initiate chat';
        }

        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          print("Could not parse error response");
        }

        _error = errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      print("=== EXCEPTION OCCURRED ===");
      print("Error: $e");
      print("Stack Trace: $stackTrace");

      // CHANGE 4: Better error messages for different exceptions
      String errorMessage;
      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout - Please check your connection';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid server response';
      } else {
        errorMessage = 'Connection error - Please try again';
      }

      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Send message
  Future<bool> sendMessage({required String message}) async {
    if (_chatId == null) {
      print("ERROR: Cannot send message, chatId is null");
      _error = 'Chat not initialized';
      notifyListeners();
      return false;
    }

    print("=== SEND MESSAGE STARTED ===");
    print("Chat ID: $_chatId");
    print("Message: $message");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print("ERROR: Token not found!");
        _error = 'Authentication token not found';
        notifyListeners();
        return false;
      }

      final requestBody = {'chat_id': _chatId, 'message': message};

      print("Request URL: $base_url/bid/api/chat/send-message");
      print("Request Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse('$base_url/bid/api/chat/send-message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print("=== SEND MESSAGE RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("Message sent successfully!");

        // Parse and add the message to local list
        try {
          if (data['message'] != null) {
            final chatMessage = ChatMessage.fromJson(data['message']);

            // Check if message already exists (avoid duplicates)
            bool exists = _messages.any((m) => m.id == chatMessage.id);
            if (!exists) {
              _messages.add(chatMessage);
              // Sort to maintain chronological order
              _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              print("Message added to local list: ${chatMessage.id}");
              notifyListeners();
            } else {
              print("⚠️ Message already exists: ${chatMessage.id}");
            }
          }
        } catch (e) {
          print("Error parsing message: $e");
          // Don't fail the whole operation if parsing fails
        }

        return true;
      } else {
        print("ERROR: Failed to send message");
        try {
          final errorData = jsonDecode(response.body);
          _error = errorData['message'] ?? 'Failed to send message';
        } catch (e) {
          _error = 'Failed to send message (Status: ${response.statusCode})';
        }
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      print("=== EXCEPTION in sendMessage ===");
      print("Error: $e");
      print("Stack Trace: $stackTrace");
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

    // Unsubscribe from NATS
    if (_chatSubscription != null && _chatId != null) {
      _natsService.unsubscribe('chat.message.$_chatId');
      _chatSubscription = null;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    // Unsubscribe from NATS
    if (_chatSubscription != null && _chatId != null) {
      _natsService.unsubscribe('chat.message.$_chatId');
    }
    super.dispose();
  }
}

// Chat message model
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
    print("=== Parsing ChatMessage ===");
    print("Raw JSON: $json");

    // Handle nested id structure
    String messageId = '';
    if (json['id'] != null) {
      if (json['id'] is Map) {
        messageId = json['id']['id']?.toString() ?? '';
      } else {
        messageId = json['id'].toString();
      }
    }
    print("Parsed ID: $messageId");

    // Handle nested message structure: {"message": {"text": "hu"}}
    String messageText = '';
    if (json['message'] != null) {
      if (json['message'] is Map) {
        messageText = json['message']['text']?.toString() ?? '';
      } else {
        messageText = json['message'].toString();
      }
    }
    print("Parsed Message: $messageText");

    // Parse other fields
    final chatId = json['chat_id']?.toString() ?? '';
    final senderId = json['sender_id']?.toString() ?? '';
    final senderType = json['sender_type']?.toString() ?? '';
    final isRead = json['is_read'] == true;

    DateTime createdAt;
    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at']);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      print("Error parsing date: $e");
      createdAt = DateTime.now();
    }

    print("Created ChatMessage successfully");

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
