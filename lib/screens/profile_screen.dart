import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthProvider>().logout();
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      // TODO: Implémenter l'upload de la photo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonctionnalité d\'upload à implémenter')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Photo de profil avec option de changement
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: user.hasPhoto
                            ? NetworkImage(user.photoProfil!)
                            : null,
                        child: user.hasPhoto
                            ? null
                            : Text(
                                user.initials,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: () => _pickImage(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Nom complet
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Email
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Téléphone
                  if (user.telephone != null)
                    Text(
                      user.telephone!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 32.0),

                  // Informations
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoItem('Membre depuis', _formatDate(user.dateCreation)),
                          
                          _buildInfoItem('Compte actif', user.isActive ? 'Oui' : 'Non'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Boutons d'action
                  Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        text: 'Modifier le profil',
                        onTap: () {
                          // TODO: Naviguer vers l'écran d'édition
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Édition du profil à implémenter')),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.lock,
                        text: 'Changer le mot de passe',
                        onTap: () {
                          // TODO: Naviguer vers l'écran de changement de mot de passe
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Changement de mot de passe à implémenter')),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.home_work,
                        text: 'Mes annonces',
                        onTap: () {
                          // TODO: Naviguer vers l'écran des annonces de l'utilisateur
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mes annonces à implémenter')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}