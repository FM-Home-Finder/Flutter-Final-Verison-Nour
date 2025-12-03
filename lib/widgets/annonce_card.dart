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
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        height: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Partie PHOTO - 2/3 de l'espace
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      color: !hasPhotos ? Colors.grey[200] : null,
                      image: hasPhotos
                          ? DecorationImage(
                              image: NetworkImage(mainImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasPhotos
                        ? const Center(
                            child: Icon(
                              Icons.home_work,
                              size: 50,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                  
                  // Type d'annonce
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        annonce.type == 'vente' ? 'À VENDRE' : 'À LOUER',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavori ? Icons.favorite : Icons.favorite_border,
                          color: isFavori ? Colors.red : Colors.white,
                          size: 18,
                        ),
                        onPressed: () => _toggleFavori(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
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
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        annonce.formattedPrix,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Indicateur de multiples photos
                  if (annonce.photos.length > 1)
                    Positioned(
                      top: 8.0,
                      right: 70.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
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
            ),
            
            // Partie DESCRIPTION - 1/3 de l'espace
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Titre
                    Flexible(
                      child: Text(
                        annonce.titre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Adresse
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              '${annonce.adresse}, ${annonce.ville}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // CORRECTION : Caractéristiques et propriétaire - Solution compacte
                    Container(
                      height: 20, // Hauteur fixe pour cette ligne
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Caractéristiques - version compacte
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Surface - version ultra compacte
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.aspect_ratio, size: 10, color: Colors.grey[600]),
                                      const SizedBox(width: 2.0),
                                      Text(
                                        '${annonce.surface}m²',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 4.0),
                                
                                // Chambres - version ultra compacte
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bed, size: 10, color: Colors.grey[600]),
                                      const SizedBox(width: 2.0),
                                      Text(
                                        '${annonce.chambres}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Photo du propriétaire - version réduite
                          CircleAvatar(
                            radius: 8, // Réduit de 10 à 8
                            backgroundColor: Colors.grey[300],
                            backgroundImage: annonce.proprietaire.hasPhoto
                                ? NetworkImage(annonce.proprietaire.photoProfil!)
                                : null,
                            child: annonce.proprietaire.hasPhoto
                                ? null
                                : Text(
                                    annonce.proprietaire.initials,
                                    style: const TextStyle(
                                      fontSize: 6, // Réduit de 8 à 6
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}