import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/conversation.dart';
import '../config/app_config.dart';
import '../models/message.dart';

class MessageProvider with ChangeNotifier {
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Vider les erreurs
  void _clearError() {
    _error = null;
  }

  // Définir une erreur
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Récupérer la liste des conversations
  Future<void> fetchConversations(String token) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      print('🔄 Chargement des conversations...');
      print('🔗 URL: ${AppConfig.apiUrl}/conversations');
      print('🔑 Token disponible: ${token.isNotEmpty}');
      
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('📊 ${data.length} conversations reçues');
          
          _conversations = data.map((json) => Conversation.fromJson(json)).toList();
          
          // Trier par date du dernier message (le plus récent d'abord)
          _conversations.sort((a, b) {
            final dateA = a.lastMessageDate ?? DateTime(1970);
            final dateB = b.lastMessageDate ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });
          
          print('✅ ${_conversations.length} conversations chargées');
        } catch (e) {
          print('❌ Erreur parsing JSON: $e');
          throw Exception('Format de réponse invalide: $e');
        }
      } else if (response.statusCode == 401) {
        print('❌ Token invalide ou expiré');
        throw Exception('Token invalide ou expiré');
      } else if (response.statusCode == 404) {
        print('❌ Route non trouvée: ${AppConfig.apiUrl}/conversations');
        throw Exception('Route API non trouvée');
      } else {
        print('❌ Erreur serveur: ${response.statusCode}');
        print('Corps de réponse: ${response.body}');
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur fetchConversations: $e');
      _setError('Erreur lors du chargement des conversations: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Récupérer les messages d'une conversation
  Future<void> fetchMessages(String token, int conversationId) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      print('🔄 Chargement des messages pour conversation $conversationId');
      
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/conversations/$conversationId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> items = data['items'] ?? [];
          _messages = items.map((json) => Message.fromJson(json)).toList();
          
          // Trier les messages par date (plus ancien en premier)
          _messages.sort((a, b) => a.dateEnvoi.compareTo(b.dateEnvoi));
          
          print('✅ ${_messages.length} messages chargés');
        } catch (e) {
          print('❌ Erreur parsing messages: $e');
          throw Exception('Format de réponse invalide pour les messages');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Conversation non trouvée');
      } else if (response.statusCode == 401) {
        throw Exception('Token invalide ou expiré');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Erreur lors du chargement des messages: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Envoyer un message
  Future<void> sendMessage(String token, Message message) async {
    _clearError();
    
    try {
      print('🔄 Envoi message: ${message.contenu}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(message.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Message newMessage = Message.fromJson(json.decode(response.body));
          _messages.add(newMessage);
          notifyListeners();
          
          // Mettre à jour la liste des conversations
          await fetchConversations(token);
          
          print('✅ Message envoyé avec succès');
        } catch (e) {
          print('❌ Erreur parsing réponse message: $e');
        }
      } else if (response.statusCode == 400) {
        throw Exception('Données du message invalides');
      } else if (response.statusCode == 401) {
        throw Exception('Token invalide ou expiré');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }

  // Créer une conversation et envoyer le premier message
  // Dans MessageProvider, corrigez la méthode createConversationAndSendMessage
Future<int> createConversationAndSendMessage(String token, int idReceiver, String firstMessage) async {
  _clearError();
  
  try {
    print('🔄 Création conversation avec utilisateur $idReceiver');
    
    // UTILISER application/json au lieu de application/x-www-form-urlencoded
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/conversations/with-message'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // ← CHANGEMENT ICI
      },
      body: json.encode({
        'id_receiver': idReceiver,
        'first_message': firstMessage,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final int conversationId = data['conversation_id'];
      
      print('✅ Conversation créée avec ID: $conversationId');
      
      // Recharger les conversations
      await fetchConversations(token);
      return conversationId;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Erreur lors de la création de la conversation');
    }
  } catch (e) {
    _setError('Erreur lors de la création de la conversation: $e');
    rethrow;
  }
}

// Corrigez aussi la méthode createConversation
Future<int> createConversation(String token, int otherUserId) async {
  _clearError();
  
  try {
    print('🔄 Création conversation directe avec utilisateur $otherUserId');
    
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/conversations/direct'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // ← CHANGEMENT ICI
      },
      body: json.encode({
        'id_user2': otherUserId,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final int conversationId = data['id_conversation'];
      
      print('✅ Conversation créée avec ID: $conversationId');
      
      // Recharger les conversations
      await fetchConversations(token);
      return conversationId;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Erreur lors de la création de la conversation');
    }
  } catch (e) {
    _setError('Erreur lors de la création de la conversation: $e');
    rethrow;
  }
}
  // Récupérer le nombre de messages non lus
  Future<int> getUnreadMessagesCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/messages/unread/count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['unread_count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Erreur lors de la récupération des messages non lus: $e');
      return 0;
    }
  }

  // ... (le reste des méthodes reste inchangé)


  // Marquer les messages comme lus (si l'endpoint existe dans le backend)
  Future<void> markMessagesAsRead(String token, int conversationId) async {
    try {
      // Cette route n'existe pas encore dans votre backend
      // Vous pouvez l'ajouter plus tard
      print('Fonction markMessagesAsRead à implémenter côté backend');
    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  // Vider les messages (utile lors de la déconnexion)
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Vider les conversations (utile lors de la déconnexion)
  void clearConversations() {
    _conversations.clear();
    notifyListeners();
  }

  // Vider toutes les données
  void clearAll() {
    _conversations.clear();
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  // Rechercher une conversation par ID
  Conversation? getConversationById(int conversationId) {
    try {
      return _conversations.firstWhere(
        (conv) => conv.idConversation == conversationId,
      );
    } catch (e) {
      return null;
    }
  }

  // Vérifier si une conversation existe avec un utilisateur
  bool conversationExistsWithUser(int userId) {
    return _conversations.any((conv) => 
      conv.idUser1 == userId || conv.idUser2 == userId
    );
  }

  // Obtenir une conversation avec un utilisateur spécifique
  Conversation? getConversationWithUser(int userId) {
    try {
      return _conversations.firstWhere((conv) => 
        conv.idUser1 == userId || conv.idUser2 == userId
      );
    } catch (e) {
      return null;
    }
  }
}