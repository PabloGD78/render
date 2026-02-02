import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/colors.dart';

// ---------------- MODELO ----------------
class InmuebleAnuncio {
  final String id;
  final String idUsuario;
  final String nombre;
  final String descripcion;
  final String precio;
  final String estado;
  final String imagenUrl;

  InmuebleAnuncio({
    required this.id,
    required this.idUsuario,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.estado,
    required this.imagenUrl,
  });

  factory InmuebleAnuncio.fromJson(Map<String, dynamic> json) {
    return InmuebleAnuncio(
      id: json['id'].toString(),
      idUsuario: json['id_usuario'].toString(),
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: json['precio'].toString(),
      estado: json['estado'] ?? 'Activo',
      imagenUrl:
          json['imagenUrl'] ??
          'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=500',
    );
  }
}

// ---------------- ALL ADS SCREEN ----------------
class AllAdsScreen extends StatefulWidget {
  final bool isParticular;
  final String userId; // Para filtrar anuncios del usuario

  const AllAdsScreen({
    super.key,
    required this.userId,
    this.isParticular = false,
  });

  @override
  State<AllAdsScreen> createState() => _AllAdsScreenState();
}

class _AllAdsScreenState extends State<AllAdsScreen> {
  late Future<List<InmuebleAnuncio>> anunciosFuture;

  @override
  void initState() {
    super.initState();
    anunciosFuture = fetchAnuncios(widget.userId);
  }

  Future<List<InmuebleAnuncio>> fetchAnuncios(String userId) async {
    final response = await http.get(
      Uri.parse('https://tu-backend.com/api/anuncios?userId=$userId'),
    );

    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((item) => InmuebleAnuncio.fromJson(item)).toList();
    } else {
      throw Exception('Error cargando anuncios');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Mis anuncios",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: FutureBuilder<List<InmuebleAnuncio>>(
        future: anunciosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes anuncios'));
          } else {
            final anuncios = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: anuncios.length,
              itemBuilder: (context, index) {
                return TarjetaAnuncioParticular(anuncio: anuncios[index]);
              },
            );
          }
        },
      ),
    );
  }
}

// ---------------- TARJETA PARTICULAR ----------------
class TarjetaAnuncioParticular extends StatelessWidget {
  final InmuebleAnuncio anuncio;

  const TarjetaAnuncioParticular({super.key, required this.anuncio});

  @override
  Widget build(BuildContext context) {
    Color colorEstado;
    Color colorTextoEstado;
    String textoBoton = "Editar";
    IconData iconoBoton = Icons.edit;
    Color colorBoton = AppColors.primary;

    if (anuncio.estado == "Caduca pronto") {
      colorEstado = Colors.orange.shade100;
      colorTextoEstado = Colors.orange.shade900;
      textoBoton = "Renovar";
      iconoBoton = Icons.refresh;
      colorBoton = Colors.orange;
    } else if (anuncio.estado == "Caducado") {
      colorEstado = Colors.red.shade100;
      colorTextoEstado = Colors.red.shade900;
      textoBoton = "Renovar";
      iconoBoton = Icons.refresh;
      colorBoton = Colors.red;
    } else {
      colorEstado = Colors.green.shade100;
      colorTextoEstado = Colors.green.shade900;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 110,
                height: 110,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(anuncio.imagenUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 14.0,
                    right: 14.0,
                    bottom: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anuncio.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.2,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${anuncio.precio} €',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorEstado,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    anuncio.estado,
                    style: TextStyle(
                      color: colorTextoEstado,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorBoton,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: Icon(iconoBoton, color: Colors.white, size: 16),
                  label: Text(
                    textoBoton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
