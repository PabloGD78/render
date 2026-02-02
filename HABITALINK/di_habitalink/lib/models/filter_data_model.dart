// lib/models/filter_data_model.dart

/// Clase centralizada para manejar los datos del formulario de filtros.
class FilterData {
  final double minPrice;
  final double maxPrice;
  final String? type;
  final String? bedrooms;
  final String? bathrooms;
  final String? feature;

  FilterData({
    // Rangos por defecto amplios
    this.minPrice = 0.0,
    this.maxPrice = 5000000.0,
    this.type,
    this.bedrooms,
    this.bathrooms,
    this.feature,
  });
}
