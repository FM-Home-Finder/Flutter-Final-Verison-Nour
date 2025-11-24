import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/annonce_model.dart';

class AnnonceService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Récupérer toutes les annonces
  Future<List<Annonce>> getAnnonces({
    String? type,
    double? prixMin,
    double? prixMax,
    String? ville,
    String? codePostal,
    int? surfaceMin,
    int? surfaceMax,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = {
        if (type != null) 'type': type,
        if (prixMin != null) 'prix_min': prixMin.toString(),
        if (prixMax != null) 'prix_max': prixMax.toString(),
        if (ville != null) 'ville': ville,
        if (codePostal != null) 'code_postal': codePostal,
        if (surfaceMin != null) 'surface_min': surfaceMin.toString(),
        if (surfaceMax != null) 'surface_max': surfaceMax.toString(),
      };

      final uri = Uri.parse('$baseUrl/annonces').replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => Annonce.fromJson(item)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de chargement des annonces: $e');
    }
  }

  // Récupérer une annonce par ID
  Future<Annonce> getAnnonceById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/annonces/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Annonce.fromJson(data);
      } else {
        throw Exception('Annonce non trouvée');
      }
    } catch (e) {
      throw Exception('Erreur de chargement: $e');
    }
  }

  // Rechercher des annonces
  Future<List<Annonce>> searchAnnonces({
    required String query,
    String? type,
    String? ville,
    double? prixMin,
    double? prixMax,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/annonces/search'),
        headers: headers,
        body: jsonEncode({
          'query': query,
          'type': type,
          'ville': ville,
          'prix_min': prixMin,
          'prix_max': prixMax,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => Annonce.fromJson(item)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de recherche: $e');
    }
  }

  // Créer une annonce
  Future<Annonce> createAnnonce(Map<String, dynamic> annonceData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/annonces'),
        headers: headers,
        body: jsonEncode(annonceData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Annonce.fromJson(data);
      } else {
        throw Exception('Erreur lors de la création');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Mettre à jour une annonce
  Future<Annonce> updateAnnonce(int id, Map<String, dynamic> annonceData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/annonces/$id'),
        headers: headers,
        body: jsonEncode(annonceData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Annonce.fromJson(data);
      } else {
        throw Exception('Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Supprimer une annonce
  Future<void> deleteAnnonce(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/annonces/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Récupérer les annonces de l'utilisateur connecté
  Future<List<Annonce>> getUserAnnonces() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/annonces/user/mes-annonces'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => Annonce.fromJson(item)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de chargement: $e');
    }
  }

  // Récupérer les annonces proches (géolocalisation)
  Future<List<Annonce>> getAnnoncesProches({
    required double latitude,
    required double longitude,
    double distance = 10,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'distance': distance.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/annonces/geolocation/proches').replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Annonce.fromJson(item)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de géolocalisation: $e');
    }
  }
}