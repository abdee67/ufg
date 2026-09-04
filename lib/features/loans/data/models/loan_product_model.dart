import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';

class LoanProductModel extends LoanProductEntity {
  const LoanProductModel({
    required super.id,
    required super.code,
    required super.name,
    required super.borrowerType,
    required super.serviceChargeRate,
    required super.maxAmount,
    required super.termMonths,
    required super.active,
  });

  factory LoanProductModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['borrower_type'] as String?)?.toLowerCase() ?? 'member';
    final borrowerType = rawType == 'outsider' ? BorrowerType.outsider : BorrowerType.member;

    return LoanProductModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      borrowerType: borrowerType,
      serviceChargeRate: (json['service_charge_rate'] as num?)?.toDouble() ?? 0.10,
      maxAmount: (json['max_amount'] as num?)?.toDouble() ?? 20000.0,
      termMonths: (json['term_months'] as num?)?.toInt() ?? 3,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'borrower_type': borrowerType == BorrowerType.outsider ? 'outsider' : 'member',
      'service_charge_rate': serviceChargeRate,
      'max_amount': maxAmount,
      'term_months': termMonths,
      'active': active,
    };
  }
}
