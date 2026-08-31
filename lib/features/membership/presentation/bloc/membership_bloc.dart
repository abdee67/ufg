import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/features/membership/domain/usecases/cancel_membership_application.dart';
import 'package:ufg/features/membership/domain/usecases/get_membership_status.dart';
import 'package:ufg/features/membership/domain/usecases/submit_membership_application.dart';
import 'package:ufg/features/membership/domain/usecases/upload_fayda_document.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_event.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_state.dart';

class MembershipBloc extends Bloc<MembershipEvent, MembershipState> {
  final GetMembershipStatus getMembershipStatus;
  final SubmitMembershipApplication submitMembershipApplication;
  final CancelMembershipApplication cancelMembershipApplication;
  final UploadFaydaDocument uploadFaydaDocument;

  MembershipBloc({
    required this.getMembershipStatus,
    required this.submitMembershipApplication,
    required this.cancelMembershipApplication,
    required this.uploadFaydaDocument,
  }) : super(MembershipInitial()) {
    on<LoadMembershipStatusRequested>(_onLoadStatus);
    on<SubmitMembershipApplicationRequested>(_onSubmit);
    on<CancelMembershipApplicationRequested>(_onCancel);
  }

  Future<void> _onLoadStatus(
    LoadMembershipStatusRequested event,
    Emitter<MembershipState> emit,
  ) async {
    emit(MembershipLoading());

    final result = await getMembershipStatus();

    result.fold(
      (failure) => emit(MembershipFailure(message: failure.message)),
      (status) => emit(MembershipStatusLoaded(
        application: status.application,
        member: status.member,
      )),
    );
  }

  Future<void> _onSubmit(
    SubmitMembershipApplicationRequested event,
    Emitter<MembershipState> emit,
  ) async {
    emit(MembershipLoading());

    // Step 1: Upload Fayda document to Storage
    final uploadResult = await uploadFaydaDocument(
      filePath: event.filePath,
      fileName: event.fileName,
      mimeType: event.mimeType,
      fileSizeBytes: event.fileSizeBytes,
    );

    final storagePath = uploadResult.fold(
      (failure) {
        emit(MembershipFailure(message: failure.message));
        return null;
      },
      (path) => path,
    );

    if (storagePath == null) return;

    // Step 2: Call atomic RPC to submit application
    final result = await submitMembershipApplication(
      address: event.address,
      dateOfBirth: event.dateOfBirth,
      phone: event.phone,
      storagePath: storagePath,
      fileName: event.fileName,
      mimeType: event.mimeType,
      fileSizeBytes: event.fileSizeBytes,
    );

    result.fold(
      (failure) => emit(MembershipFailure(message: failure.message)),
      (application) => emit(MembershipSubmitSuccess(application: application)),
    );
  }

  Future<void> _onCancel(
    CancelMembershipApplicationRequested event,
    Emitter<MembershipState> emit,
  ) async {
    emit(MembershipLoading());

    final result = await cancelMembershipApplication(event.applicationId);

    result.fold(
      (failure) => emit(MembershipFailure(message: failure.message)),
      (_) => emit(const MembershipOperationSuccess(
        message: 'Membership application cancelled successfully.',
      )),
    );
  }
}
