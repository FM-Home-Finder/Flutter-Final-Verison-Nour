import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  String? _token; // AJOUTEZ cette variable
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // AJOUTEZ ce getter
  String? get token => _token;

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
        // Récupérer le token
        _token = await _apiService.getToken(); // AJOUTEZ cette ligne
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
        _token = null; // AJOUTEZ cette ligne
      }
    } catch (e) {
      print('Erreur checkAuthStatus: $e');
      _isAuthenticated = false;
      _user = null;
      _token = null; // AJOUTEZ cette ligne
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
        // AJOUTEZ cette ligne pour sauvegarder le token
        _token = await _apiService.getToken();
      } else {
        _error = result['message'];
        _isAuthenticated = false;
        _user = null;
        _token = null; // AJOUTEZ cette ligne
      }
    } catch (e) {
      _error = 'Erreur de connexion: $e';
      _isAuthenticated = false;
      _user = null;
      _token = null; // AJOUTEZ cette ligne
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, dynamic> userData, {XFile? photoProfil}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.register(userData, photoProfil: photoProfil);
      
      if (result['success'] == true) {
        _user = User.fromJson(result['user']);
        _isAuthenticated = true;
        _error = null;
        // AJOUTEZ cette ligne pour sauvegarder le token
        _token = result['token']; // Le token est retourné par ApiService.register
      } else {
        _error = result['message'] ?? 'Erreur lors de l\'inscription';
        _isAuthenticated = false;
        _user = null;
        _token = null; // AJOUTEZ cette ligne
      }
    } catch (e) {
      _error = 'Erreur lors de l\'inscription: $e';
      _isAuthenticated = false;
      _user = null;
      _token = null; // AJOUTEZ cette ligne
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    _isAuthenticated = false;
    _token = null; // AJOUTEZ cette ligne
    _error = null;
    notifyListeners();
  }

  // ... le reste de vos méthodes reste inchangé ...


  Future<void> initialize() async {
    await checkAuthStatus();
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
// Dans AuthProvider, ajoutez cette méthode après updateProfilePhoto
Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
  required String confirmPassword,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final result = await _apiService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    
    if (result['success'] == true) {
      _error = null;
      // Succès - vous pouvez ajouter une notification ou autre
    } else {
      _error = result['message'];
    }
  } catch (e) {
    _error = 'Erreur lors du changement de mot de passe: $e';
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