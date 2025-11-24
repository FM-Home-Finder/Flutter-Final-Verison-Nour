class User {
  final int idUser;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? photoProfil;
  final DateTime dateCreation;
  final bool isActive;
  final bool isVerified;

  User({
    required this.idUser,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.photoProfil,
    required this.dateCreation,
    required this.isActive,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser: _parseInt(json['id_user']),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'],
      photoProfil: json['photo_profil'] != null 
          ? _parsePhotoUrl(json['photo_profil'])
          : null,
      dateCreation: _parseDateTime(json['date_creation']),
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String? _parsePhotoUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.startsWith('http')) {
        return value;
      } else {
        return 'http://127.0.0.1:8000$value';
      }
    }
    return null;
  }

  String get fullName => '$prenom $nom';
  
  String get initials {
    if (prenom.isEmpty && nom.isEmpty) return '?';
    if (prenom.isEmpty) return nom[0].toUpperCase();
    if (nom.isEmpty) return prenom[0].toUpperCase();
    return '${prenom[0]}${nom[0]}'.toUpperCase();
  }

  bool get hasPhoto => photoProfil != null && photoProfil!.isNotEmpty;

  // AJOUTER CETTE MÉTHODE toJson()
  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'photo_profil': photoProfil,
      'date_creation': dateCreation.toIso8601String(),
      'is_active': isActive,
      'is_verified': isVerified,
    };
  }
}