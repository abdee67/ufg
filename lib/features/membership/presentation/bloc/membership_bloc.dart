import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/features/membership/domain/usecases/cancel_membership_application.dart';
import 'package:ufg/features/membership/domain/usecases/get_membership_status.dart';
import 'package:ufg/features/membership/domain/usecases/submit_membership_application.dart';
import 'membership_event.dart';
import 'membership_state.dart';

class MembershipBloc extends Bloc<MembershipEvent, MembershipState> {
  final GetMembershipStatus getMembershipStatus;
  final SubmitMembershipApplication submitMembershipApplication;
  final CancelMembershipApplication cancelMembershipApplication;

  MembershipBloc({
    required this.getMembershipStatus,
    required this.submitMembershipApplication,
    required this.cancelMembershipApplication,
  }) : super(const MembershipInitial()) {
    on<LoadMembershipStatusRequested>(_onLoadMembershipStatus);
    on<SubmitMembershipApplicationRequested>(_onSubmitMembershipApplication);
    on<CancelMembershipApplicationRequested>(_onCancelMembershipApplication);
  }

  Future<void> _onLoadMembershipStatus(
    LoadMembershipStatusRequested event,
    Emitter<MembershipState> emit,
  ) async {
    emit(const MembershipLoading());
    final result = await getMembershipStatus();
    result.fold(
      (failure) => emit(MembershipFailure(failure.message)),
      (statusResult) => emit(MembershipStatusLoaded(statusResult)),
    );
  }

  Future<void> _onSubmitMembershipApplication(
    SubmitMembershipApplicationRequested event,
    Emitter<MembershipState> emit,
  ) async {
    emit(const MembershipLoading());
    final result = await submitMembershipApplication(
      SubmitMembershipApplicationParams(
        nationalId: event.nationalId,
        address: event.address,
        dateOfBirth: event.dateOfBirth,
        phone: event.phone,
      ),
    );

    result.fold(
      (failure) => emit(MembershipFailure(failure.message)),
      (application) => emit(MembershipSubmitSuccess(application.applicationNumber)),
    );
  }

  Future<void> _onCancelMembershipApplication(
    CancelMembershipApplicationRequested event,
    Emitter<MembershipState> emit,
  ) async {
    emit(const MembershipLoading());
    final result = await cancelMembershipApplication(event.applicationId);
    result.fold(
      (failure) => emit(MembershipFailure(failure.message)),
      (_) => emit(const MembershipOperationSuccess('Application cancelled successfully')),
    );
  }
}
