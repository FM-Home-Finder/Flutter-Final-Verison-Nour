import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class AppConfig {
  // Détection automatique de l'environnement
  static String get baseUrl {
    // Pour web/Chrome
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    
    // Pour Android emulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    
    // Pour iOS
    if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    
    // Par défaut pour web
    return 'http://127.0.0.1:8000';
  }
  
  static String get apiUrl => '$baseUrl/api';
  
  // Helper pour obtenir les URLs des photos
  static String getPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return ''; // URL vide
    }
    
    // Si c'est déjà une URL complète
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    
    // Si le chemin commence par /
    if (photoPath.startsWith('/')) {
      return '$baseUrl$photoPath';
    }
    
    // Sinon, c'est probablement juste un nom de fichier
    return '$baseUrl/static/uploads/$photoPath';
  }
}