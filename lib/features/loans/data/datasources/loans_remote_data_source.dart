import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/features/loans/data/models/guarantor_request_model.dart';
import 'package:ufg/features/loans/data/models/guarantor_candidate_model.dart';
import 'package:ufg/features/loans/data/models/member_loan_limit_model.dart';
import 'package:ufg/features/loans/data/models/loan_application_model.dart';
import 'package:ufg/features/loans/data/models/loan_eligibility_result_model.dart';
import 'package:ufg/features/loans/data/models/loan_installment_model.dart';
import 'package:ufg/features/loans/data/models/loan_model.dart';
import 'package:ufg/features/loans/data/models/loan_product_model.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';

abstract class LoansRemoteDataSource {
  Future<List<LoanProductModel>> getLoanProducts();

  Future<List<LoanApplicationModel>> getMyLoanApplications();

  Future<List<LoanModel>> getMyLoans();

  Future<Map<String, dynamic>> getLoanApplicationDetail(String applicationId);

  Future<Map<String, dynamic>> submitLoanApplication({
    required String loanProductId,
    required double requestedAmount,
    String? purpose,
    required String guarantorMemberId,
  });

  Future<MemberLoanLimitModel> getMyMemberLoanLimit();
  Future<List<GuarantorCandidateModel>> searchLoanGuarantors(String search);
  Future<LoanProductModel> getActiveOutsiderLoanProduct();
  Future<Map<String, dynamic>> submitOutsiderLoanApplication({
    required String loanProductId,
    required String fullName,
    required String phone,
    required String address,
    required double requestedAmount,
    required String purpose,
    required String guarantorMemberId,
  });

  Future<void> cancelLoanApplication(String applicationId);

  Future<LoanEligibilityResultModel> evaluateLoanEligibility(
    String applicationId,
  );

  Future<void> requestLoanGuarantor({
    required String loanApplicationId,
    required String guarantorMemberId,
  });

  Future<List<GuarantorRequestModel>> getMyGuarantorRequests();

  Future<void> respondToGuarantorRequest({
    required String guarantorRequestId,
    required BorrowerType borrowerType,
    required bool accept,
    String? rejectionReason,
  });

  Future<void> requestLoanExtension({
    required String loanId,
    required String reason,
    DateTime? requestedNewDueDate,
  });

  Future<List<LoanInstallmentModel>> getLoanInstallments(String loanId);

  Future<Map<String, dynamic>> submitLoanRepaymentPayment({
    required String loanId,
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    List<Map<String, dynamic>>? allocations,
  });

  Future<String> uploadPaymentProof({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });
}

