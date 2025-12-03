import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Carousel Model
class Carousel {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final int categoryId;
  final String type;
  final int displayOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Carousel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
    required this.type,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Carousel.fromJson(Map<String, dynamic> json) {
    return Carousel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      categoryId: json['category_id'] ?? 0,
      type: json['type'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class CarouselResponse {
  final bool success;
  final String message;
  final int total;
  final List<Carousel> carousels;

  CarouselResponse({
    required this.success,
    required this.message,
    required this.total,
    required this.carousels,
  });

  factory CarouselResponse.fromJson(Map<String, dynamic> json) {
    return CarouselResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      carousels: (json['carousels'] as List<dynamic>?)
          ?.map((item) => Carousel.fromJson(item))
          .toList() ??
          [],
    );
  }
}

// Carousel Provider
class CarouselProvider with ChangeNotifier {
  List<Carousel> _carousels = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Carousel> get carousels => _carousels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCarousels({String type = 'provider'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$base_url/api/carousel?type=$type'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final carouselResponse = CarouselResponse.fromJson(jsonData);

        // Filter only active carousels and sort by display_order
        _carousels = carouselResponse.carousels
            .where((carousel) => carousel.isActive)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        _errorMessage = null;
      } else {
        _errorMessage =
        'Failed to load carousels. Status: ${response.statusCode}';
        _carousels = [];
      }
    } catch (e) {
      _errorMessage = 'Error fetching carousels: ${e.toString()}';
      _carousels = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}