import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/annonce_model.dart';
import '../models/favori_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/conversation.dart';
import '../models/message.dart';
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await _prefs;
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // CORRECTION : Méthode register avec support photo
Future<Map<String, dynamic>> register(Map<String, dynamic> userData, {XFile? photoProfil}) async {
  try {
    print('📤 Début inscription avec données: $userData');
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/register'),
    );

    // Ajouter les champs texte
    request.fields['nom'] = userData['nom'] ?? '';
    request.fields['prenom'] = userData['prenom'] ?? '';
    request.fields['email'] = userData['email'] ?? '';
    request.fields['mot_de_passe'] = userData['mot_de_passe'] ?? '';
    
    if (userData['telephone'] != null && userData['telephone'].isNotEmpty) {
      request.fields['telephone'] = userData['telephone'];
    }

    // Ajouter la photo de profil si fournie
    if (photoProfil != null) {
      try {
        final bytes = await photoProfil.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'photo_profil',
          bytes,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      } catch (e) {
        print('❌ Erreur lecture photo: $e');
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 Réponse inscription: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      
      // CONNEXION AUTOMATIQUE APRÈS INSCRIPTION
      print('🔄 Connexion automatique après inscription...');
      final loginResult = await login(userData['email'], userData['mot_de_passe']);
      
      if (loginResult['success'] == true) {
        // Récupérer le vrai token sauvegardé
        final prefs = await _prefs;
        final realToken = prefs.getString('token');
        
        print('✅ Connexion automatique réussie');
        print('🔑 Token réel sauvegardé: ${realToken != null ? "${realToken.substring(0, 20)}..." : "NULL"}');
        
        return {
          'success': true, 
          'user': loginResult['user'],
          'token': realToken // ← Retourner le VRAI token
        };
      } else {
        print('❌ Échec connexion automatique: ${loginResult['message']}');
        return {
          'success': true,
          'user': data,
          'message': 'Inscription réussie mais connexion échouée. Veuillez vous connecter manuellement.'
        };
      }
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['detail'] ?? errorData['message'] ?? 'Erreur lors de l\'inscription';
      return {'success': false, 'message': errorMessage};
    }
  } catch (e) {
    print('❌ Exception inscription: $e');
    return {'success': false, 'message': 'Erreur de connexion: $e'};
  }
}
// Dans ApiService
// Dans votre ApiService class, ajoutez cette méthode publique
Future<String?> getToken() async {
  return await _getToken();
}Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
  try {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié',
      };
    }

    print('🔄 Envoi mise à jour profil: $userData');
    
    // CORRECTION : Enlever le /api en double
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'), // ← CORRECTION ICI : $baseUrl contient déjà /api
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(userData),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return {
        'success': true,
        'user': result,
      };
    } else if (response.statusCode == 404) {
      return {
        'success': false,
        'message': 'Utilisateur non trouvé',
      };
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['detail'] ?? 'Erreur lors de la mise à jour',
      };
    } else {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['detail'] ?? 'Erreur lors de la mise à jour',
      };
    }
  } catch (e) {
    print('Error in updateProfile: $e');
    return {
      'success': false,
      'message': 'Erreur réseau: $e',
    };
  }
}

Future<Map<String, dynamic>> updateProfilePhoto(XFile photo) async {
  try {
    final token = await _getToken(); // Utiliser _getToken() ici aussi
    if (token == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié',
      };
    }

    print('🔄 Upload photo de profil: ${photo.path}');
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/me/upload-photo'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      photo.path,
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('Photo Upload Status: ${response.statusCode}');
    print('Photo Response: $responseBody');

    if (response.statusCode == 200) {
      final result = json.decode(responseBody);
      return {
        'success': true,
        'user': result,
      };
    } else {
      final error = json.decode(responseBody);
      return {
        'success': false,
        'message': error['detail'] ?? 'Erreur lors de l\'upload de la photo',
      };
    }
  } catch (e) {
    print('Error in updateProfilePhoto: $e');
    return {
      'success': false,
      'message': 'Erreur réseau: $e',
    };
  }
}
  // Auth methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'mot_de_passe': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await _prefs;
        await prefs.setString('token', data['access_token']);
        await prefs.setString('user', jsonEncode(data['user']));
        return {'success': true, 'user': data['user']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['detail']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // CORRECTION : Ajout de la méthode getCurrentUser manquante
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await _prefs;
      final userString = prefs.getString('user');
      
      if (userString != null) {
        return User.fromJson(jsonDecode(userString));
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('user', jsonEncode(data));
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Erreur getCurrentUser: $e');
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final prefs = await _prefs;
    final token = prefs.getString('token');
    return token != null;
  }

  // Annonces methods
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

  Future<List<Annonce>> searchAnnonces(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/annonces/search'),
        headers: headers,
        body: jsonEncode({
          'query': query,
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

  Future<List<Favori>> getFavoris() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/favoris'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => Favori.fromJson(item)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de chargement des favoris: $e');
    }
  }

  Future<void> addFavori(int annonceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favoris'),
        headers: headers,
        body: jsonEncode({
          'id_annonce': annonceId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'ajout aux favoris');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  Future<void> removeFavori(int annonceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/favoris/$annonceId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la suppression des favoris');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Méthode pour récupérer les annonces de l'utilisateur
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
      throw Exception('Erreur de chargement des annonces utilisateur: $e');
    }
  }
  Future<void> deleteAnnonce(int annonceId) async {
  try {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/annonces/$annonceId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'annonce');
    }
  } catch (e) {
    throw Exception('Erreur: $e');
  }
}

  // Méthode pour créer une annonce sans images
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
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      throw Exception('Erreur de création d\'annonce: $e');
    }
  }

  // Méthode pour créer une annonce avec images
  Future<Annonce> createAnnonceWithImages({
    required Map<String, dynamic> annonceData,
    required List<dynamic> images,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Créer une requête multipart
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
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        if (image is XFile) {
          final bytes = await image.readAsBytes();
          final multipartFile = http.MultipartFile.fromBytes(
            'photos',
            bytes,
            filename: 'image_$i.jpg',
          );
          request.files.add(multipartFile);
        }
      }

      print('📤 Envoi de ${request.files.length} images');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Annonce.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la création de l\'annonce');
      }
    } catch (e) {
      throw Exception('Erreur de création d\'annonce avec images: $e');
    }
  }
  // Dans votre ApiService - ajoutez cette méthode après la méthode deleteAnnonce

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
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erreur lors de la mise à jour');
    }
  } catch (e) {
    throw Exception('Erreur de mise à jour d\'annonce: $e');
  }
}


  // Méthode helper pour récupérer le token
  Future<String?> _getToken() async {
    final prefs = await _prefs;
    return prefs.getString('token');
  }

  // =============================================
