// models/UserProfileModel.dart

class UserProfileModel {
  final int id;
  final String? username;
  final String? email;
  final String? firstname;
  final String? lastname;
  final String? mobile;
  final int? age;
  final String? gender;
  final String? image;
  final bool isRegister;
  final bool isProvider;
  final bool isBlocked;
  final String? referralCode;
  final String? referredBy;
  final double wallet;
  final bool emailVerified;
  final String createdAt;
  final String? updatedAt;
  final int? primaryAddressId;
  final bool? declaration;
  final String? otp;
  final String? otpExpiresAt;
  final String? uid;
  final String? deviceToken;
  final String? emailOtp;
  final String? emailOtpExpiresAt;
  final int? count;
  final ProviderModel? provider;

  UserProfileModel({
    required this.id,
    this.username,
    this.email,
    this.firstname,
    this.lastname,
    this.mobile,
    this.age,
    this.gender,
    this.image,
    required this.isRegister,
    required this.isProvider,
    required this.isBlocked,
    this.referralCode,
    this.referredBy,
    required this.wallet,
    required this.emailVerified,
    required this.createdAt,
    this.updatedAt,
    this.primaryAddressId,
    this.declaration,
    this.otp,
    this.otpExpiresAt,
    this.uid,
    this.deviceToken,
    this.emailOtp,
    this.emailOtpExpiresAt,
    this.count,
    this.provider,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? 0,
      username: json['username'],
      email: json['email'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      mobile: json['mobile'],
      age: json['age'],
      gender: json['gender'],
      image: json['image'],
      isRegister: json['isregister'] ?? false,
      isProvider: json['is_provider'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      referralCode: json['referral_code'],
      referredBy: json['referred_by'],
      wallet: (json['wallet'] ?? 0).toDouble(),
      emailVerified: json['email_verified'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      primaryAddressId: json['primary_address_id'],
      declaration: json['declaration'],
      otp: json['otp'],
      otpExpiresAt: json['otp_expires_at'],
      uid: json['uid'],
      deviceToken: json['device_token'],
      emailOtp: json['email_otp'],
      emailOtpExpiresAt: json['email_otp_expires_at'],
      count: json['count'],
      provider: json['provider'] != null
          ? ProviderModel.fromJson(json['provider'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'mobile': mobile,
      'age': age,
      'gender': gender,
      'image': image,
      'isregister': isRegister,
      'is_provider': isProvider,
      'is_blocked': isBlocked,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'wallet': wallet,
      'email_verified': emailVerified,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'primary_address_id': primaryAddressId,
      'declaration': declaration,
      'otp': otp,
      'otp_expires_at': otpExpiresAt,
      'uid': uid,
      'device_token': deviceToken,
      'email_otp': emailOtp,
      'email_otp_expires_at': emailOtpExpiresAt,
      'count': count,
      'provider': provider?.toJson(),
    };
  }

  // Computed properties with null checks
  String get fullName {
    if (firstname != null && lastname != null) {
      return '$firstname $lastname';
    } else if (firstname != null) {
      return firstname!;
    } else if (lastname != null) {
      return lastname!;
    } else if (username != null) {
      return username!;
    } else if (mobile != null) {
      return mobile!;
    }
    return 'User';
  }

  String get displayEmail => email ?? 'Not provided';

  String get displayMobile => mobile ?? 'Not provided';

  String get displayImage => image ?? '';

  String get displayAddress => 'Not provided';

  bool get hasProviderData => provider != null;

  bool get hasBasicInfo =>
      firstname != null ||
          lastname != null ||
          username != null ||
          email != null;

  // CopyWith method for updating specific fields
  UserProfileModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstname,
    String? lastname,
    String? mobile,
    int? age,
    String? gender,
    String? image,
    bool? isRegister,
    bool? isProvider,
    bool? isBlocked,
    String? referralCode,
    String? referredBy,
    double? wallet,
    bool? emailVerified,
    String? createdAt,
    String? updatedAt,
    int? primaryAddressId,
    bool? declaration,
    String? otp,
    String? otpExpiresAt,
    String? uid,
    String? deviceToken,
    String? emailOtp,
    String? emailOtpExpiresAt,
    int? count,
    ProviderModel? provider,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      mobile: mobile ?? this.mobile,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      image: image ?? this.image,
      isRegister: isRegister ?? this.isRegister,
      isProvider: isProvider ?? this.isProvider,
      isBlocked: isBlocked ?? this.isBlocked,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      wallet: wallet ?? this.wallet,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      primaryAddressId: primaryAddressId ?? this.primaryAddressId,
      declaration: declaration ?? this.declaration,
      otp: otp ?? this.otp,
      otpExpiresAt: otpExpiresAt ?? this.otpExpiresAt,
      uid: uid ?? this.uid,
      deviceToken: deviceToken ?? this.deviceToken,
      emailOtp: emailOtp ?? this.emailOtp,
      emailOtpExpiresAt: emailOtpExpiresAt ?? this.emailOtpExpiresAt,
      count: count ?? this.count,
      provider: provider ?? this.provider,
    );
  }
}

class ProviderModel {
  final int id;
  final int userId;
  final String? education;
  final String? educationProof;
  final String? aadhaarPhoto;
  final String? adharNo;
  final bool isActive;
  final bool isRegistered;
  final bool isBlocked;
  final String createdAt;
  final String updatedAt;
  final String? panNo;
  final String? panPhoto;
  final String? deviceToken;
  final double workRadius;
  final bool notified;
  final bool? declaration;

  ProviderModel({
    required this.id,
    required this.userId,
    this.education,
    this.educationProof,
    this.aadhaarPhoto,
    this.adharNo,
    required this.isActive,
    required this.isRegistered,
    required this.isBlocked,
    required this.createdAt,
    required this.updatedAt,
    this.panNo,
    this.panPhoto,
    this.deviceToken,
    required this.workRadius,
    required this.notified,
    this.declaration,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      education: json['education'],
      educationProof: json['education_proof'],
      aadhaarPhoto: json['aadhaar_photo'],
      adharNo: json['adhar_no'],
      isActive: json['isactive'] ?? false,
      isRegistered: json['isregistered'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      panNo: json['pan_no'],
      panPhoto: json['pan_photo'],
      deviceToken: json['device_token'],
      workRadius: (json['work_radius'] ?? 0).toDouble(),
      notified: json['notified'] ?? false,
      declaration: json['declaration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'education': education,
      'education_proof': educationProof,
      'aadhaar_photo': aadhaarPhoto,
      'adhar_no': adharNo,
      'isactive': isActive,
      'isregistered': isRegistered,
      'is_blocked': isBlocked,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pan_no': panNo,
      'pan_photo': panPhoto,
      'device_token': deviceToken,
      'work_radius': workRadius,
      'notified': notified,
      'declaration': declaration,
    };
  }

  // CopyWith method for updating specific fields
  ProviderModel copyWith({
    int? id,
    int? userId,
    String? education,
    String? educationProof,
    String? aadhaarPhoto,
    String? adharNo,
    bool? isActive,
    bool? isRegistered,
    bool? isBlocked,
    String? createdAt,
    String? updatedAt,
    String? panNo,
    String? panPhoto,
    String? deviceToken,
    double? workRadius,
    bool? notified,
    bool? declaration,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      education: education ?? this.education,
      educationProof: educationProof ?? this.educationProof,
      aadhaarPhoto: aadhaarPhoto ?? this.aadhaarPhoto,
      adharNo: adharNo ?? this.adharNo,
      isActive: isActive ?? this.isActive,
      isRegistered: isRegistered ?? this.isRegistered,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      panNo: panNo ?? this.panNo,
      panPhoto: panPhoto ?? this.panPhoto,
      deviceToken: deviceToken ?? this.deviceToken,
      workRadius: workRadius ?? this.workRadius,
      notified: notified ?? this.notified,
      declaration: declaration ?? this.declaration,
    );
  }
}