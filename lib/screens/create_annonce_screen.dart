import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/annonce_provider.dart';

class CreateAnnonceScreen extends StatefulWidget {
  const CreateAnnonceScreen({super.key});

  @override
  State<CreateAnnonceScreen> createState() => _CreateAnnonceScreenState();
}

class _CreateAnnonceScreenState extends State<CreateAnnonceScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final bool _isWeb = kIsWeb;
  bool _isSubmitting = false;

  // Contrôleurs pour les champs
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _chambresController = TextEditingController(text: '0');
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();

  String _selectedType = 'vente';

  Future<void> _pickImages() async {
    try {
      if (_isWeb) {
        // Sur le web, utiliser pickImage avec source gallery
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });
        }
      } else {
        // Sur mobile, utiliser pickMultiImage
        final List<XFile>? images = await _picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );

        if (images != null && images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection des images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      _formKey.currentState!.save();
      _createAnnonce();
    }
  }

  Future<void> _createAnnonce() async {
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Préparer les données pour l'API
      final annonceData = {
        'titre': _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'prix': double.parse(_prixController.text),
        'surface': int.parse(_surfaceController.text),
        'chambres': int.parse(_chambresController.text),
        'adresse': _adresseController.text.trim(),
        'ville': _villeController.text.trim(),
        'code_postal': _codePostalController.text.trim().isNotEmpty 
            ? _codePostalController.text.trim()
            : null,
      };

      print('📤 Création annonce avec ${_selectedImages.length} images');

      // Créer l'annonce via le provider
      final annonceProvider = context.read<AnnonceProvider>();
      
      // Utiliser la même méthode pour web et mobile
      await annonceProvider.createAnnonceWithImages(
        annonceData: annonceData,
        images: _selectedImages,
      );
      
      if (annonceProvider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce créée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${annonceProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos de l\'annonce',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _isWeb 
            ? 'Ajoutez des photos depuis votre galerie'
            : 'Ajoutez au moins une photo pour rendre votre annonce plus attractive',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),

        _buildImageGrid(),
        const SizedBox(height: 16),

        // Bouton pour ajouter des photos
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: Text(_isWeb ? 'Ajouter une photo' : 'Ajouter des photos'),
            onPressed: _pickImages,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Aucune image sélectionnée',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return FutureBuilder<Uint8List>(
          future: _getImageData(_selectedImages[index]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: MemoryImage(snapshot.data!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        );
      },
    );
  }

  // Méthode simplifiée pour afficher les images
  Future<Uint8List> _getImageData(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    return bytes;
  }

  // Champs du formulaire (inchangé)
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        TextFormField(
          controller: _titreController,
          decoration: const InputDecoration(
            labelText: 'Titre de l\'annonce *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un titre';
            }
            if (value.length < 5) {
              return 'Le titre doit faire au moins 5 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une description';
            }
            if (value.length < 10) {
              return 'La description doit faire au moins 10 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Type (Vente/Location)
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Type *',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'vente', child: Text('Vente')),
            DropdownMenuItem(value: 'location', child: Text('Location')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Veuillez sélectionner un type';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Prix
        TextFormField(
          controller: _prixController,
          decoration: InputDecoration(
            labelText: 'Prix * (${_selectedType == 'location' ? '€/mois' : '€'})',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un prix';
            }
            if (double.tryParse(value) == null) {
              return 'Veuillez entrer un prix valide';
            }
            final prix = double.parse(value);
            if (prix <= 0) {
              return 'Le prix doit être supérieur à 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Surface
        TextFormField(
          controller: _surfaceController,
          decoration: const InputDecoration(
            labelText: 'Surface (m²) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une surface';
            }
            if (int.tryParse(value) == null) {
              return 'Veuillez entrer une surface valide';
            }
            final surface = int.parse(value);
            if (surface <= 0) {
              return 'La surface doit être supérieure à 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Nombre de chambres
        TextFormField(
          controller: _chambresController,
          decoration: const InputDecoration(
            labelText: 'Nombre de chambres *',
            border: OutlineInputBorder(),
            hintText: '0',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le nombre de chambres';
            }
            if (int.tryParse(value) == null) {
              return 'Veuillez entrer un nombre valide';
            }
            final chambres = int.parse(value);
            if (chambres < 0) {
              return 'Le nombre de chambres ne peut pas être négatif';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Adresse
        TextFormField(
          controller: _adresseController,
          decoration: const InputDecoration(
            labelText: 'Adresse *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une adresse';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Ville
        TextFormField(
          controller: _villeController,
          decoration: const InputDecoration(
            labelText: 'Ville *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une ville';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        // Code postal
        TextFormField(
          controller: _codePostalController,
          decoration: const InputDecoration(
            labelText: 'Code postal',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _surfaceController.dispose();
    _chambresController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une annonce'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Photos
                    _buildImageSection(),
                    const SizedBox(height: 24),

                    // Champs du formulaire
                    _buildFormFields(),

                    // Information sur les champs obligatoires
                    const Text(
                      '* Champs obligatoires',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Bouton de soumission
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedImages.isNotEmpty || _isWeb) && !_isSubmitting 
                            ? _submitForm 
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: ((_selectedImages.isNotEmpty || _isWeb) && !_isSubmitting) 
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Création en cours...',
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              )
                            : const Text(
                                'Créer l\'annonce',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),

                    if (!_isWeb && _selectedImages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Veuillez ajouter au moins une photo',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}