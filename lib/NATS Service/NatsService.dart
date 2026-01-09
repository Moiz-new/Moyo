import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_nats/dart_nats.dart';
import 'package:flutter/material.dart';

class NatsService {
  static final NatsService _instance = NatsService._internal();

  factory NatsService() => _instance;

  NatsService._internal();

  Client? _client;
  bool _isConnected = false;
  bool _isInitialized = false;
  Timer? _reconnectTimer;

  // Configuration
  String _url = 'nats://api.moyointernational.com';
  String? _username;
  String? _password;

  // Auto-reconnect settings
  bool _autoReconnect = true;
  Duration _reconnectInterval = const Duration(seconds: 10);
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  // Connection status stream
  final _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  bool get isInitialized => _isInitialized;

  // Store subscriptions for re-subscription after reconnect
  final Map<String, Function(String)> _subscriptions = {};
  final Map<String, Subscription> _activeSubscriptions = {};

  /// Initialize NATS service with configuration
  /// Call this once in main() or in your app's entry point
  Future<void> initialize({
    String url = 'nats://api.moyointernational.com',
    String? username,
    String? password,
    bool autoReconnect = true,
    Duration reconnectInterval = const Duration(seconds: 10),
  }) async {
    if (_isInitialized) {
      debugPrint('⚠️ NATS already initialized');
      return;
    }

    _url = url;
    _username = username;
    _password = password;
    _autoReconnect = autoReconnect;
    _reconnectInterval = reconnectInterval;
    _isInitialized = true;

    debugPrint('🚀 NATS Service initialized');

    // Initial connection
    await connect();
  }

