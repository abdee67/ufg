import 'package:equatable/equatable.dart';

/// A single durable in-app notification row owned by the authenticated profile.
///
/// Mirrors `public.notifications` from
/// `20260929000038_notification_infrastructure_v1.sql`.
class NotificationEntity extends Equatable {
  final String id;
  final String recipientProfileId;
  final String category;
  final String type;
  final String title;
  final String body;
  final String priority;
  final Map<String, dynamic> data;
  final String? sourceType;
  final String? sourceId;
  final String? dedupeKey;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const NotificationEntity({
    required this.id,
    required this.recipientProfileId,
    required this.category,
    required this.type,
    required this.title,
    required this.body,
    required this.priority,
    required this.data,
    this.sourceType,
    this.sourceId,
    this.dedupeKey,
    this.readAt,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isRead => readAt != null;

  bool get isHighPriority => priority == 'high' || priority == 'critical';

  bool get isCritical => priority == 'critical';

  /// Navigation hint emitted by the backend (`data.target_type`).
  String? get targetType {
    final value = data['target_type'];
    return value is String ? value : null;
  }

  String? get transactionType {
    final value = data['transaction_type'];
    return value is String ? value : null;
  }

  bool get isSavingsRelated =>
      category == 'savings' ||
      category == 'transaction' ||
      (transactionType?.startsWith('savings_') ?? false) ||
      (transactionType == 'first_contribution');

  bool get isLoanRelated =>
      category == 'loan' ||
      (transactionType?.startsWith('loan_') ?? false);

  /// Local, presentation-only update. Postgres remains authoritative and the
  /// inbox is refetched on reconnect.
  NotificationEntity copyWith({DateTime? readAt}) {
    return NotificationEntity(
      id: id,
      recipientProfileId: recipientProfileId,
      category: category,
      type: type,
      title: title,
      body: body,
      priority: priority,
      data: data,
      sourceType: sourceType,
      sourceId: sourceId,
      dedupeKey: dedupeKey,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        recipientProfileId,
        category,
        type,
        title,
        body,
        priority,
        data,
        sourceType,
        sourceId,
        dedupeKey,
        readAt,
        createdAt,
        expiresAt,
      ];
}
