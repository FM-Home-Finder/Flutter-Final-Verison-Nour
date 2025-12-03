import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/annonce_provider.dart';
import '../providers/favori_provider.dart';
import '../widgets/image_carousel.dart';
import '../services/api_service.dart';
import '../screens/chat_screen.dart';
import '../providers/message_provider.dart';
import 'dart:convert'; // Pour json.encode/json.decode
import 'package:http/http.dart' as http; // Pour http.post
import '../providers/auth_provider.dart'; // Pour AuthProvider
import '../config/app_config.dart'; // Pour AppConfig
class AnnonceDetailScreen extends StatefulWidget {
  final int annonceId;

  const AnnonceDetailScreen({super.key, required this.annonceId});

  @override
  State<AnnonceDetailScreen> createState() => _AnnonceDetailScreenState();
}

class _AnnonceDetailScreenState extends State<AnnonceDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnonceProvider>().getAnnonceById(widget.annonceId);
    });

    _scrollController.addListener(() {
      setState(() {
        _showAppBarTitle = _scrollController.offset > 100;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFavori() {
    context.read<FavoriProvider>().toggleFavori(widget.annonceId);
  }

  void _contactProprietaire() {
    final annonce = context.read<AnnonceProvider>().selectedAnnonce;
    if (annonce == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Contacter ${annonce.proprietaire.fullName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildContactOption(
                icon: Icons.phone,
                title: 'Appeler',
                subtitle: annonce.proprietaire.telephone ?? 'Non renseigné',
                color: Colors.green,
                onTap: annonce.proprietaire.telephone != null
                    ? () => _launchPhone(annonce.proprietaire.telephone!)
                    : null,
              ),
              const SizedBox(height: 12),
              _buildContactOption(
                icon: Icons.email,
                title: 'Envoyer un email',
                subtitle: annonce.proprietaire.email,
                color: Colors.blue,
                onTap: () => _launchEmail(annonce.proprietaire.email),
              ),
              const SizedBox(height: 12),
              _buildContactOption(
                icon: Icons.message,
                title: 'Envoyer un message',
                subtitle: 'Chat privé',
                color: Colors.purple,
                onTap: () => _sendMessage(annonce.proprietaire.idUser),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showSnackBar('Impossible d\'ouvrir l\'application téléphone');
    }
  }

  void _launchEmail(String email) async {
    final url = 'mailto:$email?subject=À propos de votre annonce';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showSnackBar('Impossible d\'ouvrir l\'application email');
    }
  }
void _sendMessage(int userId) async {
  final annonce = context.read<AnnonceProvider>().selectedAnnonce;
  if (annonce == null) return;

  final authProvider = context.read<AuthProvider>();
  
  if (authProvider.token == null) {
    _showSnackBar('Vous devez être connecté pour envoyer un message');
    return;
  }

  // Fermer le bottom sheet
  Navigator.of(context).pop();

  try {
    final String defaultMessage = "Bonjour, je suis intéressé par votre annonce \"${annonce.titre}\"";

    print('🔄 Envoi message à l\'utilisateur $userId');
    print('📝 Token: ${authProvider.token!.substring(0, 20)}...');
    
    // Utiliser directement la route /api/messages
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/messages'),
      headers: {
        'Authorization': 'Bearer ${authProvider.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'contenu': defaultMessage,
        'id_receiver': userId,
        // Ne pas mettre id_conversation, le backend va la créer automatiquement
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Vérifier si la réponse contient id_conversation
      final conversationId = data['id_conversation'] ?? data['conversation_id'];
      
      if (conversationId == null) {
        throw Exception('Réponse serveur invalide: pas d\'ID de conversation');
      }
      
      if (!mounted) return;
      
      // Naviguer vers l'écran de chat
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserId: userId,
            otherUserName: annonce.proprietaire.fullName,
            otherUserPhoto: annonce.proprietaire.photoProfil,
          ),
        ),
      );
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['detail'] ?? 'Erreur serveur: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  } catch (e) {
    if (!mounted) return;
    print('❌ Erreur lors de l\'envoi du message: $e');
    _showSnackBar('Erreur lors de l\'envoi du message: ${e.toString()}');
  }
}
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
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

  void _showFullScreenImages(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.white, size: 50),
                              SizedBox(height: 16),
                              Text(
                                'Erreur de chargement',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AnnonceProvider, FavoriProvider>(
        builder: (context, annonceProvider, favoriProvider, child) {
          if (annonceProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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

          return Container(
            color: Colors.white,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // AppBar avec image réduite
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.5, // 50% au lieu de 100%
                  flexibleSpace: GestureDetector(
                    onTap: hasPhotos
                        ? () => _showFullScreenImages(processedPhotos, 0)
                        : null,
                    child: FlexibleSpaceBar(
                      background: hasPhotos
                          ? ImageCarousel(
                              images: processedPhotos,
                              height: MediaQuery.of(context).size.height * 0.5, // Même hauteur
                              onImageTap: (index) => _showFullScreenImages(processedPhotos, index),
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.home_work,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Aucune photo disponible',
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
                  ),
                  pinned: true,
                  floating: true,
                  title: _showAppBarTitle
                      ? Text(
                          annonce.formattedPrix,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  backgroundColor: Colors.transparent,
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavori ? Icons.favorite : Icons.favorite_border,
                          color: isFavori ? Colors.red : Colors.white,
                        ),
                        onPressed: _toggleFavori,
                      ),
                    ),
                  ],
                ),

                // Le reste de votre contenu reste inchangé...
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // VOTRE CONTENU EXISTANT (identique à votre code)...
                          // En-tête avec prix et type
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: annonce.type == 'vente'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  annonce.type == 'vente' ? 'À VENDRE' : 'À LOUER',
                                  style: TextStyle(
                                    color: annonce.type == 'vente'
                                        ? Colors.green
                                        : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
                          const SizedBox(height: 16),

                          // Titre
                          Text(
                            annonce.titre,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Adresse
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${annonce.adresse}, ${annonce.ville}${annonce.codePostal != null ? ' ${annonce.codePostal}' : ''}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Caractéristiques principales
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildFeatureItem(
                                  icon: Icons.aspect_ratio,
                                  value: annonce.surfaceText,
                                  label: 'Surface',
                                ),
                                _buildFeatureItem(
                                  icon: Icons.bed,
                                  value: annonce.chambresText,
                                  label: 'Chambres',
                                ),
                                _buildFeatureItem(
                                  icon: Icons.visibility,
                                  value: '${annonce.nombreVues}',
                                  label: 'Vues',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            annonce.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Color.fromRGBO(66, 66, 66, 1),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Détails techniques
                          const Text(
                            'Détails du bien',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                    'Type', annonce.type == 'vente' ? 'Vente' : 'Location'),
                                const Divider(),
                                _buildDetailRow('Surface', annonce.surfaceText),
                                const Divider(),
                                _buildDetailRow('Chambres', annonce.chambresText),
                                const Divider(),
                                _buildDetailRow(
                                    'Publiée le', _formatDate(annonce.datePublication)),
                                if (annonce.dateModification != annonce.datePublication) ...[
                                  const Divider(),
                                  _buildDetailRow('Modifiée le',
                                      _formatDate(annonce.dateModification)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Propriétaire
                          const Text(
                            'Propriétaire',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: annonce.proprietaire.hasPhoto
                                        ? NetworkImage(_getUserPhotoUrl(
                                            annonce.proprietaire.photoProfil))
                                        : null,
                                    backgroundColor: annonce.proprietaire.hasPhoto
                                        ? Colors.transparent
                                        : Colors.blue,
                                    child: annonce.proprietaire.hasPhoto
                                        ? null
                                        : Text(
                                            annonce.proprietaire.initials,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          annonce.proprietaire.fullName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          annonce.proprietaire.email,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (annonce.proprietaire.telephone != null)
                                          Text(
                                            annonce.proprietaire.telephone!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.verified, color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _contactProprietaire,
          icon: const Icon(Icons.contact_mail, size: 24),
          label: const Text(
            'Contacter',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}