  /// Connect to NATS server
  Future<bool> connect({
    String? url,
    String? username,
    String? password,
  }) async {
    try {
      if (_isConnected) {
        debugPrint('Already connected to NATS');
        return true;
      }

      // Use provided values or stored configuration
      final connectUrl = url ?? _url;
      final connectUsername = username ?? _username;
      final connectPassword = password ?? _password;

      // Store configuration for reconnection
      _url = connectUrl;
      _username = connectUsername;
      _password = connectPassword;

      debugPrint('🔌 Connecting to NATS: $connectUrl');

      // Client instance banao
      _client = Client();

      // URL ko Uri object mein convert karo
      final uri = Uri.parse(connectUrl);

      // Connect karo
      await _client!.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);

      debugPrint('✅ NATS Connected successfully to $connectUrl');

      // Re-subscribe to all previous subscriptions
      _resubscribeAll();

      // Connection status monitor karo
      _client!.statusStream.listen((status) {
        debugPrint('NATS Status: $status');
        if (status == Status.disconnected || status == Status.closed) {
          _handleDisconnection();
        }
      });

      return true;
    } catch (e) {
      debugPrint('❌ NATS Connection Error: $e');
      _isConnected = false;
      _connectionController.add(false);

      // Schedule reconnection if auto-reconnect is enabled
      if (_autoReconnect) {
        _scheduleReconnect();
      }

      return false;
    }
  }

  /// Handle disconnection and trigger reconnection
  void _handleDisconnection() {
    _isConnected = false;
    _connectionController.add(false);
    debugPrint('🔴 NATS Disconnected');

    if (_autoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    debugPrint(
      '🔄 Scheduling reconnect attempt $_reconnectAttempts in ${_reconnectInterval.inSeconds}s',
    );

    _reconnectTimer = Timer(_reconnectInterval, () async {
      debugPrint('🔄 Attempting to reconnect...');
      await connect();
    });
  }

  /// Re-subscribe to all stored subscriptions after reconnection
  void _resubscribeAll() {
    if (_subscriptions.isEmpty) return;

    debugPrint('🔄 Re-subscribing to ${_subscriptions.length} subjects');

    _subscriptions.forEach((subject, callback) {
      _subscribeInternal(subject, callback);
    });
  }

  /// String ko Uint8List mein convert karo
  Uint8List _stringToBytes(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }

  /// Uint8List ko String mein convert karo
  String _bytesToString(Uint8List? bytes) {
    if (bytes == null) return '';
    return utf8.decode(bytes);
  }

  /// Message publish karo (fire and forget)
  void publish(String subject, String message) {
    if (!_isConnected || _client == null) {
      debugPrint('❌ Not connected to NATS');
      return;
    }

    try {
      final bytes = _stringToBytes(message);
      _client!.pub(subject, bytes);
      debugPrint('📤 Published to "$subject": $message');
    } catch (e) {
      debugPrint('❌ Publish Error: $e');
    }
  }

  /// Bytes publish karo (for binary data)
  void publishBytes(String subject, Uint8List data) {
    if (!_isConnected || _client == null) {
      debugPrint('❌ Not connected to NATS');
      return;
    }

    try {
      _client!.pub(subject, data);
      debugPrint('📤 Published bytes to "$subject"');
    } catch (e) {
      debugPrint('❌ Publish Error: $e');
    }
  }

  /// Internal subscription method
  Subscription? _subscribeInternal(String subject, Function(String) onMessage) {
    if (!_isConnected || _client == null) {
      debugPrint('❌ Not connected to NATS, subscription stored for later');
      return null;
    }

    try {
      final sub = _client!.sub(subject);

      sub.stream.listen(
        (message) {
          final messageStr = _bytesToString(message.data);
          debugPrint('📥 Received on "$subject": $messageStr');
          onMessage(messageStr);
        },
        onError: (error) {
          debugPrint('❌ Subscription Error: $error');
        },
      );

      debugPrint('👂 Subscribed to "$subject"');
      _activeSubscriptions[subject] = sub;
      return sub;
    } catch (e) {
      debugPrint('❌ Subscribe Error: $e');
      return null;
    }
  }

  /// Subject ko subscribe karo with auto-resubscription support
  Subscription? subscribe(String subject, Function(String) onMessage) {
    // Store subscription for reconnection
    _subscriptions[subject] = onMessage;

    return _subscribeInternal(subject, onMessage);
  }

  /// Unsubscribe from a subject
  void unsubscribe(String subject) {
    _subscriptions.remove(subject);
    _activeSubscriptions[subject]?.unSub();
    _activeSubscriptions.remove(subject);
    debugPrint('🚫 Unsubscribed from "$subject"');
  }

  /// Subject ko subscribe karo aur raw bytes receive karo
  Subscription? subscribeBytes(String subject, Function(Uint8List?) onMessage) {
    if (!_isConnected || _client == null) {
      debugPrint('❌ Not connected to NATS');
      return null;
    }

    try {
      final sub = _client!.sub(subject);

      sub.stream.listen(
        (message) {
          debugPrint('📥 Received bytes on "$subject"');
          onMessage(message.data);
        },
        onError: (error) {
          debugPrint('❌ Subscription Error: $error');
        },
      );

      debugPrint('👂 Subscribed to "$subject" (bytes mode)');
      return sub;
    } catch (e) {
      debugPrint('❌ Subscribe Error: $e');
      return null;
    }
  }

  /// Request-Reply pattern (synchronous communication)
  Future<String?> request(
    String subject,
    String request, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isConnected || _client == null) {
      debugPrint('❌ Not connected to NATS');
      return null;
    }

    try {
      debugPrint('📞 Requesting "$subject": $request');
      final requestBytes = _stringToBytes(request);

      final response = await _client!
          .request(subject, requestBytes)
          .timeout(timeout);

      final responseStr = _bytesToString(response?.data);
      debugPrint('📨 Response received: $responseStr');
      return responseStr;
    } catch (e) {
      debugPrint('❌ Request Error: $e');
      return null;
    }
  }

  /// Request-Reply pattern with bytes
  Future<Uint8List?> requestBytes(
    String subject,
    Uint8List request, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_isConnected || _client == null) {
      debugPrint('❌ Not connected to NATS');
      return null;
    }

    try {
      debugPrint('📞 Requesting "$subject" (bytes)');

      final response = await _client!
          .request(subject, request)
          .timeout(timeout);

      debugPrint('📨 Response received (bytes)');
      return response?.data;
    } catch (e) {
      debugPrint('❌ Request Error: $e');
      return null;
    }
  }

  /// Reply handler setup karo (server-side ke liye)
  Subscription? replyHandler(String subject, String Function(String) handler) {
    if (!_isConnected || _client == null) {
      debugPrint('❌ Not connected to NATS');
      return null;
    }

    try {
      final sub = _client!.sub(subject);

      sub.stream.listen((message) {
        try {
          final requestStr = _bytesToString(message.data);
          final responseStr = handler(requestStr);
          final responseBytes = _stringToBytes(responseStr);

          if (message.replyTo != null && message.replyTo!.isNotEmpty) {
            _client!.pub(message.replyTo!, responseBytes);
            debugPrint('💬 Replied to request on "$subject"');
          }
        } catch (e) {
          debugPrint('❌ Reply Handler Error: $e');
        }
      });

      debugPrint('🎯 Reply handler set for "$subject"');
      return sub;
    } catch (e) {
      debugPrint('❌ Reply Handler Setup Error: $e');
      return null;
    }
  }

  /// Reply handler with bytes
  Subscription? replyHandlerBytes(
    String subject,
    Uint8List Function(Uint8List?) handler,
  ) {
    if (!_isConnected || _client == null) {
      debugPrint('❌ Not connected to NATS');
      return null;
    }

    try {
      final sub = _client!.sub(subject);

      sub.stream.listen((message) {
        try {
          final responseBytes = handler(message.data);

          if (message.replyTo != null && message.replyTo!.isNotEmpty) {
            _client!.pub(message.replyTo!, responseBytes);
            debugPrint('💬 Replied to request on "$subject" (bytes)');
          }
        } catch (e) {
          debugPrint('❌ Reply Handler Error: $e');
        }
      });

      debugPrint('🎯 Reply handler set for "$subject" (bytes mode)');
      return sub;
    } catch (e) {
      debugPrint('❌ Reply Handler Setup Error: $e');
      return null;
    }
  }

  /// Manually trigger reconnection
  Future<void> reconnect() async {
    debugPrint('🔄 Manual reconnection triggered');
    _reconnectAttempts = 0;
    await disconnect();
    await connect();
  }

  /// NATS connection close karo
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();

    if (_client != null) {
      await _client!.close();
      _isConnected = false;
      _connectionController.add(false);
      debugPrint('🔌 Disconnected from NATS');
    }
  }

  /// Cleanup karo
  void dispose() {
    _reconnectTimer?.cancel();
    _subscriptions.clear();
    _activeSubscriptions.clear();
    disconnect();
    _connectionController.close();
    _isInitialized = false;
  }
}
