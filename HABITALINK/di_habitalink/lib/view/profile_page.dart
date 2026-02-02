import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/colors.dart';
import 'particular_dashboard.dart';
import 'professional_dashboard.dart';
import 'property/new_property_card_page.dart';
import 'edit_property_page.dart';

// --- MODELO DE DATOS ---
class AnuncioPerfil {
  final String id;
  final String titulo;
  final String precio;
  final String estado;
  final String imagenUrl;

  AnuncioPerfil({
    required this.id,
    required this.titulo,
    required this.precio,
    required this.estado,
    required this.imagenUrl,
  });

  factory AnuncioPerfil.fromJson(Map<String, dynamic> json) {
    const String baseUrl = 'http://localhost:3000';
    dynamic imagenRaw =
        json['url_imagen'] ?? json['imagenPrincipal'] ?? json['Imagenes'];
    String rawPath = '';

    if (imagenRaw is List && imagenRaw.isNotEmpty) {
      rawPath = imagenRaw.first.toString();
    } else if (imagenRaw is String) {
      rawPath = imagenRaw;
      if (rawPath.startsWith('[')) {
        try {
          final decoded = jsonDecode(rawPath);
          if (decoded is List && decoded.isNotEmpty)
            rawPath = decoded.first.toString();
        } catch (_) {}
      }
    }

    String finalUrl = '';
    if (rawPath.isNotEmpty) {
      if (rawPath.startsWith('http')) {
        finalUrl = rawPath;
      } else {
        final clean = rawPath.startsWith('/') ? rawPath : '/$rawPath';
        finalUrl = '$baseUrl$clean';
      }
    }

    return AnuncioPerfil(
      id: json['id'].toString(),
      titulo: json['nombre'] ?? json['titulo'] ?? 'Sin título',
      precio: json['precio'] != null ? "${json['precio']} €" : "0 €",
      estado: json['estado'] ?? 'Activo',
      imagenUrl: finalUrl,
    );
  }
}

