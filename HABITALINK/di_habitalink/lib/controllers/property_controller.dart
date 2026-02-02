import 'package:flutter/foundation.dart';
import '../models/property_model.dart';
import '../services/property_service.dart' as service;
import '../services/favoritos_service.dart';

/// Controlador para manejar propiedades y su estado en la app
class PropertyController extends ChangeNotifier {
  final service.PropertyService _propertyService = service.PropertyService();
  final FavoriteService _favoriteService = FavoriteService();

  bool _isFavorited = false;
  bool get isFavorited => _isFavorited;

  bool _isFavoriteLoading = false;
  bool get isFavoriteLoading => _isFavoriteLoading;

  // Propiedad actual
  Property? _currentProperty;
  Property? get currentProperty => _currentProperty;

  // Mensaje de error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Lista de propiedades similares
  List<PropertySummary> _similarProperties = [];
  List<PropertySummary> get similarProperties => _similarProperties;

  /// Cargar los detalles de una propiedad por su ID
  Future<void> loadPropertyDetails(String id) async {
    _errorMessage = null;
    _currentProperty = null;
    _similarProperties = [];
    notifyListeners();

    try {
      // 1️⃣ Obtener detalle completo
      final property = await _propertyService.obtenerPropiedadDetalle(id);
      _currentProperty = property;

      // Cargar estado de favorito para esta propiedad
      await _loadFavoriteStatus(property.ref);

      // 2️⃣ Convertir a PropertySummary
      final propertySummary = PropertySummary.fromDetailedProperty(property);

      // 3️⃣ Obtener todas las propiedades para buscar similares
      final todas = await _propertyService.obtenerTodas();

      // 4️⃣ Filtrar similares por tipo y excluir la actual
      _similarProperties = todas
          .where(
            (p) => p.type == propertySummary.type && p.id != propertySummary.id,
          )
          .toList();
    } catch (e) {
      _errorMessage = 'Error al cargar la propiedad (ID: $id): $e';
      _currentProperty = null;
      _similarProperties = [];
    }

    notifyListeners();
  }

  Future<void> _loadFavoriteStatus(String propertyRef) async {
    _isFavoriteLoading = true;
    notifyListeners();
    try {
      final favs = await _favoriteService.getFavorites();
      _isFavorited = favs.any((f) => f.id == propertyRef);
    } catch (_) {
      _isFavorited = false;
    }
    _isFavoriteLoading = false;
    notifyListeners();
  }

  /// Alterna favorito: añade o quita según el estado actual.
  Future<bool> toggleFavorite(String propertyRef) async {
    if (_isFavoriteLoading) return false;
    _isFavoriteLoading = true;
    notifyListeners();

    bool success = false;
    try {
      if (!_isFavorited) {
        success = await _favoriteService.addFavorite(propertyRef);
      } else {
        success = await _favoriteService.removeFavorite(propertyRef);
      }
      if (success) _isFavorited = !_isFavorited;
    } catch (_) {
      success = false;
    }

    _isFavoriteLoading = false;
    notifyListeners();
    return success;
  }
}
