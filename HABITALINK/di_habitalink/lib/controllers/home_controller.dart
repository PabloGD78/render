import 'package:flutter/foundation.dart';
import '../models/property_model.dart';
import '../services/property_service.dart'; // Asegúrate de importar tu servicio

class HomeController extends ChangeNotifier {
  // Instancia del servicio
  final PropertyService _propertyService = PropertyService();

  // Variables de estado
  List<PropertySummary> _featuredProperties = [];
  bool _isLoading = false;
  String? _error;

  // Getters para que la vista pueda leer los datos
  List<PropertySummary> get featuredProperties => _featuredProperties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor: Carga datos al iniciar
  HomeController() {
    loadFeaturedProperties();
  }

  // Cargar las propiedades
  Future<void> loadFeaturedProperties() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Avisa a la vista que empezó a cargar

    try {
      // 1. Llamamos al servicio (el mismo que usabas en HomePage)
      final allProperties = await _propertyService.obtenerTodas();
      
      // 2. Ordenamos por fecha (de más reciente a más antigua)
      allProperties.sort((a, b) => b.creationDate.compareTo(a.creationDate));

      // 3. Guardamos la lista
      _featuredProperties = allProperties;

    } catch (e) {
      _error = 'Error al cargar propiedades: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Avisa a la vista que terminó (con éxito o error)
    }
  }
}