class ProviderBidModel {
  final String id;
  final String title;
  final String category;
  final String service;
  final String description;
  final String userId;
  final double budget;
  final double maxBudget;
  final String tenure;
  final DateTime scheduleDate;
  final String scheduleTime;
  final String serviceType;
  final String location;
  final double latitude;
  final double longitude;
  final String serviceMode;
  final int durationValue;
  final String durationUnit;
  final String? serviceDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final int extraTimeMinutes;
  final String? assignedProviderId;
  final String status;
  final String? reason;
  final DateTime? startedAt;
  final DateTime? arrivedAt;
  final DateTime? endedAt;
  final DateTime? confirmedAt;
  final String? startOtp;
  final String? endOtp;
  final String paymentMethod;
  final String paymentType;
  final double? finalAmount;
  final Map<String, dynamic>? dynamicFields;
  final String? cancelledBy;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderBidModel({
    required this.id,
    required this.title,
    required this.category,
    required this.service,
    required this.description,
    required this.userId,
    required this.budget,
    required this.maxBudget,
    required this.tenure,
    required this.scheduleDate,
    required this.scheduleTime,
    required this.serviceType,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.serviceMode,
    required this.durationValue,
    required this.durationUnit,
    this.serviceDays,
    this.startDate,
    this.endDate,
    required this.extraTimeMinutes,
    this.assignedProviderId,
    required this.status,
    this.reason,
    this.startedAt,
    this.arrivedAt,
    this.endedAt,
    this.confirmedAt,
    this.startOtp,
    this.endOtp,
    required this.paymentMethod,
    required this.paymentType,
    this.finalAmount,
    this.dynamicFields,
    this.cancelledBy,
    this.cancelReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderBidModel.fromJson(Map<String, dynamic> json) {
    // Handle nested service object
    final service = json['service'] ?? json;

    return ProviderBidModel(
      id: service['id']?.toString() ?? '0',
      title: service['title'] ?? 'Unknown Service',
      category: service['category'] ?? 'General',
      service: service['service'] ?? 'Service',
      description: service['description'] ?? '',
      userId: service['user_id']?.toString() ?? '0',
      budget: double.tryParse(service['budget']?.toString() ?? '0') ?? 0.0,
      maxBudget: double.tryParse(service['max_budget']?.toString() ?? '0') ?? 0.0,
      tenure: service['tenure'] ?? 'one_time',
      scheduleDate: _parseDateTime(service['schedule_date']),
      scheduleTime: service['schedule_time'] ?? '00:00:00',
      serviceType: service['service_type'] ?? 'instant',
      location: service['location'] ?? 'Unknown Location',
      latitude: double.tryParse(service['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(service['longitude']?.toString() ?? '0') ?? 0.0,
      serviceMode: service['service_mode'] ?? 'hrs',
      durationValue: int.tryParse(service['duration_value']?.toString() ?? '0') ?? 0,
      durationUnit: service['duration_unit'] ?? 'hour',
      serviceDays: service['service_days'],
      startDate: service['start_date'] != null ? _parseDateTime(service['start_date']) : null,
      endDate: service['end_date'] != null ? _parseDateTime(service['end_date']) : null,
      extraTimeMinutes: int.tryParse(service['extra_time_minutes']?.toString() ?? '0') ?? 0,
      assignedProviderId: service['assigned_provider_id']?.toString(),
      status: service['status'] ?? 'open',
      reason: service['reason'],
      startedAt: service['started_at'] != null ? _parseDateTime(service['started_at']) : null,
      arrivedAt: service['arrived_at'] != null ? _parseDateTime(service['arrived_at']) : null,
      endedAt: service['ended_at'] != null ? _parseDateTime(service['ended_at']) : null,
      confirmedAt: service['confirmed_at'] != null ? _parseDateTime(service['confirmed_at']) : null,
      startOtp: service['start_otp'],
      endOtp: service['end_otp'],
      paymentMethod: service['payment_method'] ?? 'prepaid',
      paymentType: service['payment_type'] ?? 'online',
      finalAmount: service['final_amount'] != null
          ? double.tryParse(service['final_amount'].toString())
          : null,
      dynamicFields: service['dynamic_fields'] is Map
          ? Map<String, dynamic>.from(service['dynamic_fields'])
          : null,
      cancelledBy: service['cancelled_by'],
      cancelReason: service['cancel_reason'],
      cancelledAt: service['cancelled_at'] != null ? _parseDateTime(service['cancelled_at']) : null,
      createdAt: _parseDateTime(service['created_at']),
      updatedAt: _parseDateTime(service['updated_at']),
    );
  }

  static DateTime _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedBudget => '₹${budget.toStringAsFixed(2)}';
  String get formattedMaxBudget => '₹${maxBudget.toStringAsFixed(2)}';

  String get durationDisplay {
    if (durationValue == 0) return 'N/A';
    return '$durationValue ${durationUnit}${durationValue > 1 ? 's' : ''}';
  }

  String get dynamicFieldsDisplay {
    if (dynamicFields == null || dynamicFields!.isEmpty) return '';
    return dynamicFields!.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'service': service,
      'description': description,
      'user_id': userId,
      'budget': budget,
      'max_budget': maxBudget,
      'tenure': tenure,
      'schedule_date': scheduleDate.toIso8601String(),
      'schedule_time': scheduleTime,
      'service_type': serviceType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'service_mode': serviceMode,
      'duration_value': durationValue,
      'duration_unit': durationUnit,
      'service_days': serviceDays,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'extra_time_minutes': extraTimeMinutes,
      'assigned_provider_id': assignedProviderId,
      'status': status,
      'payment_method': paymentMethod,
      'payment_type': paymentType,
      'final_amount': finalAmount,
      'dynamic_fields': dynamicFields,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}