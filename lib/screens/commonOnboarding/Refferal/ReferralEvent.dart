
abstract class ReferralEvent {}

class ApplyReferralCodeEvent extends ReferralEvent {
  final String referralCode;

  ApplyReferralCodeEvent(this.referralCode);
}

class SkipReferralEvent extends ReferralEvent {}