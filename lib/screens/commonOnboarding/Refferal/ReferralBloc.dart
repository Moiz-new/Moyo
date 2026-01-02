// lib/blocs/referral/referral_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'ReferralEvent.dart';
import 'ReferralRepository.dart';
import 'ReferralState.dart';


class ReferralBloc extends Bloc<ReferralEvent, ReferralState> {
  final ReferralRepository repository;

  ReferralBloc({required this.repository}) : super(ReferralInitial()) {
    on<ApplyReferralCodeEvent>(_onApplyReferralCode);
    on<SkipReferralEvent>(_onSkipReferral);
  }

  Future<void> _onApplyReferralCode(
      ApplyReferralCodeEvent event,
      Emitter<ReferralState> emit,
      ) async {
    emit(ReferralLoading());

    try {
      final response = await repository.applyReferralCode(event.referralCode);

      if (response.message.toLowerCase().contains('success')) {
        emit(ReferralSuccess(
          message: response.message,
          referralData: response.referral,
        ));
      } else {
        emit(ReferralError(response.message));
      }
    } catch (e) {
      emit(ReferralError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onSkipReferral(
      SkipReferralEvent event,
      Emitter<ReferralState> emit,
      ) async {
    emit(ReferralSkipped());
  }
}