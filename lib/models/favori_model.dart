import 'annonce_model.dart';

class Favori {
  final int idFavori;
  final int idUser;
  final int idAnnonce;
  final DateTime dateAjout;
  final Annonce annonce;

  Favori({
    required this.idFavori,
    required this.idUser,
    required this.idAnnonce,
    required this.dateAjout,
    required this.annonce,
  });

  factory Favori.fromJson(Map<String, dynamic> json) {
    return Favori(
      idFavori: _parseInt(json['id_favori']),
      idUser: _parseInt(json['id_user']),
      idAnnonce: _parseInt(json['id_annonce']),
      dateAjout: _parseDateTime(json['date_ajout']),
      annonce: Annonce.fromJson(json['annonce'] ?? {}),
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
}