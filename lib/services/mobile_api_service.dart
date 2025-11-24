import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/annonce_model.dart';

class MobileApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Annonce> createAnnonceWithImages({
    required Map<String, dynamic> annonceData,
    required List<dynamic> images,
  }) async {
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

      // Ajouter les images
      for (final image in images) {
        if (image is File) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photos',
              image.path,
            ),
          );
        }
      }

      print('📤 Envoi annonce mobile avec ${images.length} images');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Annonce créée avec succès sur mobile');
        return Annonce.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la création de l\'annonce');
      }
    } catch (e) {
      print('❌ Erreur création annonce mobile: $e');
      throw Exception('Erreur de création mobile: $e');
    }
  }

  Future<User> uploadProfilePhoto(dynamic imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      if (imageFile is! File) {
        throw Exception('Type de fichier non supporté');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/me/upload-photo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo_profil',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Mettre à jour le cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data));
        return User.fromJson(data);
      } else {
        throw Exception('Erreur lors de l\'upload de la photo');
      }
    } catch (e) {
      throw Exception('Erreur upload photo: $e');
    }
  }

  Future<void> uploadAnnoncePhotos(int annonceId, List<dynamic> images) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/annonces/$annonceId/photos'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter les images
      for (final image in images) {
        if (image is File) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photos',
              image.path,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'upload des photos');
      }
    } catch (e) {
      throw Exception('Erreur upload photos annonce: $e');
    }
  }
}