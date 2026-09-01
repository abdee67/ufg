import 'package:equatable/equatable.dart';

class SavingsAccountEntity extends Equatable {
  final String id;
  final String memberId;
  final String accountId;
  final String status;
  final DateTime createdAt;

  const SavingsAccountEntity({
    required this.id,
    required this.memberId,
    required this.accountId,
    required this.status,
    required this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isLocked => status.toLowerCase() == 'locked';
  bool get isClosed => status.toLowerCase() == 'closed';

  @override
  List<Object?> get props => [id, memberId, accountId, status, createdAt];
}
