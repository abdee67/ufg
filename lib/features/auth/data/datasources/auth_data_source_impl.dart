import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/core/errors/failures/auth_failures.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source.dart';
import 'package:ufg/features/auth/domain/entities/customer_address_input.dart';

class AuthDataSourceImpl implements AuthDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  //static const String _customerTable = 'customers';
  //static const String _customerColumns =
    //  'id, email, first_name, last_name, phone_number, profile_image_url, '
      //'created_at, updated_at';

  @override
  Future<Session> signIn(String email, String password) async {
    try {
      final result = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (result.session == null) {
        throw const AuthExceptions(
          message: 'We could not start your session. Please try again.',
        );
      }

      final user = result.user ?? _client.auth.currentUser;
      if (user == null) {
        await _signOutQuietly();
        throw const AuthExceptions(
          message: 'We could not find your account. Please try again.',
        );
      }

      return result.session!;
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> signUp(
    String email,
    String password,
    String fullname,
    String phone,
  ) async {
    try {
      final result = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullname, 'phone': phone},
      );
      if (result.user == null) {
        throw const AuthExceptions(
          message: 'We could not create your account. Please try again.',
        );
      }

    /*  await _ensureCustomerProfileFromUser(
        result.user!,
        fallbackEmail: email,
        rethrowErrors: false,
      );*/
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      final result = await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (result.messageId == null) {
        throw const AuthExceptions(
          message: 'We could not send a verification code. Please try again.',
        );
      }
    } catch (_) {
      try {
        await _client.auth.signInWithOtp(
          email: email,
          shouldCreateUser: true,
          data: const {'app_role': 'customer'},
        );
      } catch (error, stackTrace) {
        throw AuthErrorMapper.toException(error, stackTrace);
      }
    }
  }

  @override
  Future<void> verifyOTP(String email, String otp) async {
    try {
      final result = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      if (result.session == null) {
        throw const InvalidOtpException();
      }

      final verifiedUser = result.user ?? _client.auth.currentUser;
      if (verifiedUser == null) {
        throw const InvalidOtpException();
      }


    /*  await _ensureCustomerProfileFromUser(
        verifiedUser,
        fallbackEmail: email,
        rethrowErrors: true,
      );*/
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> verifyPasswordResetOtp(String email, String otp) async {
    try {
      final result = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );
      if (result.session == null) {
        throw const InvalidOtpException();
      }
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }
    @override
  Future<void> forgotPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> resetPassword(String email, String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<String> checkStartupSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null) {
      }
      return 'no_session';
    } catch (e) {
      if (kDebugMode) {
        developer.log("checkUserSession error: ${e.toString()}");
      }
      return 'Something went wrong. Please try again.';
    }
  }

    Future<void> _signOutQuietly() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }


 /* @override
  Future<CustomerModel> getCurrentCustomer() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final response = await _fetchCustomerResponse(user.id);

      if (response != null) {
        final customer = CustomerModel.fromJson(
          Map<String, dynamic>.from(response),
        );
        if (customer.id.isNotEmpty && customer.email.isNotEmpty) {
          return customer;
        }
      }

      final metadata = user.userMetadata ?? <String, dynamic>{};
      final fallbackCustomer = CustomerModel(
        id: user.id,
        email: user.email ?? '',
        firstName: (metadata['first_name'] ?? '').toString(),
        lastName: (metadata['last_name'] ?? '').toString(),
        phone: int.tryParse((metadata['phone_number'] ?? '0').toString()) ?? 0,
      );

      await _ensureCustomerRecord(fallbackCustomer);
      await _ensureCustomerProfileFromUser(
        user,
        fallbackEmail: user.email ?? '',
        rethrowErrors: false,
      );

      final refreshedResponse = await _fetchCustomerResponse(user.id);
      if (refreshedResponse != null) {
        return CustomerModel.fromJson(
          Map<String, dynamic>.from(refreshedResponse),
        );
      }

      return fallbackCustomer;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Error retrieving current customer: $error');
      }
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<CustomerModel> updateCustomerProfile(CustomerModel customer) async {
    try {

      await _client.auth.updateUser(
        UserAttributes(
          email: customer.email,
          data: {
            'first_name': customer.firstName,
            'last_name': customer.lastName,
            'phone_number': customer.phone.toString(),
          },
        ),
      );

      await _client.from(_customerTable).upsert({
        'id': customer.id,
        'email': customer.email,
        'first_name': customer.firstName,
        'last_name': customer.lastName,
        'phone_number': customer.phone,
        'profile_image_url': customer.profileImage,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      return customer;
    } catch (e) {
      throw Exception('Failed to update customer profile: $e');
    }
  }

  Future<void> _ensureCustomerRecord(CustomerModel customer) async {
    try {
      await _client.from(_customerTable).upsert({
        'id': customer.id,
        'email': customer.email,
        'first_name': customer.firstName,
        'last_name': customer.lastName,
        'phone_number': customer.phone,
        'profile_image_url': customer.profileImage,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring customer record: $e');
      }
    }
  }

  Future<void> _ensureCustomerProfileFromUser(
    User user, {
    required String fallbackEmail,
    required bool rethrowErrors,
  }) async {
    try {
      final customer = _customerFromUser(user, fallbackEmail: fallbackEmail);
      await _ensureCustomerRecord(customer);
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring signup customer profile: $e');
      }
      if (rethrowErrors) {
        rethrow;
      }
    }
  }

  CustomerModel _customerFromUser(User user, {required String fallbackEmail}) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};

    return CustomerModel(
      id: user.id,
      email: (user.email ?? fallbackEmail).trim(),
      fullName: (metadata['full_name'] ?? '').toString(),
      phone: int.tryParse((metadata['phone'] ?? '0').toString()) ?? 0,
    );
  }



  Future<dynamic> _fetchCustomerResponse(String userId) async {
    try {
      return await _client
          .from(_customerTable)
          .select(_customerColumns)
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving current customer: $e');
      }
      return null;
    }
  }

*/
}
