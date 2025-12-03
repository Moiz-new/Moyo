// models/user_profile_model.dart

class UserProfileModel {
  final int id;
  final String? username;
  final String? email;
  final String? firstname;
  final String? lastname;
  final String mobile;
  final String? address;
  final int? age;
  final String createdAt;
  final String? gender;
  final String? image;
  final bool isRegister;
  final bool isProvider;
  final bool isBlocked;
  final String? uid;
  final String? deviceToken;
  final String referralCode;
  final String? referredBy;
  final double wallet;
  final bool emailVerified;
  final String updatedAt;

  UserProfileModel({
    required this.id,
    this.username,
    this.email,
    this.firstname,
    this.lastname,
    required this.mobile,
    this.address,
    this.age,
    required this.createdAt,
    this.gender,
    this.image,
    required this.isRegister,
    required this.isProvider,
    required this.isBlocked,
    this.uid,
    this.deviceToken,
    required this.referralCode,
    this.referredBy,
    required this.wallet,
    required this.emailVerified,
    required this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? 0,
      username: json['username'],
      email: json['email'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      mobile: json['mobile'] ?? '',
      address: json['address'],
      age: json['age'],
      createdAt: json['created_at'] ?? '',
      gender: json['gander'], // Note: API has typo "gander" instead of "gender"
      image: json['image'],
      isRegister: json['isregister'] ?? false,
      isProvider: json['is_provider'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      uid: json['uid'],
      deviceToken: json['device_token'],
      referralCode: json['referral_code'] ?? '',
      referredBy: json['referred_by'],
      wallet: (json['wallet'] ?? 0).toDouble(),
      emailVerified: json['email_verified'] ?? false,
      updatedAt: json['updated_at'] ?? '',
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
      'address': address,
      'age': age,
      'created_at': createdAt,
      'gander': gender,
      'image': image,
      'isregister': isRegister,
      'is_provider': isProvider,
      'is_blocked': isBlocked,
      'uid': uid,
      'device_token': deviceToken,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'wallet': wallet,
      'email_verified': emailVerified,
      'updated_at': updatedAt,
    };
  }

  String get fullName {
    if (firstname != null && lastname != null) {
      return '${firstname!} ${lastname!}'.trim();
    } else if (firstname != null) {
      return firstname!;
    } else if (lastname != null) {
      return lastname!;
    }
    return 'User';
  }

  String get displayEmail => email ?? 'Not provided';
  String get displayAddress => address ?? 'Not provided';
  String get displayImage => image ?? '';
}