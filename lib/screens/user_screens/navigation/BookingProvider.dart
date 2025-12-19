import 'package:flutter/material.dart';
import '../BookProviderApiService.dart';

class BookingProvider extends ChangeNotifier {
  final BookProviderApiService _apiService = BookProviderApiService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>?> bookProvider({
    required String serviceId,
    required String providerId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.confirmProvider(
        serviceId: serviceId,
        providerId: providerId,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}