import 'package:dio/dio.dart';
import 'package:ufg/core/api/api_client.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/features/membership/data/models/member_model.dart';
import 'package:ufg/features/membership/data/models/membership_application_model.dart';
import 'package:ufg/features/membership/data/models/profile_model.dart';

abstract class MembershipRemoteDataSource {
  Future<ProfileModel> getCurrentProfile();
  Future<MembershipApplicationModel?> getLatestApplication();
  Future<MemberModel?> getActiveMemberDetails();
  Future<MembershipApplicationModel> submitApplication({
    required String nationalId,
    required String address,
    required DateTime dateOfBirth,
    required String phone,
  });
  Future<void> cancelApplication(String applicationId);
}

class MembershipRemoteDataSourceImpl implements MembershipRemoteDataSource {
  final ApiClient apiClient;

  MembershipRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProfileModel> getCurrentProfile() async {
    try {
      final response = await apiClient.dio.get('/auth/me');
      final data = response.data as Map<String, dynamic>;

      final profileJson = data['profile'] as Map<String, dynamic>;
      final rolesList = <String>[];

      if (data['roles'] is List) {
        for (final r in data['roles']) {
          if (r is Map && r['code'] != null) {
            rolesList.add(r['code'].toString());
          }
        }
      }

      return ProfileModel.fromJson(profileJson, roles: rolesList);
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e);
      throw AuthExceptions(message: errorMsg);
    } catch (e) {
      throw AuthExceptions(message: 'Failed to load profile: $e');
    }
  }

  @override
  Future<MembershipApplicationModel?> getLatestApplication() async {
    try {
      final response = await apiClient.dio.get('/membership/me/application');
      final data = response.data;
      if (data == null || (data is Map && data.isEmpty)) return null;

      return MembershipApplicationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      final errorMsg = _extractErrorMessage(e);
      throw AuthExceptions(message: errorMsg);
    } catch (e) {
      throw AuthExceptions(message: 'Failed to fetch membership application: $e');
    }
  }

  @override
  Future<MemberModel?> getActiveMemberDetails() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return null;

      final memberRes = await SupabaseConfig.client
          .from('members')
          .select()
          .eq('profile_id', user.id)
          .maybeSingle();

      if (memberRes == null) return null;
      return MemberModel.fromJson(memberRes);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<MembershipApplicationModel> submitApplication({
    required String nationalId,
    required String address,
    required DateTime dateOfBirth,
    required String phone,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/membership/applications',
        data: {
          'national_id': nationalId.trim(),
          'address': address.trim(),
          'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
          'phone': phone.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final applicationJson = data['application'] as Map<String, dynamic>;

      return MembershipApplicationModel.fromJson(applicationJson);
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e);
      throw AuthExceptions(message: errorMsg);
    } catch (e) {
      throw AuthExceptions(message: 'Failed to submit application: $e');
    }
  }

  @override
  Future<void> cancelApplication(String applicationId) async {
    try {
      await SupabaseConfig.client
          .from('membership_applications')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);
    } catch (e) {
      throw AuthExceptions(message: 'Failed to cancel application: $e');
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final resData = e.response!.data as Map;
      if (resData['message'] != null) {
        if (resData['message'] is List) {
          return (resData['message'] as List).join(', ');
        }
        return resData['message'].toString();
      }
    }
    return e.message ?? 'Network error occurred. Please check if backend is running.';
  }
}
