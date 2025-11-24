import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier d'abord si on a un token
      final hasToken = await _apiService.isAuthenticated();
      
      if (hasToken) {
        // Récupérer les infos utilisateur
        final user = await _apiService.getCurrentUser();
        if (user != null) {
          _user = user;
          _isAuthenticated = true;
        } else {
          // Token invalide, déconnecter
          await logout();
        }
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      print('Erreur checkAuthStatus: $e');
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);
      
      if (result['success'] == true) {
        _user = User.fromJson(result['user']);
        _isAuthenticated = true;
        _error = null;
      } else {
        _error = result['message'];
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      _error = 'Erreur de connexion: $e';
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // CORRECTION : Ajout du paramètre photoProfil
Future<void> register(Map<String, dynamic> userData, {XFile? photoProfil}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final result = await _apiService.register(userData, photoProfil: photoProfil);
    
    if (result['success'] == true) {
      // INSCRIPTION RÉUSSIE - CONNECTER AUTOMATIQUEMENT
      _user = User.fromJson(result['user']);
      _isAuthenticated = true; // ← CONNEXION AUTOMATIQUE
      _error = null;
      
      // Sauvegarder la session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(result['user']));
      
      print('✅ Inscription réussie - Utilisateur connecté automatiquement');
      notifyListeners();
    } else {
      _error = result['message'] ?? 'Erreur lors de l\'inscription';
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
    }
  } catch (e) {
    _error = 'Erreur lors de l\'inscription: $e';
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  Future<void> initialize() async {
    await checkAuthStatus();
  }

  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }
  // Dans AuthProvider
Future<void> updateProfile(Map<String, dynamic> userData) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final result = await _apiService.updateProfile(userData);
    
    if (result['success'] == true) {
      _user = User.fromJson(result['user']);
      _error = null;
    } else {
      _error = result['message'];
    }
  } catch (e) {
    _error = 'Erreur lors de la mise à jour: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> updateProfilePhoto(XFile photo) async {
  _isLoading = true;
  notifyListeners();

  try {
    final result = await _apiService.updateProfilePhoto(photo);
    
    if (result['success'] == true) {
      _user = User.fromJson(result['user']);
    }
  } catch (e) {
    _error = 'Erreur lors de la mise à jour de la photo: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  void clearError() {
    _error = null;
    notifyListeners();
  }
}