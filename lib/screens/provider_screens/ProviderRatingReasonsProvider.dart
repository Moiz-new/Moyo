import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Model for Rating Reason
class RatingReason {
  final int id;
  final String reason;

  RatingReason({
    required this.id,
    required this.reason,
  });

  factory RatingReason.fromJson(Map<String, dynamic> json) {
    return RatingReason(
      id: json['id'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

// Provider for Rating Reasons
class ProviderRatingReasonsProvider extends ChangeNotifier {
  List<RatingReason> _reasons = [];
  bool _isLoading = false;
  String? _error;

  // Separate reasons by rating level
  Map<int, List<RatingReason>> _reasonsByRating = {};

  List<RatingReason> get reasons => _reasons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get reasons for specific rating
  List<RatingReason> getReasonsForRating(int rating) {
    return _reasonsByRating[rating] ?? [];
  }

  // Fetch reasons for a specific rating
  Future<void> fetchRatingReasons(int rating) async {
    // Return cached data if available
    if (_reasonsByRating.containsKey(rating) &&
        _reasonsByRating[rating]!.isNotEmpty) {
      _reasons = _reasonsByRating[rating]!;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.moyointernational.com/api/rating/public/$rating'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _reasons = data.map((json) => RatingReason.fromJson(json)).toList();

        // Cache the reasons for this rating
        _reasonsByRating[rating] = _reasons;

        _error = null;
      } else {
        throw Exception('Failed to load rating reasons: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rating reasons: $e');
      _error = e.toString();
      _reasons = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear reasons when rating changes
  void clearReasons() {
    _reasons = [];
    _error = null;
    notifyListeners();
  }

  // Reset all data
  void reset() {
    _reasons = [];
    _reasonsByRating.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}