// user_annonce_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/annonce_model.dart';

class UserAnnonceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Annonce> _userAnnonces = [];
  bool _isLoading = false;
  String? _error;

  List<Annonce> get userAnnonces => _userAnnonces;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserAnnonces() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userAnnonces = await _apiService.getUserAnnonces();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement de vos annonces: $e';
      print('Erreur loadUserAnnonces: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAnnonce(int annonceId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.deleteAnnonce(annonceId);
      
      // Supprimer de la liste locale
      _userAnnonces.removeWhere((annonce) => annonce.idAnnonce == annonceId);
      _error = null;
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      print('Erreur deleteAnnonce: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // CORRECTION : Retourner Future<void> au lieu de void
  Future<void> refresh() async {
    _userAnnonces = [];
    _error = null;
    await loadUserAnnonces(); // Ajouter await
  }
}