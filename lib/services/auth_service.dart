import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  /// -----------------------------
  /// AUTHENTICATION
  /// -----------------------------
  Future<AuthResponse> signUp(String email, String password, String username) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() async => await _client.auth.signOut();

  /// -----------------------------
  /// SESSION HELPERS
  /// -----------------------------
  Future<String?> getAccessToken() async {
    return _client.auth.currentSession?.accessToken;
  }

  bool get isAuthenticated => _client.auth.currentSession != null;

  Future<Map<String, dynamic>> fetchUserData() async {
    final token = await getAccessToken();
    if (token == null) return {};

    try {
      final response = await http.get(
        Uri.parse("https://livkit.onrender.com/api/accounts/me2/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching user data from Django: $e");
    }
    return {};
  }

  Future<bool> updateSettings({required String type, required String field, required bool value}) async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse("https://livkit.onrender.com/api/accounts/settings/update/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "type": type,
          "field": field,
          "value": value,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating settings: $e");
      return false;
    }
  }

  Future<bool> updateProfile({required String displayName, required String bio, required String phone}) async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse("https://livkit.onrender.com/api/accounts/profile/update/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "display_name": displayName,
          "bio": bio,
          "phone": phone,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }

  Future<bool> uploadAvatar(String path) async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://livkit.onrender.com/api/accounts/profile/upload-avatar/"),
      );
      request.headers["Authorization"] = "Bearer $token";
      request.files.add(await http.MultipartFile.fromPath('avatar', path));
      
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Error uploading avatar: $e");
      return false;
    }
  }

  Future<String?> getUserId() async {
    return _client.auth.currentUser?.id;
  }

  Future<String?> getUsername() async {
    return _client.auth.currentUser?.userMetadata?['username'] ?? "User";
  }

  /// -----------------------------
  /// PASSWORD RESET
  /// -----------------------------
  Future<void> forgotPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
