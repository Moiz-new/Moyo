class ServiceResponse {
  final bool success;
  final int total;
  final List<ServiceModel> services;

  ServiceResponse({required this.success, required this.total, required this.services});

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    return ServiceResponse(
      success: json['success'] ?? false,
      total: json['total'] ?? 0,
      services: (json['services'] as List<dynamic>?)?.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class ServiceModel {
  final String id;
  final String title;
  final String category;
  final String service;
  final String description;
  final String budget;
  final String maxBudget;
  final String location;
  final String serviceMode;
  final int? durationValue;
  final String? durationUnit;
  final int? serviceDays;
  final String status;
  final String totalBids;
  final String createdAtFormatted;

  ServiceModel({
    required this.id,
    required this.title,
    required this.category,
    required this.service,
    required this.description,
    required this.budget,
    required this.maxBudget,
    required this.location,
    required this.serviceMode,
    this.durationValue,
    this.durationUnit,
    this.serviceDays,
    required this.status,
    required this.totalBids,
    required this.createdAtFormatted,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      service: json['service'] ?? '',
      description: json['description'] ?? '',
      budget: json['budget']?.toString() ?? '0',
      maxBudget: json['max_budget']?.toString() ?? '0',
      location: json['location'] ?? '',
      serviceMode: json['service_mode'] ?? '',
      durationValue: json['duration_value'],
      durationUnit: json['duration_unit'],
      serviceDays: json['service_days'],
      status: json['status'] ?? '',
      totalBids: json['total_bids']?.toString() ?? '0',
      createdAtFormatted: json['created_at_formatted'] ?? '',
    );
  }
}