import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:di_habitalink/controllers/property_controller.dart';
import 'package:di_habitalink/models/property_model.dart';
import 'package:di_habitalink/theme/colors.dart';
import 'package:di_habitalink/widgets/similar_property_card.dart';
import 'package:di_habitalink/widgets/search_bar_widget.dart';

class PropertyDetailPage extends StatelessWidget {
  final String propertyRef;

  const PropertyDetailPage({Key? key, required this.propertyRef})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PropertyController()..loadPropertyDetails(propertyRef),
      child: const _PropertyDetailView(),
    );
  }
}

class _PropertyDetailView extends StatefulWidget {
  const _PropertyDetailView({Key? key}) : super(key: key);

  @override
  State<_PropertyDetailView> createState() => _PropertyDetailViewState();
}

class _PropertyDetailViewState extends State<_PropertyDetailView> {
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentImageIndex);
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentImageIndex) {
        setState(() => _currentImageIndex = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- CORRECCIÓN DE COORDENADAS ---
  LatLng getValidLocation(Property property) {
    double lat = property.location.latitude;
    double lon = property.location.longitude;

    // Si las coordenadas son 0,0 devolvemos el centro de Sevilla
    if (lat == 0 && lon == 0) {
      return const LatLng(37.3891, -5.9845);
    }

    // Lógica de corrección para Sevilla:
    // Si la latitud es ~37 y la longitud llegó positiva (Argelia),
    // la convertimos a negativa para que sea Sevilla.
    if (lat > 36 && lat < 38 && lon > 0) {
      lon = -lon;
    }

    return LatLng(lat, lon);
  }

  void _nextImage(Property property) {
    if (property.images.isEmpty) return;
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % property.images.length;
      _pageController.animateToPage(
        _currentImageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _previousImage(Property property) {
    if (property.images.isEmpty) return;
    setState(() {
      _currentImageIndex =
          (_currentImageIndex - 1 + property.images.length) %
          property.images.length;
      _pageController.animateToPage(
        _currentImageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<PropertyController>(context);

    if (controller.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Propiedad')),
        body: Center(
          child: Text(
            controller.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    if (controller.currentProperty == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final property = controller.currentProperty!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: isDesktop
                      ? _buildDesktopLayout(property, controller)
                      : _buildMobileLayout(property, controller),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
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
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Property property, PropertyController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildPropertyMainContent(property)),
        const SizedBox(width: 30),
        Expanded(flex: 1, child: _buildSidebar(property, controller)),
      ],
    );
  }

  Widget _buildMobileLayout(Property property, PropertyController controller) {
    return Column(
      children: [
        _buildPropertyMainContent(property),
        const SizedBox(height: 30),
        _buildSidebar(property, controller),
      ],
    );
  }

  Widget _buildPropertyMainContent(Property property) {
    final controller = Provider.of<PropertyController>(context);
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(property),
            const SizedBox(height: 16),
            _FavoriteTitleRow(
              title: property.title,
              isFavorited: controller.isFavorited,
              isLoading: controller.isFavoriteLoading,
              onToggle: () async {
                final success = await controller.toggleFavorite(property.ref);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (controller.isFavorited
                                ? 'Favorito añadido.'
                                : 'Favorito eliminado.')
                          : 'No se pudo actualizar favorito.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              runSpacing: 8,
              children: [
                _buildDetailIcon(property.area, Icons.crop_square),
                _buildDetailIcon('${property.beds} hab', Icons.bed),
                _buildDetailIcon(
                  '${property.baths} ${int.tryParse(property.baths) == 1 ? 'baño' : 'baños'}',
                  Icons.bathtub,
                ),
                if (property.features.contains('Piscina'))
                  _buildDetailIcon('Piscina', Icons.pool),
                if (property.features.contains('Balcón'))
                  _buildDetailIcon('Balcón', Icons.balcony),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              property.description,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildPriceAndActions(property),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAndActions(Property property) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.formattedPrice,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              property.ref,
              style: TextStyle(
                color: AppColors.hintTextColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildActionButton(Icons.phone, 'Llamar'),
            const SizedBox(width: 8),
            _buildActionButton(Icons.email, 'Contactar'),
          ],
        ),
      ],
    );
  }

  Widget _buildImageGallery(Property property) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: property.images.isEmpty
                ? Container(
                    color: AppColors.cardBackground,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: property.images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        property.images[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                      );
                    },
                  ),
          ),
          if (property.images.length > 1) ...[
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: IconButton(
                onPressed: () => _previousImage(property),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: IconButton(
                onPressed: () => _nextImage(property),
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(property.images.length, (i) {
                  final isActive = i == _currentImageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 10 : 7,
                    height: isActive ? 10 : 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebar(Property property, PropertyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarSection(
          title: 'Ubicación',
          content: _buildLocationWithFlutterMap(property),
        ),
        const SizedBox(height: 30),
        _buildSidebarSection(
          title: 'Descubre casas similares',
          content: _buildSimilarPropertiesList(controller),
        ),
      ],
    );
  }

  Widget _buildLocationWithFlutterMap(Property property) {
    // Usamos la función de corrección
    final location = getValidLocation(property);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SizedBox(
        height: 250,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: 15, // Un poco más cerca para ver bien la calle
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 50,
                      height: 50,
                      point: location,
                      // Eliminado el texto "Propiedad" que causaba Overflow
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lat: ${location.latitude.toStringAsFixed(6)}, Lon: ${location.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailIcon(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.hintTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: Colors.brown),
      label: Text(
        label,
        style: const TextStyle(color: Colors.brown, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSidebarSection({
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.hintTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _buildSimilarPropertiesList(PropertyController controller) {
    if (controller.similarProperties.isEmpty) {
      return const Text('No hay propiedades similares disponibles.');
    }
    return Column(
      children: controller.similarProperties.map((prop) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: SimilarPropertyCard(
            title: prop.title,
            price: prop.formattedPrice,
            imageUrl: prop.imageUrl,
            onTap: (_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailPage(propertyRef: prop.id),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _FavoriteTitleRow extends StatelessWidget {
  final String title;
  final bool isFavorited;
  final bool isLoading;
  final VoidCallback onToggle;

  const _FavoriteTitleRow({
    required this.title,
    required this.isFavorited,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.hintTextColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: isLoading ? null : onToggle,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isFavorited ? Colors.white : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              border: isFavorited ? Border.all(color: AppColors.primary) : null,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited ? AppColors.primary : Colors.white,
                  ),
          ),
        ),
      ],
    );
  }
}
