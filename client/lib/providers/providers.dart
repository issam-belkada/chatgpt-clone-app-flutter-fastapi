import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider(this._apiService);

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Register
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.register(
        username: username,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.login(
        username: username,
        password: password,
      );
      _isAuthenticated = true;
      await _loadCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load current user
  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Logout
  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _error = null;
    _apiService.clearTokens();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class ConversationProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  String? _error;

  ConversationProvider(this._apiService);

  // Getters
  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _apiService.getConversations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create conversation
  Future<Conversation?> createConversation({
    String title = 'New Conversation',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _apiService.createConversation(title: title);
      _conversations.insert(0, conversation);
      _currentConversation = conversation;
      _isLoading = false;
      notifyListeners();
      return conversation;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Load conversation
  Future<void> loadConversation(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _apiService.getConversation(conversationId);
      _currentConversation = conversation;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update conversation title
  Future<void> updateConversationTitle({
    required int conversationId,
    required String title,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedConversation = await _apiService.updateConversation(
        conversationId: conversationId,
        title: title,
      );

      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = updatedConversation;
      }

      if (_currentConversation?.id == conversationId) {
        _currentConversation = updatedConversation;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete conversation
  Future<void> deleteConversation(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteConversation(conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);

      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  int? _conversationId;

  ChatProvider(this._apiService);

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get conversationId => _conversationId;

  // Send message
  Future<void> sendMessage({
    required String message,
    int? conversationId,
  }) async {
    // Add user message immediately for better UX
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId ?? 0,
      role: 'user',
      content: message,
      createdAt: DateTime.now(),
    );
    _messages.add(userMessage);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final chatResponse = await _apiService.sendMessage(
        message: message,
        conversationId: conversationId ?? _conversationId,
      );

      _conversationId = chatResponse.conversationId;

      // Update conversation ID if it's a new conversation
      if (conversationId == null && _messages.isNotEmpty) {
        _messages[_messages.length - 1] = userMessage.copyWith(
          id: chatResponse.userMessage.id,
          conversationId: chatResponse.conversationId,
        );
      }

      // Add assistant message
      _messages.add(chatResponse.assistantMessage);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      // Remove the user message if sending failed
      _messages.removeWhere((m) => m.id == userMessage.id);
      notifyListeners();
    }
  }

  // Load messages from conversation
  void loadMessages(List<Message> messages, {int? conversationId}) {
    _messages = messages;
    if (conversationId != null) {
      _conversationId = conversationId;
    }
    notifyListeners();
  }

  void setConversationId(int? conversationId) {
    _conversationId = conversationId;
  }

  // Add message
  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  // Clear messages
  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