// --- PÁGINA PRINCIPAL DE PERFIL ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color _backgroundColor = const Color(0xFFF3E5CD);

  String? userName;
  String? userEmail;
  String? userPassword;
  String? userType;
  String? idUsuario;

  bool _isLoading = true;
  bool _showPassword = false;
  List<AnuncioPerfil> misAnuncios = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    idUsuario =
        prefs.getString('idUsuario') ??
        prefs.getString('userId') ??
        prefs.getString('id');
    userName = prefs.getString('userName') ?? 'Usuario';
    userEmail = prefs.getString('userEmail') ?? 'Correo no disponible';
    userPassword = prefs.getString('userPassword') ?? '';
    userType = prefs.getString('tipo')?.toLowerCase();

    if (idUsuario != null &&
        (userType == 'particular' || userType == 'profesional')) {
      await _fetchUserProperties(idUsuario!);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchUserProperties(String userId) async {
    try {
      final url = Uri.parse(
        'http://localhost:3000/api/propiedades/usuario/$userId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> listaBruta = (decoded is List)
            ? decoded
            : (decoded['data'] ?? []);
        setState(() {
          misAnuncios = listaBruta
              .map((json) => AnuncioPerfil.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching properties: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAuthorized = userType == 'particular' || userType == 'profesional';
    bool isProfesional = userType == 'profesional';
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      floatingActionButton: isAuthorized ? _buildFab() : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 30 : 16,
                    horizontal: isDesktop ? 40 : 16,
                  ),
                  child: isDesktop
                      ? _buildDesktopLayout(isProfesional, isAuthorized)
                      : _buildMobileLayout(isProfesional, isAuthorized),
                ),
              ),
            ),
    );
  }

  Widget _buildFab() => FloatingActionButton.extended(
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPropertyCardPage()),
    ),
    backgroundColor: AppColors.primary,
    icon: const Icon(Icons.add, color: Colors.white),
    label: const Text(
      "Subir anuncio",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  AppBar _buildAppBar() => AppBar(
    title: const Text(
      'Ajustes de Perfil',
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
    ),
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.primary,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      onPressed: () => Navigator.pop(context),
    ),
  );

  Widget _buildDesktopLayout(bool isProfesional, bool isAuthorized) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 350,
          child: Column(
            children: [
              _buildIdentityCard(isProfesional),
              const SizedBox(height: 20),
              _buildAccountDetailsCard(),
            ],
          ),
        ),
        const SizedBox(width: 30),
        Expanded(
          child: Column(
            children: [
              if (isAuthorized) ...[
                _buildTopBanner(isProfesional),
                const SizedBox(height: 30),
                _buildUserPropertiesSection(),
              ] else
                const Center(child: Text("Bienvenido a tu perfil")),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isProfesional, bool isAuthorized) {
    return Column(
      children: [
        _buildIdentityCard(isProfesional),
        const SizedBox(height: 20),
        if (isAuthorized) ...[
          _buildTopBanner(isProfesional),
          const SizedBox(height: 20),
        ],
        _buildAccountDetailsCard(),
        const SizedBox(height: 30),
        if (isAuthorized) _buildUserPropertiesSection(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildIdentityCard(bool isProfesional) {
    Color badgeColor = isProfesional
        ? AppColors.primary
        : const Color(0xFFD97706);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF3D6158)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: -35,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 37,
                      backgroundColor: _backgroundColor,
                      child: Text(
                        userName != null && userName!.isNotEmpty
                            ? userName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 45),
          Text(
            userName ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              userType?.toUpperCase() ?? 'VISITANTE',
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos Personales',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 20),
        _buildInfoRow('Nombre completo', userName ?? ''),
        const Divider(height: 32),
        _buildInfoRow('Correo electrónico', userEmail ?? ''),
        const Divider(height: 32),
        _buildPasswordRow(),
      ],
    ),
  );

  Widget _buildTopBanner(bool isProfesional) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFF1A2E2A)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Panel de Control",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Gestiona y analiza tus publicaciones.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => isProfesional
                  ? const ProfessionalDashboard()
                  : const ParticularDashboard(),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Ir a mi Panel",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _buildUserPropertiesSection() {
    if (misAnuncios.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Mis anuncios",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              "${misAnuncios.length} total",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: misAnuncios.length > 2 ? 2 : misAnuncios.length,
          itemBuilder: (context, index) =>
              _buildAnuncioCard(misAnuncios[index]),
        ),
        if (misAnuncios.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllAdsPage(allAnuncios: misAnuncios),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  "Ver todos",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnuncioCard(AnuncioPerfil anuncio) {
    bool isActive = anuncio.estado == 'Activo';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: anuncio.imagenUrl.isNotEmpty
                  ? Image.network(
                      anuncio.imagenUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(color: Colors.grey.shade100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anuncio.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  anuncio.precio,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      anuncio.estado,
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, size: 18),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPropertyPage(
                            propiedad: {
                              'id': anuncio.id,
                              'titulo': anuncio.titulo,
                              'precio': anuncio.precio,
                              'estado': anuncio.estado,
                              'imagenUrl': anuncio.imagenUrl,
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Color(0xFF374151),
        ),
      ),
    ],
  );

  Widget _buildPasswordRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildInfoRow('Contraseña', _showPassword ? userPassword! : '••••••••'),
      IconButton(
        onPressed: () => setState(() => _showPassword = !_showPassword),
        icon: Icon(
          _showPassword ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
          size: 20,
        ),
      ),
    ],
  );
}

// --- CLASE ALLADSPAGE (MODIFICACIÓN PROFESIONAL SOLICITADA) ---
class AllAdsPage extends StatelessWidget {
  final List<AnuncioPerfil> allAnuncios;
  const AllAdsPage({super.key, required this.allAnuncios});

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 4 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5CD),
      appBar: AppBar(
        title: const Text(
          "MI CARTERA",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: allAnuncios.length,
        itemBuilder: (context, index) {
          final anuncio = allAnuncios[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: anuncio.imagenUrl.isNotEmpty
                        ? Image.network(
                            anuncio.imagenUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.broken_image, size: 20),
                          )
                        : const Icon(Icons.image, color: Colors.black12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          anuncio.titulo.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          anuncio.precio,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            anuncio.estado.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
