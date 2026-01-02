// lib/blocs/referral/referral_state.dart

import 'ReferralResponseModel.dart';

abstract class ReferralState {}

class ReferralInitial extends ReferralState {}

class ReferralLoading extends ReferralState {}

class ReferralSuccess extends ReferralState {
  final String message;
  final ReferralData? referralData;

  ReferralSuccess({
    required this.message,
    this.referralData,
  });
}

class ReferralError extends ReferralState {
  final String errorMessage;

  ReferralError(this.errorMessage);
}

class ReferralSkipped extends ReferralState {}