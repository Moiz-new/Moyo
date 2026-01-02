// lib/models/referral_response_model.dart

class ReferralData {
  final int id;
  final int referrerId;
  final int referredUserId;
  final String referralCode;
  final String status;
  final String rewardAmount;
  final String createdAt;
  final String updatedAt;

  ReferralData({
    required this.id,
    required this.referrerId,
    required this.referredUserId,
    required this.referralCode,
    required this.status,
    required this.rewardAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      id: json['id'] ?? 0,
      referrerId: json['referrer_id'] ?? 0,
      referredUserId: json['referred_user_id'] ?? 0,
      referralCode: json['referral_code'] ?? '',
      status: json['status'] ?? '',
      rewardAmount: json['reward_amount'] ?? '0.00',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ReferralResponseModel {
  final String message;
  final ReferralData? referral;

  ReferralResponseModel({
    required this.message,
    this.referral,
  });

  factory ReferralResponseModel.fromJson(Map<String, dynamic> json) {
    return ReferralResponseModel(
      message: json['message'] ?? '',
      referral: json['referral'] != null
          ? ReferralData.fromJson(json['referral'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'referral': referral,
    };
  }
}