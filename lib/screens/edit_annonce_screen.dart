// edit_annonce_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/annonce_provider.dart';
import '../models/annonce_model.dart';

class EditAnnonceScreen extends StatefulWidget {
  final Annonce annonce;

  const EditAnnonceScreen({super.key, required this.annonce});

  @override
  State<EditAnnonceScreen> createState() => _EditAnnonceScreenState();
}

class _EditAnnonceScreenState extends State<EditAnnonceScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    // Pré-remplir les données de l'annonce
    _formData.addAll({
      'titre': widget.annonce.titre,
      'description': widget.annonce.description,
      'type': widget.annonce.type,
      'prix': widget.annonce.prix.toString(),
      'surface': widget.annonce.surface.toString(),
      'chambres': widget.annonce.chambres.toString(),
      'adresse': widget.annonce.adresse,
      'ville': widget.annonce.ville,
      'code_postal': widget.annonce.codePostal ?? '',
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final annonceProvider = context.read<AnnonceProvider>();
      
      try {
        await annonceProvider.updateAnnonce(
          widget.annonce.idAnnonce,
          _formData,
        );

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce modifiée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${annonceProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'annonce'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Titre
              TextFormField(
                initialValue: _formData['titre'],
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un titre';
                  }
                  return null;
                },
                onSaved: (value) => _formData['titre'] = value!,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                initialValue: _formData['description'],
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une description';
                  }
                  return null;
                },
                onSaved: (value) => _formData['description'] = value!,
              ),
              const SizedBox(height: 16),

              // Type
              DropdownButtonFormField<String>(
                value: _formData['type'],
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'vente', child: Text('Vente')),
                  DropdownMenuItem(value: 'location', child: Text('Location')),
                ],
                onChanged: (value) => _formData['type'] = value,
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Prix
              TextFormField(
                initialValue: _formData['prix'],
                decoration: const InputDecoration(
                  labelText: 'Prix (TND) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un prix';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Prix invalide';
                  }
                  return null;
                },
                onSaved: (value) => _formData['prix'] = value!,
              ),
              const SizedBox(height: 16),

              // Surface
              TextFormField(
                initialValue: _formData['surface'],
                decoration: const InputDecoration(
                  labelText: 'Surface (m²) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une surface';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Surface invalide';
                  }
                  return null;
                },
                onSaved: (value) => _formData['surface'] = value!,
              ),
              const SizedBox(height: 16),

              // Chambres
              TextFormField(
                initialValue: _formData['chambres'],
                decoration: const InputDecoration(
                  labelText: 'Nombre de chambres *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le nombre de chambres';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
                onSaved: (value) => _formData['chambres'] = value!,
              ),
              const SizedBox(height: 16),

              // Adresse
              TextFormField(
                initialValue: _formData['adresse'],
                decoration: const InputDecoration(
                  labelText: 'Adresse *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une adresse';
                  }
                  return null;
                },
                onSaved: (value) => _formData['adresse'] = value!,
              ),
              const SizedBox(height: 16),

              // Ville
              TextFormField(
                initialValue: _formData['ville'],
                decoration: const InputDecoration(
                  labelText: 'Ville *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une ville';
                  }
                  return null;
                },
                onSaved: (value) => _formData['ville'] = value!,
              ),
              const SizedBox(height: 16),

              // Code postal
              TextFormField(
                initialValue: _formData['code_postal'],
                decoration: const InputDecoration(
                  labelText: 'Code postal',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _formData['code_postal'] = value ?? '',
              ),
              const SizedBox(height: 24),

              // Bouton de sauvegarde
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Sauvegarder les modifications',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}