import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favori_provider.dart';
import '../widgets/annonce_card.dart';
import 'annonce_detail_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriProvider>().loadFavoris();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
      ),
      body: Consumer<FavoriProvider>(
        builder: (context, favoriProvider, child) {
          if (favoriProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoriProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(favoriProvider.error!),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => favoriProvider.loadFavoris(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (favoriProvider.favoris.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16.0),
                  Text(
                    'Aucun favori',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Ajoutez des annonces à vos favoris',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await favoriProvider.loadFavoris();
            },
            child: ListView.builder(
              itemCount: favoriProvider.favoris.length,
              itemBuilder: (context, index) {
                final favori = favoriProvider.favoris[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnonceDetailScreen(annonceId: favori.annonce.idAnnonce),
                      ),
                    );
                  },
                  child: AnnonceCard(annonce: favori.annonce),
                );
              },
            ),
          );
        },
      ),
    );
  }
}