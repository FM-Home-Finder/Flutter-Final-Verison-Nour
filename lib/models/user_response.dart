class UserResponse {
  final int idUser;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? photoProfil;
  final DateTime dateCreation;
  final bool isVerified;

  UserResponse({
    required this.idUser,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.photoProfil,
    required this.dateCreation,
    required this.isVerified,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      idUser: json['id_user'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      telephone: json['telephone'],
      photoProfil: json['photo_profil'],
      dateCreation: DateTime.parse(json['date_creation']),
      isVerified: json['is_verified'] ?? false,
    );
  }

  // Getters utiles
  String get fullName => '$prenom $nom';
  
  String get initials {
    if (prenom.isEmpty && nom.isEmpty) return '?';
    if (prenom.isEmpty) return nom.substring(0, 1).toUpperCase();
    if (nom.isEmpty) return prenom.substring(0, 1).toUpperCase();
    return '${prenom.substring(0, 1)}${nom.substring(0, 1)}'.toUpperCase();
  }

  bool get hasPhoto => photoProfil != null && photoProfil!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'photo_profil': photoProfil,
      'date_creation': dateCreation.toIso8601String(),
      'is_verified': isVerified,
    };
  }
}