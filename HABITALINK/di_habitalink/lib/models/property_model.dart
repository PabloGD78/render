import 'package:latlong2/latlong.dart';

// -----------------------------------------------------------------------------
// 0. CONFIGURACIÓN DE URL BASE
// -----------------------------------------------------------------------------
const String BASE_URL_SERVER = 'http://172.22.50.19:3000 ';

// -----------------------------------------------------------------------------
// 1. Funciones Helper para parseo seguro y URL
// -----------------------------------------------------------------------------

double _parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleanString = value
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^\d\.]'), '')
        .trim();
    return double.tryParse(cleanString) ?? 0.0;
  }
  return 0.0;
}

int _parseToInt(dynamic value) => _parseToDouble(value).toInt();

DateTime _parseToDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

String _makeAbsoluteUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final cleanPath = path.startsWith('/') ? path : '/$path';
  return BASE_URL_SERVER + cleanPath;
}

// -----------------------------------------------------------------------------
// 2. Modelo de Detalle Completo: Property
// -----------------------------------------------------------------------------

class Property {
  final String ref;
  final String title;
  final String price;
  final String area;
  final String beds;
  final String baths;
  final String description;
  final LatLng location;
  final List<String> images;
  final List<String> features;

  Property({
    required this.ref,
    required this.title,
    required this.price,
    required this.area,
    required this.beds,
    required this.baths,
    required this.description,
    required this.location,
    required this.images,
    required this.features,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    final lat = _parseToDouble(json['latitude']);
    final lon = _parseToDouble(json['longitude']);

    // 🔍 DEBUG: Mostrar coordenadas parseadas
    print(
      '📍 Property.fromJson - Ubicación: lat=$lat, lon=$lon, id=${json['id']}',
    );

    return Property(
      ref: json['id']?.toString() ?? json['ref']?.toString() ?? '',
      title:
          json['titulo_completo'] ?? json['titulo'] ?? 'Propiedad de Detalle',
      price: json['precio']?.toString() ?? '0',
      area: json['superficie']?.toString() ?? '0',
      beds: json['dormitorios']?.toString() ?? '0',
      baths: json['banos']?.toString() ?? '0',
      description:
          json['descripcion_larga'] ??
          json['descripcion_corta'] ??
          json['descripcion'] ??
          'Sin descripción.',

      // ✅ CORRECCIÓN AQUÍ: Nombres de columnas coincidentes con tu DB (latitude/longitude)
      location: LatLng(lat, lon),

      images:
          (json['imagenes'] as List<dynamic>?)
              ?.map((i) => _makeAbsoluteUrl(i.toString()))
              .toList() ??
          (json['url_imagen'] != null
              ? [_makeAbsoluteUrl(json['url_imagen'].toString())]
              : []),
      features: List<String>.from(json['caracteristicas'] ?? []),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Modelo de Resumen: PropertySummary
// -----------------------------------------------------------------------------

String _formatCurrency(int value) {
  if (value == 0) return '0 €';
  final s = value.toString();
  final buffer = StringBuffer();
  int offset = s.length % 3;
  if (offset > 0) {
    buffer.write(s.substring(0, offset));
    if (s.length > 3) buffer.write('.');
  }
  for (int i = offset; i < s.length; i += 3) {
    buffer.write(s.substring(i, i + 3));
    if (i + 3 < s.length) buffer.write('.');
  }
  return '${buffer.toString()} €';
}

extension PropertyFormatters on Property {
  int get priceValue => _parseToDouble(price).toInt();
  String get formattedPrice => _formatCurrency(priceValue);
}

extension PropertySummaryFormatters on PropertySummary {
  String get formattedPrice => _formatCurrency(price);
}

class PropertySummary {
  final String id;
  final String imageUrl;
  final String title;
  final String details;
  final int price;
  final int bedrooms;
  final int bathrooms;
  final double superficie;
  final String location;
  final String type;
  final bool hasPool;
  final List<String> features;
  final DateTime creationDate;

  PropertySummary({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.details,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.superficie,
    required this.location,
    required this.type,
    required this.hasPool,
    required this.features,
    required this.creationDate,
  });

  factory PropertySummary.fromJson(Map<String, dynamic> json) {
    final double superficieValue = _parseToDouble(json['superficie']);
    final int bedroomsValue = _parseToInt(json['dormitorios']);
    final int bathroomsValue = _parseToInt(json['banos']);
    final int priceValue = _parseToInt(json['precio']);
    final String idPropiedad =
        json['id']?.toString() ?? json['ref']?.toString() ?? '';

    final String locationName =
        json['localidad'] ??
        json['ubicacion'] ??
        json['ciudad'] ??
        json['municipio'] ??
        '';

    final DateTime dateValue = _parseToDateTime(json['fecha_creacion']);

    final String imagePathWithPrefix = json['url_imagen'] ?? '';
    String imageUrl = '';

    if (imagePathWithPrefix.isNotEmpty) {
      final imagePath = imagePathWithPrefix.startsWith('2.')
          ? imagePathWithPrefix.substring(2)
          : imagePathWithPrefix;
      imageUrl = _makeAbsoluteUrl(imagePath);
    }

    final bool hasPoolValue =
        (json['caracteristicas'] as List<dynamic>?)?.any(
          (f) => f.toString().toLowerCase().contains('piscina'),
        ) ??
        false;

    return PropertySummary(
      id: idPropiedad,
      imageUrl: imageUrl,
      title: json['titulo'] ?? 'Propiedad Sin Título',
      price: priceValue,
      bedrooms: bedroomsValue,
      bathrooms: bathroomsValue,
      superficie: superficieValue,
      location: locationName,
      type: json['tipo'] ?? 'Desconocido',
      hasPool: hasPoolValue,
      features: List<String>.from(json['caracteristicas'] ?? []),
      details:
          '$bedroomsValue habs - $bathroomsValue baños - ${superficieValue.toInt()} m2',
      creationDate: dateValue,
    );
  }

  factory PropertySummary.fromDetailedProperty(Property detailedProperty) {
    int _safeParseInt(String s) {
      final clean = s.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9\.]'), '');
      return double.tryParse(clean)?.toInt() ?? 0;
    }

    double _safeParseDouble(String s) {
      final cleanString = s.replaceAll(RegExp(r'[^\d\.]'), '');
      return double.tryParse(cleanString) ?? 0.0;
    }

    final bedroomsValue = _safeParseInt(detailedProperty.beds);
    final bathroomsValue = _safeParseInt(detailedProperty.baths);
    final superficieValue = _safeParseDouble(detailedProperty.area);

    final hasPool = detailedProperty.features.any(
      (f) => f.toLowerCase().contains('piscina'),
    );

    String imageUrl = 'assets/default.png';
    if (detailedProperty.images.isNotEmpty) {
      imageUrl = detailedProperty.images.first;
    }

    String detectType(String title, List<String> features) {
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('piso') || lowerTitle.contains('apartamento'))
        return 'Piso';
      if (lowerTitle.contains('chalet') || lowerTitle.contains('casa'))
        return 'Chalet';
      if (lowerTitle.contains('garaje') || lowerTitle.contains('parking'))
        return 'Garaje';
      if (lowerTitle.contains('oficina') || lowerTitle.contains('local'))
        return 'Oficina';
      return 'Desconocido';
    }

    return PropertySummary(
      id: detailedProperty.ref,
      imageUrl: imageUrl,
      title: detailedProperty.title,
      price: _safeParseInt(detailedProperty.price),
      bedrooms: bedroomsValue,
      bathrooms: bathroomsValue,
      superficie: superficieValue,
      location: '',
      type: detectType(detailedProperty.title, detailedProperty.features),
      hasPool: hasPool,
      features: detailedProperty.features,
      details:
          '$bedroomsValue habs - $bathroomsValue baños - ${superficieValue.toInt()} m2',
      creationDate: DateTime.now(),
    );
  }
}
