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
    final supabase = Supabase.instance.client;
    try {
      // 1. Register with Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return 'Registration failed: No user returned';
      }

      // 2. Insert into users table
      await supabase.from('users').insert({
        'user_id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'artist_name': artistName,
        'email': email,
        'phone': phone,
      });

      return null; // Success
    } catch (e) {
      return 'Registration failed: $e';
    }
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
