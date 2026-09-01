import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/features/savings/data/models/savings_history_item_model.dart';
import 'package:ufg/features/savings/data/models/savings_obligation_model.dart';
import 'package:ufg/features/savings/data/models/savings_summary_model.dart';
import 'package:ufg/features/savings/data/models/withdrawal_request_model.dart';

abstract class SavingsRemoteDataSource {
  Future<SavingsSummaryModel> getSavingsSummary();

  Future<List<SavingsObligationModel>> getSavingsObligations();

  Future<List<SavingsHistoryItemModel>> getSavingsHistory();

  Future<Map<String, dynamic>> submitSavingsPayment({
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    String? obligationId,
  });

  Future<WithdrawalRequestModel> requestSavingsWithdrawal({
    required double amount,
    String? reason,
  });

  Future<WithdrawalRequestModel> cancelWithdrawalRequest({
    required String withdrawalRequestId,
  });

  Future<List<WithdrawalRequestModel>> getWithdrawalRequests();

  Future<String> uploadPaymentProof({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });
}

class SavingsRemoteDataSourceImpl implements SavingsRemoteDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthExceptions(message: 'Not authenticated.');
    }
    return user.id;
  }

  @override
  Future<SavingsSummaryModel> getSavingsSummary() async {
    try {
      final response = await _client.rpc('get_my_savings_summary');
      if (response == null) {
        throw const AuthExceptions(message: 'Failed to retrieve savings summary.');
      }
      return SavingsSummaryModel.fromJson(Map<String, dynamic>.from(response as Map));
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC get_my_savings_summary error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<List<SavingsObligationModel>> getSavingsObligations() async {
    try {
      final response = await _client.rpc('get_my_savings_obligations');
      if (response == null) return [];
      final list = response as List;
      return list
          .map((item) => SavingsObligationModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC get_my_savings_obligations error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<List<SavingsHistoryItemModel>> getSavingsHistory() async {
    try {
      final response = await _client.rpc('get_my_savings_history');
      if (response == null) return [];
      final list = response as List;
      return list
          .map((item) => SavingsHistoryItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC get_my_savings_history error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> submitSavingsPayment({
    required double amount,
    required String paymentMethodCode,
    required String externalReference,
    String? paymentProofPath,
    String? obligationId,
  }) async {
    try {
      final response = await _client.rpc(
        'submit_savings_payment',
        params: {
          'p_amount': amount,
          'p_payment_method_code': paymentMethodCode,
          'p_external_reference': externalReference,
          'p_payment_proof_path': paymentProofPath,
          'p_obligation_id': obligationId,
        },
      );

      if (response == null) {
        throw const AuthExceptions(message: 'Failed to submit savings payment.');
      }

      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC submit_savings_payment error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<WithdrawalRequestModel> requestSavingsWithdrawal({
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await _client.rpc(
        'request_savings_withdrawal',
        params: {
          'p_amount': amount,
          'p_reason': reason,
        },
      );

      if (response == null) {
        throw const AuthExceptions(message: 'Failed to request savings withdrawal.');
      }

      return WithdrawalRequestModel.fromJson(Map<String, dynamic>.from(response as Map));
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC request_savings_withdrawal error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<WithdrawalRequestModel> cancelWithdrawalRequest({
    required String withdrawalRequestId,
  }) async {
    try {
      final response = await _client.rpc(
        'cancel_withdrawal_request',
        params: {'p_withdrawal_request_id': withdrawalRequestId},
      );

      if (response == null) {
        throw const AuthExceptions(message: 'Failed to cancel withdrawal request.');
      }

      return WithdrawalRequestModel.fromJson(Map<String, dynamic>.from(response as Map));
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC cancel_withdrawal_request error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<List<WithdrawalRequestModel>> getWithdrawalRequests() async {
    try {
      final response = await _client.rpc('get_my_withdrawal_requests');
      if (response == null) return [];
      final list = response as List;
      return list
          .map((item) => WithdrawalRequestModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC get_my_withdrawal_requests error: ${e.message}');
      }
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
      final userId = _currentUserId;

      if (fileSizeBytes > 10 * 1024 * 1024) {
        throw const AuthExceptions(message: 'Proof file size exceeds the 10MB limit.');
      }

      final ext = fileName.split('.').last.toLowerCase();
      final uuid = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = '$userId/$uuid.$ext';

      final file = File(filePath);
      await _client.storage.from('membership-documents').upload(
            storagePath,
            file,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      return storagePath;
    } on StorageException catch (e) {
      if (kDebugMode) {
        print('Storage upload error: ${e.message}');
      }
      throw AuthExceptions(message: 'Proof upload failed: ${e.message}');
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: 'File upload error: ${e.toString()}');
    }
  }
}
