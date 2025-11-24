import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/annonce_provider.dart';
import '../widgets/annonce_card.dart';
import 'annonce_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<AnnonceProvider>().searchAnnonces(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<AnnonceProvider>().clearSearch();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
      ),
      body: Consumer<AnnonceProvider>(
        builder: (context, annonceProvider, child) {
          return Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par titre, ville, description...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),

              // Bouton de recherche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _performSearch,
                    child: const Text('Rechercher'),
                  ),
                ),
              ),

              const SizedBox(height: 16.0),

              // Résultats
              Expanded(
                child: _buildResults(annonceProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResults(AnnonceProvider annonceProvider) {
    if (annonceProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text('Entrez un terme de recherche'),
      );
    }

    if (annonceProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(annonceProvider.error!),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (annonceProvider.searchResults.isEmpty) {
      return const Center(
        child: Text('Aucun résultat trouvé'),
      );
    }

    return ListView.builder(
      itemCount: annonceProvider.searchResults.length,
      itemBuilder: (context, index) {
        final annonce = annonceProvider.searchResults[index];
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}