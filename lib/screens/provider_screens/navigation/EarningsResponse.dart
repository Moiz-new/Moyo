// models/earnings_response.dart

class EarningsResponse {
  final bool success;
  final int? providerId;
  final String? filter;
  final int? totalServices;
  final String? totalEarnings;
  final int? totalWaitingCharges;
  final List<ServiceEarning>? services;

  EarningsResponse({
    required this.success,
    this.providerId,
    this.filter,
    this.totalServices,
    this.totalEarnings,
    this.totalWaitingCharges,
    this.services,
  });

  factory EarningsResponse.fromJson(Map<String, dynamic> json) {
    return EarningsResponse(
      success: json['success'] ?? false,
      providerId: json['provider_id'] is String
          ? int.tryParse(json['provider_id'])
          : json['provider_id'] as int?,
      filter: json['filter']?.toString(),
      totalServices: json['total_services'] is String
          ? int.tryParse(json['total_services'])
          : json['total_services'] as int?,
      totalEarnings: json['total_earnings']?.toString(),
      totalWaitingCharges: json['total_waiting_charges'] is String
          ? int.tryParse(json['total_waiting_charges'])
          : json['total_waiting_charges'] as int?,
      services: json['services'] != null
          ? (json['services'] as List)
          .map((service) => ServiceEarning.fromJson(service))
          .toList()
          : null,
    );
  }
}

class ServiceEarning {
  final String? serviceId;
  final String? serviceTitle;
  final DateTime? serviceDate;
  final String? baseFare;
  final int? waitingMinutes;
  final int? waitingCharges;
  final String? totalAmount;
  final DateTime? startedAt;
  final DateTime? arrivedAt;
  final DateTime? endedAt;

  ServiceEarning({
    this.serviceId,
    this.serviceTitle,
    this.serviceDate,
    this.baseFare,
    this.waitingMinutes,
    this.waitingCharges,
    this.totalAmount,
    this.startedAt,
    this.arrivedAt,
    this.endedAt,
  });

  factory ServiceEarning.fromJson(Map<String, dynamic> json) {
    return ServiceEarning(
      serviceId: json['service_id']?.toString(),
      serviceTitle: json['service_title']?.toString(),
      serviceDate: json['service_date'] != null
          ? DateTime.parse(json['service_date'])
          : null,
      baseFare: json['base_fare']?.toString(),
      waitingMinutes: json['waiting_minutes'] is String
          ? int.tryParse(json['waiting_minutes'])
          : json['waiting_minutes'] as int?,
      waitingCharges: json['waiting_charges'] is String
          ? int.tryParse(json['waiting_charges'])
          : json['waiting_charges'] as int?,
      totalAmount: json['total_amount']?.toString(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      arrivedAt: json['arrived_at'] != null
          ? DateTime.parse(json['arrived_at'])
          : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
    );
  }

  String getRelativeTime() {
    final dateToUse = serviceDate ?? startedAt;
    if (dateToUse == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(dateToUse);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return getFormattedDate();
    }
  }

  String getFormattedDate() {
    final dateToUse = serviceDate ?? startedAt;
    if (dateToUse == null) return 'N/A';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateToUse.day} ${months[dateToUse.month - 1]} ${dateToUse.year}';
  }

  String getFullFormattedDate() {
    final dateToUse = serviceDate ?? startedAt;
    if (dateToUse == null) return 'N/A';

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${dateToUse.day} ${months[dateToUse.month - 1]} ${dateToUse.year}';
  }

  String getFormattedTime() {
    final dateToUse = startedAt ?? serviceDate;
    if (dateToUse == null) return 'N/A';

    final hour = dateToUse.hour == 0 ? 12 : (dateToUse.hour > 12 ? dateToUse.hour - 12 : dateToUse.hour);
    final amPm = dateToUse.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateToUse.minute.toString().padLeft(2, '0')} $amPm';
  }

  String getDuration() {
    if (startedAt == null || endedAt == null) return 'N/A';

    final duration = endedAt!.difference(startedAt!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}