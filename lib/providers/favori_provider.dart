import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/favori_model.dart';

class FavoriProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Favori> _favoris = [];
  bool _isLoading = false;
  String? _error;

  List<Favori> get favoris => _favoris;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFavoris() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _favoris = await _apiService.getFavoris();
    } catch (e) {
      _error = 'Erreur lors du chargement des favoris';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavori(int annonceId) async {
    try {
      final isInFavoris = _favoris.any((f) => f.idAnnonce == annonceId);
      
      if (isInFavoris) {
        await _apiService.removeFavori(annonceId);
        _favoris.removeWhere((f) => f.idAnnonce == annonceId);
      } else {
        await _apiService.addFavori(annonceId);
        // Recharger la liste pour avoir les données complètes
        await loadFavoris();
      }
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la modification des favoris';
      notifyListeners();
    }
  }

  bool isFavori(int annonceId) {
    return _favoris.any((f) => f.idAnnonce == annonceId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}