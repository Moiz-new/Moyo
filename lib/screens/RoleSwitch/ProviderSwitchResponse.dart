class ProviderSwitchResponse {
  final String message;
  final ProviderData? provider;
  final String? providerToken;

  ProviderSwitchResponse({
    required this.message,
    this.provider,
    this.providerToken,
  });

  factory ProviderSwitchResponse.fromJson(Map<String, dynamic> json) {
    return ProviderSwitchResponse(
      message: json['message'] ?? '',
      provider: json['provider'] != null
          ? ProviderData.fromJson(json['provider'])
          : null,
      providerToken: json['providertoken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'provider': provider?.toJson(),
      'providertoken': providerToken,
    };
  }
}

class ProviderData {
  final int id;
  final int userId;
  final String? experience;
  final String? education;
  final String? educationProof;
  final String? licenseCertified;
  final String? licenseType;
  final String? licenseProof;
  final String? service;
  final String? keySkills;
  final String? aadhaarPhoto;
  final String? adharNo;
  final bool isActive;
  final bool isRegistered;
  final bool isBlocked;
  final double? latitude;
  final double? longitude;
  final String? createdAt;
  final String? updatedAt;

  ProviderData({
    required this.id,
    required this.userId,
    this.experience,
    this.education,
    this.educationProof,
    this.licenseCertified,
    this.licenseType,
    this.licenseProof,
    this.service,
    this.keySkills,
    this.aadhaarPhoto,
    this.adharNo,
    required this.isActive,
    required this.isRegistered,
    required this.isBlocked,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderData.fromJson(Map<String, dynamic> json) {
    return ProviderData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      experience: json['experience'],
      education: json['education'],
      educationProof: json['education_proof'],
      licenseCertified: json['license_certified'],
      licenseType: json['license_type'],
      licenseProof: json['license_proof'],
      service: json['service'],
      keySkills: json['key_skills'],
      aadhaarPhoto: json['aadhaar_photo'],
      adharNo: json['adhar_no'],
      isActive: json['isactive'] ?? false,
      isRegistered: json['isregistered'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'experience': experience,
      'education': education,
      'education_proof': educationProof,
      'license_certified': licenseCertified,
      'license_type': licenseType,
      'license_proof': licenseProof,
      'service': service,
      'key_skills': keySkills,
      'aadhaar_photo': aadhaarPhoto,
      'adhar_no': adharNo,
      'isactive': isActive,
      'isregistered': isRegistered,
      'is_blocked': isBlocked,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}