// MESSAGERIE - CONVERSATIONS ET MESSAGES
// =============================================

// Récupérer la liste des conversations
Future<List<Conversation>> getConversations() async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Token invalide ou expiré');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erreur de chargement des conversations: $e');
  }
}

// Récupérer les messages d'une conversation
Future<List<Message>> getMessages(int conversationId) async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((json) => Message.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      throw Exception('Conversation non trouvée');
    } else if (response.statusCode == 401) {
      throw Exception('Token invalide ou expiré');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erreur de chargement des messages: $e');
  }
}

// Envoyer un message
Future<Message> sendMessage({
  required String contenu,
  required int idReceiver,
  int? idConversation,
}) async {
  try {
    final headers = await _getHeaders();
    
    final Map<String, dynamic> messageData = {
      'contenu': contenu,
      'id_receiver': idReceiver,
      if (idConversation != null) 'id_conversation': idConversation,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: headers,
      body: jsonEncode(messageData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Message.fromJson(data);
    } else if (response.statusCode == 400) {
      throw Exception('Données du message invalides');
    } else if (response.statusCode == 401) {
      throw Exception('Token invalide ou expiré');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erreur lors de l\'envoi du message: $e');
  }
}

// Créer une nouvelle conversation
Future<Conversation> createConversation(int idUser2) async {
  try {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: headers,
      body: jsonEncode({
        'id_user2': idUser2,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Conversation.fromJson(data);
    } else if (response.statusCode == 400) {
      throw Exception('Impossible de créer une conversation avec vous-même');
    } else if (response.statusCode == 401) {
      throw Exception('Token invalide ou expiré');
    } else {
      throw Exception('Erreur lors de la création de la conversation');
    }
  } catch (e) {
    throw Exception('Erreur lors de la création de la conversation: $e');
  }
}

// Créer une conversation et envoyer le premier message
Future<int> createConversationAndSendMessage(int idReceiver, String firstMessage) async {
  try {
    // Créer la conversation
    final conversation = await createConversation(idReceiver);
    
    // Envoyer le premier message
    await sendMessage(
      contenu: firstMessage,
      idReceiver: idReceiver,
      idConversation: conversation.idConversation,
    );

    return conversation.idConversation;
  } catch (e) {
    throw Exception('Erreur lors de la création de la conversation: $e');
  }
}

// Récupérer le nombre de messages non lus
Future<int> getUnreadMessagesCount() async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/unread/count'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['unread_count'] ?? 0;
    } else {
      return 0;
    }
  } catch (e) {
    print('Erreur lors de la récupération des messages non lus: $e');
    return 0;
  }
}

// Marquer les messages comme lus (si l'endpoint existe dans le backend)
Future<void> markMessagesAsRead(int conversationId) async {
  try {
    // Cette route n'existe pas encore dans votre backend
    // Vous pouvez l'ajouter plus tard
    print('Fonction markMessagesAsRead à implémenter côté backend');
  } catch (e) {
    print('Erreur lors du marquage des messages comme lus: $e');
  }
}
// Dans ApiService, ajoutez cette méthode après login/register
Future<Map<String, dynamic>> changePassword({
  required String currentPassword,
  required String newPassword,
  required String confirmPassword,
}) async {
  try {
    final token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Utilisateur non authentifié',
      };
    }

    print('🔄 Envoi changement mot de passe');
    
    // Créer une requête multipart
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/users/me/password'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    
    // Ajouter les champs
    request.fields['current_password'] = currentPassword;
    request.fields['new_password'] = newPassword;
    request.fields['confirm_password'] = confirmPassword;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return {
        'success': true,
        'message': result['message'] ?? 'Mot de passe modifié avec succès',
      };
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['detail'] ?? error['message'] ?? 'Erreur lors du changement',
      };
    } else if (response.statusCode == 401) {
      return {
        'success': false,
        'message': 'Token invalide ou expiré',
      };
    } else {
      final error = json.decode(response.body);
      return {
        'success': false,
        'message': error['detail'] ?? 'Erreur serveur',
      };
    }
  } catch (e) {
    print('❌ Erreur changement mot de passe: $e');
    return {
      'success': false,
      'message': 'Erreur réseau: $e',
    };
  }
}
}