// mes_annonces_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_annonce_provider.dart';
import '../models/annonce_model.dart';
import '../widgets/annonce_card.dart';
import 'annonce_detail_screen.dart';
import 'edit_annonce_screen.dart';

class MesAnnoncesScreen extends StatefulWidget {
  const MesAnnoncesScreen({super.key});

  @override
  State<MesAnnoncesScreen> createState() => _MesAnnoncesScreenState();
}

class _MesAnnoncesScreenState extends State<MesAnnoncesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserAnnonceProvider>().loadUserAnnonces();
    });
  }

  void _showDeleteDialog(int annonceId, String titre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$titre" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnonce(annonceId);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAnnonce(int annonceId) async {
    final provider = context.read<UserAnnonceProvider>();
    
    try {
      await provider.deleteAnnonce(annonceId);
      
      // Afficher un message de succès
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editAnnonce(Annonce annonce) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAnnonceScreen(annonce: annonce),
      ),
    );
  }

  // CORRECTION : Méthode pour gérer le refresh
  Future<void> _handleRefresh() async {
    await context.read<UserAnnonceProvider>().refresh();
  }

  // CORRECTION : Méthode pour gérer le bouton refresh
  void _handleRefreshButton() async {
    await context.read<UserAnnonceProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Annonces'),
        actions: [
          // CORRECTION : Utiliser la méthode corrigée
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefreshButton,
          ),
        ],
      ),
      body: Consumer<UserAnnonceProvider>(
        builder: (context, userAnnonceProvider, child) {
          if (userAnnonceProvider.isLoading && userAnnonceProvider.userAnnonces.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userAnnonceProvider.error != null && userAnnonceProvider.userAnnonces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    userAnnonceProvider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    // CORRECTION : Utiliser la méthode corrigée
                    onPressed: _handleRefreshButton,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (userAnnonceProvider.userAnnonces.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune annonce publiée',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Créez votre première annonce !',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            // CORRECTION : Utiliser la méthode qui retourne Future<void>
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: userAnnonceProvider.userAnnonces.length,
              itemBuilder: (context, index) {
                final annonce = userAnnonceProvider.userAnnonces[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Stack(
                    children: [
                      // Carte d'annonce
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnnonceDetailScreen(annonceId: annonce.idAnnonce),
                            ),
                          );
                        },
                        child: AnnonceCard(annonce: annonce),
                      ),
                      
                      // Badge "Vos annonces"
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'VOTRE ANNONCE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      // Menu d'actions (modifier/supprimer)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editAnnonce(annonce);
                            } else if (value == 'delete') {
                              _showDeleteDialog(annonce.idAnnonce, annonce.titre);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Indicateur d'état (active/inactive)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: annonce.isActive ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            annonce.isActive ? 'ACTIVE' : 'INACTIVE',
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}