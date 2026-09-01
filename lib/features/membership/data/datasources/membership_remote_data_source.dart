import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/features/membership/data/models/member_model.dart';
import 'package:ufg/features/membership/data/models/membership_application_model.dart';

/// Data source that talks directly to Supabase Database, Storage, and RPC.
abstract class MembershipRemoteDataSource {
  Future<MembershipApplicationModel?> getMyApplication();
  Future<MemberModel?> getMyMemberDetails();
  Future<String> uploadFaydaDocument({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });
  Future<MembershipApplicationModel> submitApplication({
    required String address,
    required DateTime dateOfBirth,
    required String phone,
    required String storagePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });
  Future<void> cancelApplication(String applicationId);
}

class MembershipRemoteDataSourceImpl implements MembershipRemoteDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthExceptions(message: 'Not authenticated.');
    }
    return user.id;
  }

  @override
  Future<MembershipApplicationModel?> getMyApplication() async {
    try {
      final userId = _currentUserId;

      final response = await _client
          .from('membership_applications')
          .select()
          .eq('applicant_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return MembershipApplicationModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (e) {
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<MemberModel?> getMyMemberDetails() async {
    try {
      final userId = _currentUserId;

      final response = await _client
          .from('members')
          .select()
          .eq('profile_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) return null;
      return MemberModel.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<String> uploadFaydaDocument({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      final userId = _currentUserId;

      // Max 10MB
      if (fileSizeBytes > 10 * 1024 * 1024) {
        throw const AuthExceptions(
          message: 'Document size exceeds the 10MB limit.',
        );
      }

      // Validate MIME type
      const allowedTypes = [
        'image/jpeg',
        'image/jpg',
        'image/png',
        'image/webp',
        'application/pdf',
      ];
      if (!allowedTypes.contains(mimeType.toLowerCase())) {
        throw AuthExceptions(
          message:
              'Unsupported document type: $mimeType. Please upload a JPEG, PNG, WebP, or PDF file.',
        );
      }

      // Generate UUID-based path scoped to user ID
      final ext = fileName.split('.').last.toLowerCase();
      final uuid = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = '$userId/$uuid.$ext';

      final file = File(filePath);
      await _client.storage
          .from('membership-documents')
          .upload(
            storagePath,
            file,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      return storagePath;
    } on StorageException catch (e) {
      if (kDebugMode) {
        print('Storage upload error: ${e.message}');
      }
      throw AuthExceptions(message: 'Storage upload failed: ${e.message}');
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: 'File upload error: ${e.toString()}');
    }
  }

  @override
  Future<MembershipApplicationModel> submitApplication({
    required String address,
    required DateTime dateOfBirth,
    required String phone,
    required String storagePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      final response = await _client.rpc(
        'submit_membership_application',
        params: {
          'p_address': address,
          'p_date_of_birth': dateOfBirth.toIso8601String().split('T').first,
          'p_phone': phone,
          'p_storage_path': storagePath,
          'p_file_name': fileName,
          'p_mime_type': mimeType,
          'p_file_size_bytes': fileSizeBytes,
        },
      );

      if (kDebugMode) {
        print('Membership application submitted successfully: $response');
      }

      if (response == null) {
        throw const AuthExceptions(
          message: 'Failed to submit membership application.',
        );
      }

      return MembershipApplicationModel.fromRpcJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC submit_membership_application error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<void> cancelApplication(String applicationId) async {
    try {
      await _client
          .from('membership_applications')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', applicationId)
          .eq('applicant_id', _currentUserId);
    } on PostgrestException catch (e) {
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }
}
