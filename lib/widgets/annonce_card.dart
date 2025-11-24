import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/annonce_model.dart';
import '../providers/favori_provider.dart';

class AnnonceCard extends StatelessWidget {
  final Annonce annonce;

  const AnnonceCard({super.key, required this.annonce});

  void _toggleFavori(BuildContext context) {
    context.read<FavoriProvider>().toggleFavori(annonce.idAnnonce);
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    } else {
      return 'http://127.0.0.1:8000$imagePath';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavori = context.watch<FavoriProvider>().isFavori(annonce.idAnnonce);
    final hasPhotos = annonce.photos.isNotEmpty;
    final mainImageUrl = hasPhotos ? _getImageUrl(annonce.photos[0]) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  color: !hasPhotos ? Colors.grey[200] : null, // ← CORRECTION ICI
                  image: hasPhotos
                      ? DecorationImage(
                          image: NetworkImage(mainImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null, // ← PLUS de AssetImage!
                ),
                child: !hasPhotos
                    ? const Center(
                        child: Icon(
                          Icons.home_work,
                          size: 64,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
              
              // Type d'annonce (À VENDRE / À LOUER)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    annonce.type == 'vente' ? 'À VENDRE' : 'À LOUER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Bouton favori
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavori ? Icons.favorite : Icons.favorite_border,
                      color: isFavori ? Colors.red : Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _toggleFavori(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ),
              
              // Prix
              Positioned(
                bottom: 8.0,
                left: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    annonce.formattedPrix,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Indicateur de multiples photos
              if (annonce.photos.length > 1)
                Positioned(
                  top: 8.0,
                  right: 80.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      '+${annonce.photos.length - 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annonce.titre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                
                // Adresse
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        '${annonce.adresse}, ${annonce.ville}',
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                
                // Caractéristiques
                Row(
                  children: [
                    _buildFeatureChip(Icons.aspect_ratio, annonce.surfaceText),
                    const SizedBox(width: 8.0),
                    _buildFeatureChip(Icons.bed, annonce.chambresText),
                    const SizedBox(width: 8.0),
                    if (annonce.nombreVues > 0)
                      _buildFeatureChip(Icons.visibility, '${annonce.nombreVues} vues'),
                    const Spacer(),
                    // Photo du propriétaire
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: annonce.proprietaire.hasPhoto
                          ? NetworkImage(annonce.proprietaire.photoProfil!)
                          : null,
                      child: annonce.proprietaire.hasPhoto
                          ? null
                          : Text(
                              annonce.proprietaire.initials,
                              style: const TextStyle(fontSize: 8),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4.0),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}