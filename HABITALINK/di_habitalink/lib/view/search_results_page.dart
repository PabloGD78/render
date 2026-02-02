import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/filter_sidebar.dart';
import '../widgets/result_property_card.dart';
import '../widgets/search_bar_widget.dart';
import '../services/property_service.dart';
import '../models/property_model.dart';
import '../models/filter_data_model.dart';
import 'property/property_detail_page.dart';
import 'notificaciones_page.dart';
import 'favoritos_page.dart';

const double _kMaxWidth = 1200.0;

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final PropertyService _propertyService = PropertyService();

  List<PropertySummary> _allPropertiesFromDb = [];
  List<PropertySummary> _filteredProperties = [];
  bool _loading = true;
  String? _errorMessage;
  String? _initialQuery;
  String? _initialFilter;

  @override
  void initState() {
    super.initState();
    _loadInitialProperties();
  }

  Future<void> _loadInitialProperties() async {
    try {
      final data = await _propertyService.obtenerTodas();
      // 🚨 Punto A: Verifica el tamaño de la lista de la base de datos
      print('DEBUG A: Propiedades obtenidas de la DB: ${data.length}');

      setState(() {
        _allPropertiesFromDb = data;
        _filteredProperties = data;
        _loading = false;
        // 🚨 Punto B: Verifica el tamaño de la lista filtrada DESPUÉS del setState
        print('DEBUG B: Lista filtrada inicial: ${_filteredProperties.length}');
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }

    // Aplicar filtros iniciales si vienen por argumentos
    if ((_initialQuery != null && _initialQuery!.isNotEmpty) ||
        (_initialFilter != null && _initialFilter != 'Vivienda')) {
      final filters = FilterData(
        minPrice: 0,
        maxPrice: double.maxFinite,
        type: _initialFilter == 'Vivienda' ? null : _initialFilter,
      );
      _applyFilters(filters, initialQuery: _initialQuery);
    }
  }

  void _onFilterChanged(FilterData filters) {
    // Comprobación de seguridad para evitar filtrar una lista vacía antes de que carguen los datos
    if (_allPropertiesFromDb.isEmpty && !_loading) {
      print(
        'ADVERTENCIA: Intento de filtrar con lista de propiedades vacía. No se aplica filtro.',
      );
      return;
    }

    print(
      'DEBUG: Aplicando filtros: ${filters.minPrice} - ${filters.maxPrice}, Type: ${filters.type}, Beds: ${filters.bedrooms}, Baths: ${filters.bathrooms}',
    );

    setState(() {
      _filteredProperties = _allPropertiesFromDb.where((property) {
        // 1. FILTRO DE PRECIO
        if (property.price < filters.minPrice ||
            property.price > filters.maxPrice) {
          return false;
        }

        // 2. FILTRO DE TIPO
        if (filters.type != null && property.type != filters.type) {
          return false;
        }

        // 3. FILTRO DE DORMITORIOS
        if (filters.bedrooms != null) {
          if (filters.bedrooms == '4+') {
            if (property.bedrooms < 4) return false;
          } else {
            final requiredBeds = int.tryParse(filters.bedrooms!);
            if (requiredBeds != null && property.bedrooms != requiredBeds) {
              return false;
            }
          }
        }

        // 4. FILTRO DE BAÑOS
        if (filters.bathrooms != null) {
          if (filters.bathrooms == '3+') {
            if (property.bathrooms < 3) return false;
          } else {
            final requiredBaths = int.tryParse(filters.bathrooms!);
            if (requiredBaths != null && property.bathrooms != requiredBaths) {
              return false;
            }
          }
        }

        // 5. FILTRO DE CARACTERÍSTICAS (general)
        if (filters.feature != null) {
          final f = filters.feature!.toLowerCase();
          final hasFeature = property.features.any((feat) => feat.toLowerCase() == f);
          if (!hasFeature) return false;
        }

        return true;
      }).toList();
      print(
        'DEBUG C: Propiedades filtradas resultantes: ${_filteredProperties.length}',
      );
    });
  }

  // Variante que permite pasar query de búsqueda (ubicación/título)
  void _applyFilters(FilterData filters, {String? initialQuery}) {
    setState(() {
      _filteredProperties = _allPropertiesFromDb.where((property) {
        if (property.price < filters.minPrice ||
            property.price > filters.maxPrice) return false;

        if (filters.type != null && property.type != filters.type) return false;

        if (filters.bedrooms != null) {
          if (filters.bedrooms == '4+') {
            if (property.bedrooms < 4) return false;
          } else {
            final requiredBeds = int.tryParse(filters.bedrooms!);
            if (requiredBeds != null && property.bedrooms != requiredBeds)
              return false;
          }
        }

        if (filters.bathrooms != null) {
          if (filters.bathrooms == '3+') {
            if (property.bathrooms < 3) return false;
          } else {
            final requiredBaths = int.tryParse(filters.bathrooms!);
            if (requiredBaths != null && property.bathrooms != requiredBaths)
              return false;
          }
        }

        if (filters.feature != null &&
            filters.feature == 'Piscina' &&
            !(property.hasPool ?? false)) return false;

        // Aplicar búsqueda por texto (ubicación/título)
        if (initialQuery != null && initialQuery.isNotEmpty) {
          final q = initialQuery.toLowerCase();
          final matchesTitle = property.title.toLowerCase().contains(q);
          final matchesDetails = property.details.toLowerCase().contains(q);
          final matchesLocation = property.location.toLowerCase().contains(q);
          if (!matchesTitle && !matchesDetails && !matchesLocation) return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Leer argumentos (si existen) al construir la página
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && (_initialQuery == null && _initialFilter == null)) {
      try {
        final mapArgs = args as Map<String, dynamic>;
        _initialQuery = (mapArgs['query'] as String?)?.trim();
        _initialFilter = (mapArgs['filter'] as String?)?.trim();
      } catch (_) {}
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.home, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pushNamed(context, '/'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: SearchBarWidget(
                      accentColor: AppColors.accent,
                      primaryColor: AppColors.primary,
                      isDense: true,
                      borderRadius: 30.0,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritosPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: _kMaxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: FilterSidebar(onFilterChanged: _onFilterChanged),
                ),
              ),
              Container(
                width: 2,
                color: AppColors.hintTextColor,
                margin: const EdgeInsets.symmetric(vertical: 20),
              ),
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                          child: Text(
                            '❌ Error al cargar datos: $_errorMessage',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : _filteredProperties.isEmpty
                      ? Center(
                          child: Text(
                            _allPropertiesFromDb.isEmpty
                                ? 'No hay propiedades en la base de datos.'
                                : 'No se encontraron propiedades que coincidan con los filtros.',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProperties.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final property = _filteredProperties[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: ResultPropertyCard(
                                property: property,
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
                            );
                          },
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
