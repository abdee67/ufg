abstract class MembershipEvent {}

class LoadMembershipStatusRequested extends MembershipEvent {}

class SubmitMembershipApplicationRequested extends MembershipEvent {
  final String address;
  final DateTime dateOfBirth;
  final String phone;
  final String filePath;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;

  SubmitMembershipApplicationRequested({
    required this.address,
    required this.dateOfBirth,
    required this.phone,
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
  });
}

class CancelMembershipApplicationRequested extends MembershipEvent {
  final String applicationId;

  CancelMembershipApplicationRequested({required this.applicationId});
}

/// Fired by LoginScreen and SessionCheckingSplash after auth is confirmed.
/// The MembershipBloc loads the membership status and emits
/// [MembershipRouteReady] with the resolved destination route.
class CheckMembershipAfterAuthRequested extends MembershipEvent {}
