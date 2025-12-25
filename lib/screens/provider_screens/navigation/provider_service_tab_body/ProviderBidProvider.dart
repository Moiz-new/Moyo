import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../NATS Service/NatsService.dart';
import 'ProviderBidModel.dart';

class ProviderBidProvider extends ChangeNotifier {
  final NatsService _natsService = NatsService();

  String? _currentTopic;
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
    _connectionSubscription = _natsService.connectionStream.listen((connected) {
      _isConnected = connected;

      if (connected) {
        _error = null;
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

    _isConnected = _natsService.isConnected;
  }

  /// Remove bid from list (called when timer expires)
  void removeBid(String bidId) {
    final bidIndex = _bids.indexWhere((bid) => bid.id == bidId);
    if (bidIndex != -1) {
      final bid = _bids[bidIndex];
      _bids.removeAt(bidIndex);
      notifyListeners();
      debugPrint('🗑️ Removed bid: ${bid.title} (ID: $bidId) - Timer expired');
    }
  }

  /// Initialize subscription to provider-specific topic
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _providerId = prefs.getInt('provider_id');

      if (_providerId == null) {
        _error = 'Provider ID not found. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Wait for NATS connection
      if (!_natsService.isConnected) {
        debugPrint('⚠️ NATS not connected yet, waiting...');

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

      final data = jsonDecode(message);
      final bid = ProviderBidModel.fromJson(data);

      // Only process 'open' status bids
      if (bid.status == 'open') {
        final existingIndex = _bids.indexWhere((b) => b.id == bid.id);

        if (existingIndex != -1) {
          // Update existing bid with new receivedAt time
          _bids[existingIndex] = bid.copyWith(receivedAt: DateTime.now());
          debugPrint('🔄 Updated existing service: ${bid.title}');
        } else {
          // Add new bid with current timestamp (timer starts from now)
          final newBid = bid.copyWith(receivedAt: DateTime.now());
          _bids.insert(0, newBid); // Add at top of list
          debugPrint('✅ New service request added: ${bid.title}');
          debugPrint('⏱️ Timer will start immediately for this service');
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
      _bids[existingIndex] = bid.copyWith(receivedAt: DateTime.now());
    } else {
      _bids.insert(0, bid.copyWith(receivedAt: DateTime.now()));
    }
    notifyListeners();
    debugPrint('➕ Manually added bid: ${bid.title}');
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

    if (!_natsService.isConnected) {
      await _natsService.reconnect();
      await Future.delayed(const Duration(seconds: 10));
    }

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

  /// Refresh/reload bids
  Future<void> refresh() async {
    await Future.delayed(const Duration(seconds: 10));
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();

    if (_currentTopic != null) {
      _natsService.unsubscribe(_currentTopic!);
      debugPrint('🔕 Unsubscribed from topic: $_currentTopic');
    }

    super.dispose();
  }
}