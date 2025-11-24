import 'user_model.dart';
class Annonce {
  final int idAnnonce;
  final String titre;
  final String description;
  final String type;
  final double prix;
  final int surface;
  final int chambres;
  final String adresse;
  final String ville;
  final String? codePostal;
  final double? latitude;
  final double? longitude;
  final DateTime datePublication;
  final DateTime dateModification;
  final int idUser;
  final bool isActive;
  final int nombreVues;
  final List<String> photos;
  final User proprietaire;

  Annonce({
    required this.idAnnonce,
    required this.titre,
    required this.description,
    required this.type,
    required this.prix,
    required this.surface,
    required this.chambres,
    required this.adresse,
    required this.ville,
    this.codePostal,
    this.latitude,
    this.longitude,
    required this.datePublication,
    required this.dateModification,
    required this.idUser,
    required this.isActive,
    required this.nombreVues,
    required this.photos,
    required this.proprietaire,
  });

  factory Annonce.fromJson(Map<String, dynamic> json) {
    return Annonce(
      idAnnonce: _parseInt(json['id_annonce']),
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'vente',
      prix: _parseDouble(json['prix']),
      surface: _parseInt(json['surface']),
      chambres: _parseInt(json['chambres'] ?? 0),
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      codePostal: json['code_postal'],
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
      datePublication: _parseDateTime(json['date_publication']),
      dateModification: _parseDateTime(json['date_modification']),
      idUser: _parseInt(json['id_user']),
      isActive: json['is_active'] ?? true,
      nombreVues: _parseInt(json['nombre_vues'] ?? 0),
      photos: _parsePhotos(json['photos']),
      proprietaire: User.fromJson(json['proprietaire'] ?? {}),
    );
  }

  // Méthodes helper pour parser les types
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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

  static List<String> _parsePhotos(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  String get formattedPrix => '${prix.toInt()} €${type == 'location' ? '/mois' : ''}';
  String get surfaceText => '$surface m²';
  String get chambresText => chambres > 0 ? '$chambres chambre${chambres > 1 ? 's' : ''}' : 'Studio';
}