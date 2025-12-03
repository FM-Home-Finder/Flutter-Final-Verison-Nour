// lib/utils/image_utils.dart
import 'package:flutter/material.dart';

class ImageUtils {
  static String getFullPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return '';
    }
    
    if (photoPath.startsWith('http')) {
      return photoPath;
    } else if (photoPath.startsWith('/static/')) {
      return 'http://localhost:8000$photoPath';
    } else if (photoPath.startsWith('static/')) {
      return 'http://localhost:8000/$photoPath';
    } else {
      return 'http://localhost:8000/static/uploads/$photoPath';
    }
  }

  static String getInitials(String? prenom, String? nom) {
    final first = prenom?.isNotEmpty == true ? prenom![0] : '';
    final last = nom?.isNotEmpty == true ? nom![0] : '';
    final initials = (first + last).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  static String getUserFullName(String? prenom, String? nom) {
    if (prenom == null && nom == null) return 'Utilisateur';
    if (prenom == null) return nom!;
    if (nom == null) return prenom;
    return '$prenom $nom';
  }

  static Widget buildUserAvatar({
    required String? photoProfil,
    required String? prenom,
    required String? nom,
    double radius = 20,
  }) {
    final initials = getInitials(prenom, nom);
    
    if (photoProfil != null && photoProfil.isNotEmpty) {
      final photoUrl = getFullPhotoUrl(photoProfil);
      return CircleAvatar(
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: Colors.transparent,
        radius: radius,
        onBackgroundImageError: (exception, stackTrace) {
          print('❌ Erreur chargement avatar: $exception');
        },
        child: Container(), // Vide pour éviter les erreurs
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.blue,
        radius: radius,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.5,
          ),
        ),
      );
    }
  }
}