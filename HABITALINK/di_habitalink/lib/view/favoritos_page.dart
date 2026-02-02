// lib/pages/FavoritosPage.dart - CÓDIGO COMPLETO Y DINÁMICO

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/result_property_card.dart';
import 'property/property_detail_page.dart';
import '../models/property_model.dart';
import '../services/favoritos_service.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final FavoriteService _favoriteService = FavoriteService();
  List<PropertySummary> _favoritos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final properties = await _favoriteService.getFavorites();
      setState(() {
        _favoritos = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al conectar con el servidor: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavoriteAndReload(String propertyId) async {
    final success = await _favoriteService.removeFavorite(propertyId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propiedad eliminada de favoritos.')),
        );
        _loadFavorites();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar de favoritos.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double kMaxWidth = 1200.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 20),
                const Text(
                  "Mis Favoritos",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxWidth),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : _favoritos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Text(
                      "Aún no tienes propiedades en favoritos.",
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.hintTextColor,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _favoritos.length,
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    final property = _favoritos[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Stack(
                        children: [
                          ResultPropertyCard(
                            property: property,
                            // cardWidth y cardHeight han sido eliminados del constructor
                            onDetailsPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PropertyDetailPage(
                                    propertyRef: property.id,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Icono para ELIMINAR de favoritos
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Color(0xFF007F3E),
                                size: 30,
                              ),
                              onPressed: () {
                                _removeFavoriteAndReload(property.id);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
