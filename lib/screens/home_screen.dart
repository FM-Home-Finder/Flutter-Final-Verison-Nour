import 'package:flutter/material.dart';
import 'annonces_screen.dart';
import 'favoris_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'create_annonce_screen.dart';
import 'conversation_list_screen.dart'; // Ajouter cette importation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AnnoncesScreen(),
    const SearchScreen(),
    const FavorisScreen(),
    const ConversationListScreen(), // Remplacer ProfileScreen par Messages
    const ProfileScreen(), // Déplacer ProfileScreen à la fin
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Annonces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message), // Icône pour les messages
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      // Ajouter le bouton flottant pour créer une annonce
      floatingActionButton: _currentIndex == 0 // Afficher seulement sur l'écran Annonces
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateAnnonceScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}