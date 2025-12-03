import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/annonce_provider.dart';
import '../widgets/annonce_card.dart';
import 'annonce_detail_screen.dart';

class AnnoncesScreen extends StatefulWidget {
  const AnnoncesScreen({super.key});

  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  String? _selectedType;
  String? _selectedVille;

  @override
  void initState() {
    super.initState();
    _loadAnnonces();
  }

  void _loadAnnonces() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnonceProvider>().loadAnnonces(
        type: _selectedType,
        ville: _selectedVille,
      );
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'vente', child: Text('Vente')),
                      DropdownMenuItem(value: 'location', child: Text('Location')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Ville
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedVille = value.isNotEmpty ? value : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = null;
                              _selectedVille = null;
                            });
                          },
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _loadAnnonces();
                          },
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces Immobilières'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Consumer<AnnonceProvider>(
        builder: (context, annonceProvider, child) {
          if (annonceProvider.isLoading && annonceProvider.annonces.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (annonceProvider.error != null && annonceProvider.annonces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(annonceProvider.error!),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loadAnnonces,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (annonceProvider.annonces.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work, size: 64, color: Colors.grey),
                  SizedBox(height: 16.0),
                  Text(
                    'Aucune annonce disponible',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Essayez de modifier vos filtres',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<AnnonceProvider>().loadAnnonces();
            },
            child: RefreshIndicator(
  onRefresh: () async {
    await context.read<AnnonceProvider>().loadAnnonces();
  },
  child: GridView.builder(
    padding: const EdgeInsets.all(16.0),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, // 2 annonces par ligne
      crossAxisSpacing: 16.0, // Espacement horizontal
      mainAxisSpacing: 16.0, // Espacement vertical
      childAspectRatio: 0.7, // Ajustez ce ratio selon vos besoins
    ),
    itemCount: annonceProvider.annonces.length,
    itemBuilder: (context, index) {
      final annonce = annonceProvider.annonces[index];
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnonceDetailScreen(annonceId: annonce.idAnnonce),
            ),
          );
        },
        child: AnnonceCard(annonce: annonce),
      );
    },
  ),
),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}