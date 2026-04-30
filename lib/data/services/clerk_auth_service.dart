import 'package:clerk_flutter/clerk_flutter.dart';
import 'api_service.dart';

class ClerkAuthService {
  final ApiService _api = ApiService();

  // Initialize Clerk
  static Future<void> initialize() async {
    await Clerk.initialize(
      publishableKey: 'your-clerk-publishable-key',
    );
  }

  // Get current user
  Future<ClerkUser?> getCurrentUser() async {
    try {
      return await Clerk.session?.user;
    } catch (e) {
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final session = await Clerk.session;
      return session != null;
    } catch (e) {
      return false;
    }
  }

  // Sign in with email/password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final signIn = await Clerk.client.signIn.create(
        identifier: email,
        password: password,
      );

      // Store Clerk token
      final token = await signIn.createdSessionId;
      if (token != null) {
        await _api.setToken(token);
      }

      return {
        'success': true,
        'userId': signIn.userId,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sign up
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await Clerk.client.signUp.create(
        emailAddress: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      // Prepare email verification
      await Clerk.client.signUp.prepareVerification(
        strategy: PrepareStrategy.emailCode,
      );

      return {
        'success': true,
        'message': 'Verification email sent',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Verify email code
  Future<Map<String, dynamic>> verifyEmail({
    required String code,
  }) async {
    try {
      final signUp = await Clerk.client.signUp.attemptVerification(
        strategy: AttemptStrategy.emailCode,
        code: code,
      );

      // Store token
      final token = await signUp.createdSessionId;
      if (token != null) {
        await _api.setToken(token);
      }

      return {
        'success': true,
        'userId': signUp.userId,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Clerk.client.signOut();
      await _api.clearToken();
    } catch (e) {
      // Still clear token
      await _api.clearToken();
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      await Clerk.client.signIn.create(
        identifier: email,
        strategy: PrepareStrategy.resetPasswordEmailCode,
      );

      return {
        'success': true,
        'message': 'Reset email sent',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
  }) async {
    try {
      final user = await Clerk.session?.user;
      if (user != null) {
        await user.update(
          firstName: firstName,
          lastName: lastName,
          username: username,
        );
        return {'success': true};
      }
      return {'success': false, 'error': 'No user found'};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = await Clerk.session?.user;
      if (user != null) {
        await user.delete();
        await _api.clearToken();
        return {'success': true};
      }
      return {'success': false, 'error': 'No user found'};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
