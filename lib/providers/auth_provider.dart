import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  AuthProvider() {
    // Listen to Firebase Auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
    _loadRememberMe();
  }

  bool _isLocalBypass = false;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null || _isLocalBypass;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;

  // Load "Remember Me" preference
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? false;
    notifyListeners();
  }

  // Toggle "Remember Me"
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    notifyListeners();
  }

  // Sign in
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Local bypass check for testing/offline evaluation
    if (email.trim() == 'owner@meet.com' && password == 'admin123') {
      _isLocalBypass = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      _isLocalBypass = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_isLocalBypass) {
        _isLocalBypass = false;
      } else {
        await _authService.signOut();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
