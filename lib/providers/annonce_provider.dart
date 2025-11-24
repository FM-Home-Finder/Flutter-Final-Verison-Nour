import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/annonce_model.dart';
import 'package:http/http.dart' as http;

class AnnonceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Annonce> _annonces = [];
  List<Annonce> _searchResults = [];
  Annonce? _selectedAnnonce;
  bool _isLoading = false;
  String? _error;

  List<Annonce> get annonces => _annonces;
  List<Annonce> get searchResults => _searchResults;
  Annonce? get selectedAnnonce => _selectedAnnonce;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAnnonces({
    String? type,
    double? prixMin,
    double? prixMax,
    String? ville,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _annonces = await _apiService.getAnnonces(
        type: type,
        prixMin: prixMin,
        prixMax: prixMax,
        ville: ville,
      );
    } catch (e) {
      _error = 'Erreur lors du chargement des annonces: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchAnnonces(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchAnnonces(query);
    } catch (e) {
      _error = 'Erreur lors de la recherche: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAnnonceById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedAnnonce = await _apiService.getAnnonceById(id);
    } catch (e) {
      _error = 'Erreur lors du chargement de l\'annonce: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CORRECTION : Méthode pour créer une annonce avec images
  Future<void> createAnnonceWithImages({
  required Map<String, dynamic> annonceData,
  required List<XFile> images,
}) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Récupérer le token depuis SharedPreferences
    final token = await _getToken();
    
    if (token == null || token.isEmpty) {
      _error = 'Vous devez être connecté pour créer une annonce';
      throw Exception(_error);
    }

    print('🔑 Token utilisé: ${token.substring(0, 20)}...');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:8000/api/annonces/with-images'),
    );

    // Ajouter le token d'authentification
    request.headers['Authorization'] = 'Bearer $token';

    // Ajouter les champs du formulaire
    request.fields.addAll({
      'titre': annonceData['titre'],
      'description': annonceData['description'],
      'type': annonceData['type'],
      'prix': annonceData['prix'].toString(),
      'surface': annonceData['surface'].toString(),
      'chambres': annonceData['chambres'].toString(),
      'adresse': annonceData['adresse'],
      'ville': annonceData['ville'],
      if (annonceData['code_postal'] != null && annonceData['code_postal'].isNotEmpty)
        'code_postal': annonceData['code_postal'],
    });

    print('📝 Données envoyées: ${request.fields}');

    // CORRECTION : Convertir les XFile en MultipartFile
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      print('📸 Traitement image $i: ${image.name}');
      
      try {
        // Lire les bytes de l'image
        final bytes = await image.readAsBytes();
        print('📊 Bytes lus: ${bytes.length}');
        
        // Déterminer l'extension du fichier
        String extension = 'jpg';
        if (image.name.toLowerCase().endsWith('.png')) {
          extension = 'png';
        } else if (image.name.toLowerCase().endsWith('.jpeg')) {
          extension = 'jpeg';
        } else if (image.name.toLowerCase().endsWith('.gif')) {
          extension = 'gif';
        } else if (image.name.toLowerCase().endsWith('.webp')) {
          extension = 'webp';
        }
        
        final filename = 'image_$i.$extension';
        
        // Créer le MultipartFile
        final multipartFile = http.MultipartFile.fromBytes(
          'images', // Doit correspondre au nom dans le backend
          bytes,
          filename: filename,
        );
        
        request.files.add(multipartFile);
        print('✅ Image $i ajoutée: $filename (${bytes.length} bytes)');
        
      } catch (e) {
        print('❌ Erreur lecture image $i: $e');
        // Continuer avec les autres images
      }
    }

    print('📤 Envoi de l\'annonce avec ${request.files.length} images...');

    // Envoyer la requête
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 Réponse serveur: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      _error = null;
      print('✅ Annonce créée avec succès avec ${request.files.length} images');
      
      // Recharger la liste des annonces
      await loadAnnonces();
    } else if (response.statusCode == 401) {
      _error = 'Session expirée. Veuillez vous reconnecter.';
      print('❌ Erreur d\'authentification: ${response.body}');
      throw Exception(_error);
    } else {
      _error = 'Erreur ${response.statusCode}: ${response.body}';
      print('❌ Erreur serveur: $_error');
      throw Exception(_error);
    }
  } catch (e) {
    _error = 'Erreur lors de la création: $e';
    print('❌ Exception: $_error');
    throw Exception(_error);
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  // Méthode pour créer une annonce sans images
  Future<void> createAnnonce(Map<String, dynamic> annonceData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAnnonce = await _apiService.createAnnonce(annonceData);
      _annonces.insert(0, newAnnonce);
      _error = null;
    } catch (e) {
      _error = 'Erreur lors de la création de l\'annonce: $e';
      print('Erreur détaillée: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CORRECTION : Méthode pour récupérer le token depuis SharedPreferences
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('❌ Aucun token trouvé dans SharedPreferences');
        return null;
      }
      
      print('✅ Token récupéré (${token.length} caractères)');
      return token;
    } catch (e) {
      print('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    _annonces = [];
    _searchResults = [];
    _selectedAnnonce = null;
    _error = null;
    loadAnnonces();
  }
}