import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/annonce_provider.dart';
import '../providers/favori_provider.dart';
import '../widgets/image_carousel.dart';

class AnnonceDetailScreen extends StatefulWidget {
  final int annonceId;

  const AnnonceDetailScreen({super.key, required this.annonceId});

  @override
  State<AnnonceDetailScreen> createState() => _AnnonceDetailScreenState();
}

class _AnnonceDetailScreenState extends State<AnnonceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnonceProvider>().getAnnonceById(widget.annonceId);
    });
  }

  void _toggleFavori() {
    context.read<FavoriProvider>().toggleFavori(widget.annonceId);
  }

  void _contactProprietaire() {
    final annonce = context.read<AnnonceProvider>().selectedAnnonce;
    if (annonce == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contacter ${annonce.proprietaire.fullName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Appeler'),
                subtitle: annonce.proprietaire.telephone != null
                    ? Text(annonce.proprietaire.telephone!)
                    : const Text('Non renseigné'),
                onTap: annonce.proprietaire.telephone != null
                    ? () => _launchPhone(annonce.proprietaire.telephone!)
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Envoyer un email'),
                onTap: () => _launchEmail(annonce.proprietaire.email),
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Envoyer un message'),
                onTap: () => _sendMessage(annonce.proprietaire.idUser),
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'application téléphone')),
      );
    }
  }

  void _launchEmail(String email) async {
    final url = 'mailto:$email?subject=À propos de votre annonce';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'application email')),
      );
    }
  }

  void _sendMessage(int userId) {
    // Implémenter l'envoi de message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité message à implémenter')),
    );
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    } else {
      return 'http://127.0.0.1:8000$imagePath';
    }
  }

  String _getUserPhotoUrl(String? photoPath) {
    if (photoPath == null) return '';
    if (photoPath.startsWith('http')) {
      return photoPath;
    } else {
      return 'http://127.0.0.1:8000$photoPath';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AnnonceProvider, FavoriProvider>(
        builder: (context, annonceProvider, favoriProvider, child) {
          if (annonceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (annonceProvider.selectedAnnonce == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Annonce non trouvée',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          final annonce = annonceProvider.selectedAnnonce!;
          final isFavori = favoriProvider.isFavori(annonce.idAnnonce);
          final hasPhotos = annonce.photos.isNotEmpty;
          final processedPhotos = annonce.photos.map(_getImageUrl).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                flexibleSpace: FlexibleSpaceBar(
                  background: hasPhotos
                      ? ImageCarousel(images: processedPhotos)
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_work,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Aucune photo',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavori ? Icons.favorite : Icons.favorite_border,
                      color: isFavori ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavori,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et prix
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              annonce.titre,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            annonce.formattedPrix,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      
                      // Adresse
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              '${annonce.adresse}, ${annonce.ville}${annonce.codePostal != null ? ' ${annonce.codePostal}' : ''}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // Caractéristiques
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFeatureItem(Icons.aspect_ratio, annonce.surfaceText),
                            _buildFeatureItem(Icons.bed, annonce.chambresText),
                            _buildFeatureItem(Icons.visibility, '${annonce.nombreVues} vues'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        annonce.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16.0),

                      // Détails supplémentaires
                      const Text(
                        'Détails',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          children: [
                            _buildDetailItem('Type', annonce.type == 'vente' ? 'Vente' : 'Location'),
                            _buildDetailItem('Surface', annonce.surfaceText),
                            _buildDetailItem('Chambres', annonce.chambresText),
                            _buildDetailItem('Publiée le', _formatDate(annonce.datePublication)),
                            if (annonce.dateModification != annonce.datePublication)
                              _buildDetailItem('Modifiée le', _formatDate(annonce.dateModification)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Propriétaire
                      const Text(
                        'Propriétaire',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: annonce.proprietaire.hasPhoto
                                ? NetworkImage(_getUserPhotoUrl(annonce.proprietaire.photoProfil))
                                : null,
                            child: annonce.proprietaire.hasPhoto
                                ? null
                                : Text(
                                    annonce.proprietaire.initials,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          title: Text(
                            annonce.proprietaire.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(annonce.proprietaire.email),
                              if (annonce.proprietaire.telephone != null)
                                Text(annonce.proprietaire.telephone!),
                            ],
                          ),
                          trailing: const Icon(Icons.contact_mail, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactProprietaire,
        icon: const Icon(Icons.contact_mail),
        label: const Text('Contacter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(height: 4.0),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}