import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import conditionnel pour le mobile
import 'dart:io' if (dart.library.io) 'dart:io';
import 'package:http_parser/http_parser.dart' if (dart.library.io) 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart' if (dart.library.io) 'package:mime/mime.dart';

class ImageUploadService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Méthode unique qui s'adapte à la plateforme
  Future<Map<String, dynamic>> createAnnonce({
    required Map<String, dynamic> annonceData,
    List<dynamic>? images,
  }) async {
    if (kIsWeb) {
      return _createAnnonceWeb(annonceData: annonceData);
    } else {
      // Pour le mobile
      if (images != null && images.isNotEmpty) {
        return _createAnnonceWithImagesMobile(
          annonceData: annonceData,
          images: images.cast<File>(),
        );
      } else {
        return _createAnnonceWeb(annonceData: annonceData);
      }
    }
  }

  // Méthode privée pour le mobile avec images
  Future<Map<String, dynamic>> _createAnnonceWithImagesMobile({
    required Map<String, dynamic> annonceData,
    required List<File> images,
  }) async {
    // Vérifier si on est sur le web (ne devrait pas arriver avec kIsWeb)
    if (kIsWeb) {
      throw Exception('Upload d\'images non supporté sur le web');
    }

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/annonces'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter les champs de l'annonce
      annonceData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Ajouter les images (uniquement sur mobile)
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        final extension = mimeType.split('/')[1];

        request.files.add(
          await http.MultipartFile.fromPath(
            'photos',
            file.path,
            contentType: MediaType('image', extension),
          ),
        );
      }

      print('📤 Envoi annonce mobile avec ${images.length} images');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Annonce créée avec succès sur mobile');
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la création de l\'annonce');
      }
    } catch (e) {
      print('❌ Erreur création annonce mobile: $e');
      throw Exception('Erreur de création mobile: $e');
    }
  }

  // Méthode pour le web (sans images)
  Future<Map<String, dynamic>> _createAnnonceWeb({
    required Map<String, dynamic> annonceData,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📤 Envoi annonce web sans images');

      final response = await http.post(
        Uri.parse('$baseUrl/annonces'),
        headers: headers,
        body: json.encode(annonceData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Annonce créée avec succès sur web');
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la création de l\'annonce');
      }
    } catch (e) {
      print('❌ Erreur création annonce web: $e');
      throw Exception('Erreur de création web: $e');
    }
  }
}