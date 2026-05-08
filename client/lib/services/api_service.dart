import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://192.168.177.171:8000/api/v1';
  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  String? _accessToken;
  String? _refreshToken;

  // Getters
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

  // Set tokens
  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  // Clear tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // Helper method for making authenticated requests
  Map<String, String> _getHeaders({bool isMultipart = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================

  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }

      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        setTokens(authResponse.accessToken, authResponse.refreshToken);
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get current user');
      }
    } catch (e) {
      throw Exception('Get current user error: $e');
    }
  }

  // ============================================================================
  // CONVERSATION ENDPOINTS
  // ============================================================================

  Future<List<Conversation>> getConversations({
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations?skip=$skip&limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Conversation.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      throw Exception('Get conversations error: $e');
    }
  }

  Future<Conversation> createConversation({
    String title = 'New Conversation',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations'),
        headers: _getHeaders(),
        body: jsonEncode({
          'title': title,
        }),
      );

      if (response.statusCode == 200) {
        return Conversation.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create conversation');
      }
    } catch (e) {
      throw Exception('Create conversation error: $e');
    }
  }

  Future<Conversation> getConversation(int conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Conversation.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load conversation');
      }
    } catch (e) {
      throw Exception('Get conversation error: $e');
    }
  }

  Future<Conversation> updateConversation({
    required int conversationId,
    required String title,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/conversations/$conversationId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'title': title,
        }),
      );

      if (response.statusCode == 200) {
        return Conversation.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update conversation');
      }
    } catch (e) {
      throw Exception('Update conversation error: $e');
    }
  }

  Future<void> deleteConversation(int conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/conversations/$conversationId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete conversation');
      }
    } catch (e) {
      throw Exception('Delete conversation error: $e');
    }
  }

  // ============================================================================
  // CHAT ENDPOINTS
  // ============================================================================

  Future<ChatResponse> sendMessage({
    required String message,
    int? conversationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: _getHeaders(),
        body: jsonEncode({
          'message': message,
          'conversation_id': conversationId,
        }),
      );

      if (response.statusCode == 200) {
        return ChatResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Send message error: $e');
    }
  }
}
