import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../NATS Service/NatsService.dart';
import 'ProviderBidModel.dart';

class ProviderBidProvider extends ChangeNotifier {
  final NatsService _natsService = NatsService();

  // Subscription is now managed by NatsService internally
  String? _currentTopic;

  // ✅ ADD THIS: Store stream subscription to prevent memory leak
  StreamSubscription<bool>? _connectionSubscription;

  List<ProviderBidModel> _bids = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;
  int? _providerId;

  List<ProviderBidModel> get bids => _bids;

  bool get isLoading => _isLoading;

  bool get isConnected => _isConnected;

  String? get error => _error;

  int? get providerId => _providerId;

  ProviderBidProvider() {
    // ✅ CHANGE THIS: Store the subscription reference
    _connectionSubscription = _natsService.connectionStream.listen((connected) {
      _isConnected = connected;

      if (connected) {
        _error = null;
        // If we have a topic and connection restored, subscription is auto-restored
        if (_currentTopic != null) {
          debugPrint(
            '✅ NATS reconnected. Subscription to $_currentTopic restored automatically',
          );
        }
      } else {
        _error = 'Connection lost. Reconnecting...';
      }

      notifyListeners();
    });

    // Set initial connection status
    _isConnected = _natsService.isConnected;
  }

  /// Initialize subscription to provider-specific topic
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get provider ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _providerId = prefs.getInt('provider_id');

      if (_providerId == null) {
        _error = 'Provider ID not found. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Wait for NATS to be connected (it's initialized in main())
      if (!_natsService.isConnected) {
        debugPrint('⚠️ NATS not connected yet, waiting...');

        // Wait up to 5 seconds for connection
        int attempts = 0;
        while (!_natsService.isConnected && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }

        if (!_natsService.isConnected) {
          _error = 'Failed to connect to NATS server';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _isConnected = true;

      // Unsubscribe from previous topic if exists
      if (_currentTopic != null) {
        _natsService.unsubscribe(_currentTopic!);
        debugPrint('🔕 Unsubscribed from previous topic: $_currentTopic');
      }

      // Subscribe to provider-specific topic
      _currentTopic = 'services.provider.$_providerId';

      // The subscribe method now handles persistence internally
      _natsService.subscribe(_currentTopic!, _handleBidNotification);

      debugPrint('✅ Successfully subscribed to: $_currentTopic');
      debugPrint('🎧 Listening for service requests...');
      _error = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Initialization error: ${e.toString()}';
      _isLoading = false;
      _isConnected = false;
      notifyListeners();
      debugPrint('❌ Initialization Error: $e');
    }
  }

  /// Handle incoming bid notifications
  void _handleBidNotification(String message) {
    try {
      debugPrint('📥 Received service request: $message');

      // Parse the JSON message
      final data = jsonDecode(message);

      // Create bid model from the data
      final bid = ProviderBidModel.fromJson(data);

      // Only add if status is 'open' (new service requests)
      if (bid.status == 'open') {
        // Add to the list (avoid duplicates)
        final existingIndex = _bids.indexWhere((b) => b.id == bid.id);
        if (existingIndex != -1) {
          _bids[existingIndex] = bid;
          debugPrint('🔄 Updated existing service: ${bid.title}');
        } else {
          _bids.insert(0, bid); // Add new bids at the top
          debugPrint('✅ New service request added: ${bid.title}');
        }

        notifyListeners();

        debugPrint('💰 Budget: ${bid.formattedBudget}');
        debugPrint('📍 Location: ${bid.location}');
        debugPrint('⏰ Schedule: ${bid.scheduleDate} at ${bid.scheduleTime}');
      } else {
        debugPrint('ℹ️ Skipped service (status: ${bid.status})');
      }
    } catch (e) {
      debugPrint('❌ Error parsing service notification: $e');
      debugPrint('📄 Raw message: $message');
      _error = 'Error processing notification: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Manually add a bid (for testing)
  void addBid(ProviderBidModel bid) {
    final existingIndex = _bids.indexWhere((b) => b.id == bid.id);
    if (existingIndex != -1) {
      _bids[existingIndex] = bid;
    } else {
      _bids.insert(0, bid);
    }
    notifyListeners();
  }

  /// Remove a bid
  void removeBid(String serviceId) {
    _bids.removeWhere((bid) => bid.id == serviceId);
    notifyListeners();
    debugPrint('🗑️ Removed service: $serviceId');
  }

  /// Clear all bids
  void clearBids() {
    _bids.clear();
    notifyListeners();
    debugPrint('🗑️ Cleared all bids');
  }

  /// Retry connection and subscription
  Future<void> retry() async {
    debugPrint('🔄 Retrying connection...');

    // If NATS is not connected, trigger manual reconnect
    if (!_natsService.isConnected) {
      await _natsService.reconnect();

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(seconds: 1));
    }

    // Re-initialize subscription
    await initialize();
  }

  /// Get bid by ID
  ProviderBidModel? getBidById(String id) {
    try {
      return _bids.firstWhere((bid) => bid.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh/reload bids (useful for pull-to-refresh)
  Future<void> refresh() async {
    // You can add API call here to fetch initial bids if needed
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }

  @override
  void dispose() {
    // ✅ ADD THIS: Cancel stream subscription to prevent memory leak
    _connectionSubscription?.cancel();

    // Unsubscribe from the topic using NatsService method
    if (_currentTopic != null) {
      _natsService.unsubscribe(_currentTopic!);
      debugPrint('🔕 Unsubscribed from topic: $_currentTopic');
    }

    // Don't disconnect NATS here as it's shared across the app
    super.dispose();
  }
}
