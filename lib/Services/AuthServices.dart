import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Register user
  Future<String?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String artistName,
    required String phone,
  }) async {
    // 1. Register with Supabase Auth
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );

    final user = response.user;
    if (user == null) {
      return 'Registration failed';
    }

    // 2. Insert extra info into 'users' table
    final insertResponse = await _supabase.from('users').insert({
      'user_id': user.id,
      'email': email.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'artist_name': artistName.trim(),
      'phone': phone.trim(),
    });

    // Check for insert error (for latest supabase_flutter)
    if (insertResponse == null ||
        (insertResponse.status != 201 && insertResponse.status != 200)) {
      return 'Failed to insert user data: ${insertResponse?.toString() ?? "No response"}';
    }

    return null; // Success
  }

  // Login user
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user == null || response.session == null) {
        return 'Login failed. Please check your credentials.';
      }
      return null;
    } on AuthException catch (e) {
      return e.message ?? 'Login failed. Please check your credentials.';
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