class LoansRemoteDataSourceImpl implements LoansRemoteDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthExceptions(message: 'Not authenticated.');
    }
    return user.id;
  }

  @override
  Future<List<LoanProductModel>> getLoanProducts() async {
    try {
      final response = await _client
          .from('loan_products')
          .select()
          .eq('active', true)
          .order('service_charge_rate');

      final list = response as List;
      return list
          .map(
            (item) => LoanProductModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) print('getLoanProducts error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<List<LoanApplicationModel>> getMyLoanApplications() async {
    try {
      final response = await _client.rpc('get_my_member_loan_applications_v2');
      if (response == null) return [];
      final list = response as List;
      return list
          .map(
            (item) => LoanApplicationModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode)
        print('RPC get_my_member_loan_applications_v2 error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<List<LoanModel>> getMyLoans() async {
    try {
      final response = await _client.rpc('get_my_loans');
      if (response == null) return [];
      final list = response as List;
      return list
          .map(
            (item) =>
                LoanModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) print('RPC get_my_loans error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getLoanApplicationDetail(
    String applicationId,
  ) async {
    try {
      final response = await _client.rpc(
        'get_member_loan_application_detail_v2',
        params: {'p_application_id': applicationId},
      );
      if (response == null) {
        throw const AuthExceptions(
          message: 'Loan application details not found.',
        );
      }
      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC get_loan_application_detail error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> submitLoanApplication({
    required String loanProductId,
    required double requestedAmount,
    String? purpose,
    required String guarantorMemberId,
  }) async {
    try {
      final response = await _client.rpc(
        'submit_member_loan_application_v2',
        params: {
          'p_loan_product_id': loanProductId,
          'p_requested_amount': requestedAmount,
          'p_purpose': purpose ?? '',
          'p_guarantor_member_id': guarantorMemberId,
        },
      );

      if (response == null) {
        throw const AuthExceptions(
          message: 'Failed to submit loan application.',
        );
      }
      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      if (kDebugMode)
        print('RPC submit_member_loan_application_v2 error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<MemberLoanLimitModel> getMyMemberLoanLimit() async {
    try {
      final response = await _client.rpc('get_my_member_loan_limit_v2');
      if (response == null) {
        throw const AuthExceptions(
          message: 'Member loan limit is unavailable.',
        );
      }
      return MemberLoanLimitModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on PostgrestException catch (e) {
      if (kDebugMode)
        print('RPC get_my_member_loan_limit_v2 error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<List<GuarantorCandidateModel>> searchLoanGuarantors(
    String search,
  ) async {
    try {
      final response = await _client.rpc(
        'search_outsider_loan_guarantors',
        params: {'p_search': search.trim()},
      );
      final list = response as List? ?? const [];
      return list
          .map(
            (item) => GuarantorCandidateModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((candidate) => candidate.memberId.isNotEmpty)
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode)
        print('RPC search_outsider_loan_guarantors error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<LoanProductModel> getActiveOutsiderLoanProduct() async {
    try {
      final response = await _client.rpc('get_active_outsider_loan_product_v2');
      if (response == null) {
        throw const AuthExceptions(
          message: 'Outsider loan is currently unavailable.',
        );
      }
      return LoanProductModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on PostgrestException catch (e) {
      if (kDebugMode)
        print('RPC get_active_outsider_loan_product_v2 error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> submitOutsiderLoanApplication({
    required String loanProductId,
    required String fullName,
    required String phone,
    required String address,
    required double requestedAmount,
    required String purpose,
    required String guarantorMemberId,
  }) async {
    try {
      final response = await _client.rpc(
        'submit_outsider_loan_application_v2',
        params: {
          'p_loan_product_id': loanProductId,
          'p_full_name': fullName.trim(),
          'p_phone': phone.trim(),
          'p_address': address.trim(),
          'p_requested_amount': requestedAmount,
          'p_purpose': purpose.trim(),
          'p_guarantor_member_id': guarantorMemberId,
        },
      );
      if (response == null) {
        throw const AuthExceptions(
          message: 'Failed to submit outsider loan application.',
        );
      }
      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      if (kDebugMode)
        print('RPC submit_outsider_loan_application_v2 error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<void> cancelLoanApplication(String applicationId) async {
    try {
      await _client.rpc(
        'cancel_loan_application',
        params: {'p_loan_application_id': applicationId},
      );
    } on PostgrestException catch (e) {
      if (kDebugMode) print('RPC cancel_loan_application error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<LoanEligibilityResultModel> evaluateLoanEligibility(
    String applicationId,
  ) async {
    try {
      final response = await _client.rpc(
        'evaluate_loan_application',
        params: {'p_application_id': applicationId},
      );

      if (response == null) {
        throw const AuthExceptions(
          message: 'Eligibility evaluation returned empty result.',
        );
      }
      return LoanEligibilityResultModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC evaluate_loan_application error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<void> requestLoanGuarantor({
    required String loanApplicationId,
    required String guarantorMemberId,
  }) async {
    try {
      await _client.rpc(
        'request_loan_guarantor',
        params: {
          'p_loan_application_id': loanApplicationId,
          'p_guarantor_member_id': guarantorMemberId,
        },
      );
    } on PostgrestException catch (e) {
      if (kDebugMode) print('RPC request_loan_guarantor error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<List<GuarantorRequestModel>> getMyGuarantorRequests() async {
    try {
      final response = await _client.rpc('get_my_guarantor_requests_v2');
      final list = response as List? ?? const [];
      return list
          .map(
            (item) => GuarantorRequestModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) print('getMyGuarantorRequests error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<void> respondToGuarantorRequest({
    required String guarantorRequestId,
    required BorrowerType borrowerType,
    required bool accept,
    String? rejectionReason,
  }) async {
    try {
      await _client.rpc(
        borrowerType == BorrowerType.member
            ? 'respond_to_member_loan_guarantor_request_v2'
            : 'respond_to_outsider_loan_guarantor_request_v2',
        params: {
          'p_guarantor_id': guarantorRequestId,
          'p_decision': accept ? 'approved' : 'rejected',
          'p_rejection_reason': rejectionReason?.trim(),
        },
      );
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC respond_to_loan_guarantor_request error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<void> requestLoanExtension({
    required String loanId,
    required String reason,
    DateTime? requestedNewDueDate,
  }) async {
    try {
      await _client.rpc(
        'request_loan_extension',
        params: {
          'p_loan_id': loanId,
          'p_reason': reason,
          if (requestedNewDueDate != null)
            'p_requested_new_due_date': requestedNewDueDate
                .toIso8601String()
                .split('T')
                .first,
        },
      );
    } on PostgrestException catch (e) {
      if (kDebugMode) print('RPC request_loan_extension error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<List<LoanInstallmentModel>> getLoanInstallments(String loanId) async {
    try {
      final response = await _client
          .from('loan_installments')
          .select()
          .eq('loan_id', loanId)
          .order('installment_number');

      final list = response as List;
      return list
          .map(
            (item) => LoanInstallmentModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) print('getLoanInstallments error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> submitLoanRepaymentPayment({
    required String loanId,
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    List<Map<String, dynamic>>? allocations,
  }) async {
    try {
      final methodRes = await _client
          .from('payment_methods')
          .select('id')
          .eq('code', paymentMethodCode)
          .single();

      final paymentMethodId = methodRes['id'] as String;

      final paymentInsert = await _client
          .from('payments')
          .insert({
            'payer_profile_id': _currentUserId,
            'payment_method_id': paymentMethodId,
            'amount': amount,
            'currency': 'ETB',
            'status': 'pending',
            'purpose_type': 'loan_repayment',
            'purpose_id': loanId,
            'external_reference': externalReference,
            'payment_proof_path': paymentProofPath,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Map<String, dynamic>.from(paymentInsert);
    } on PostgrestException catch (e) {
      if (kDebugMode) print('submitLoanRepaymentPayment error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<String> uploadPaymentProof({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const AuthExceptions(
          message: 'Selected payment proof file does not exist.',
        );
      }

      final fileBytes = await file.readAsBytes();
      final sanitizedName = fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath =
          'loan_payments/$_currentUserId/${timestamp}_$sanitizedName';

      await _client.storage
          .from('payment-proofs')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      return storagePath;
    } on StorageException catch (e) {
      if (kDebugMode) print('Storage upload error: ${e.message}');
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }
}
