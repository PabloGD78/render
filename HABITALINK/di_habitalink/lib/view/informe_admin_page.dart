import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../theme/colors.dart';

// --- GENERACIÓN DE PDF PROFESIONAL ---
Future<Uint8List> _generatePdfBytes(Map payload) async {
  final data = payload['data'] as Map<String, dynamic>;
  final logo = payload['logo'] as Uint8List?;
  final pie = payload['pie'] as Uint8List?;
  final bar = payload['bar'] as Uint8List?;
  final barTypes = payload['barTypes'] as Uint8List?;
  final barFeatures = payload['barFeatures'] as Uint8List?;
  final int totalUsers = payload['totalUsers'] ?? 0;

  final pdf = pw.Document();
  final pwLogo = logo != null ? pw.MemoryImage(logo) : null;
  final PdfColor basePrimary = PdfColor.fromInt(AppColors.primary.value);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context pwContext) {
        return [
          // ENCABEZADO
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INFORME ADMINISTRATIVO',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: basePrimary,
                    ),
                  ),
                  pw.Text(
                    'HabitaLink - Estado de la Plataforma',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              if (pwLogo != null)
                pw.Container(width: 50, height: 50, child: pw.Image(pwLogo)),
            ],
          ),
          pw.Divider(thickness: 1.5, color: basePrimary),
          pw.SizedBox(height: 15),

          // KPIs
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox('Usuarios Totales', '$totalUsers', basePrimary),
              _buildStatBox(
                'Anuncios Totales',
                '${payload['totalAds']}',
                PdfColors.green800,
              ),
              _buildStatBox(
                'Usuarios Activos',
                '${payload['activeUsers']}',
                PdfColors.blue600,
              ),
              _buildStatBox(
                'Alertas Imagen',
                '${data['alertasSinImagen'] ?? 0}',
                PdfColors.red,
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // SECCIÓN USUARIOS
          pw.Text(
            'Distribución de Usuarios',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: basePrimary,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (pie != null)
                pw.Container(
                  width: 180,
                  height: 140,
                  child: pw.Image(pw.MemoryImage(pie)),
                ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headerDecoration: pw.BoxDecoration(color: basePrimary),
                  headers: ['Tipo', 'Cant.', '%'],
                  data: List<List<String>>.generate(
                    (data['usuariosTipo'] as List).length,
                    (index) {
                      final u = data['usuariosTipo'][index];
                      final cant = u['cantidad'] as int;
                      final porc = totalUsers > 0
                          ? (cant / totalUsers * 100).toStringAsFixed(1)
                          : "0";
                      return [u['tipo'].toString(), cant.toString(), "$porc%"];
                    },
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // SECCIÓN: Inventario por Tipo de Anuncio
          pw.Text(
            'Inventario por Tipo de Anuncio',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: basePrimary,
            ),
          ),
          pw.SizedBox(height: 10),
          if (barTypes != null)
            pw.Center(
              child: pw.Container(
                width: 350,
                height: 150,
                child: pw.Image(pw.MemoryImage(barTypes), fit: pw.BoxFit.contain),
              ),
            ),
          pw.SizedBox(height: 10),
          // Tabla con popularTypes
          pw.Text('Top tipos por favoritos', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Tipo', 'Favs'],
            data: List<List<String>>.generate(
              (data['popularTypes'] as List?)?.length ?? 0,
              (i) {
                final row = (data['popularTypes'] as List)[i];
                return [row['tipo'].toString(), (row['favoritos'] ?? 0).toString()];
              },
            ),
          ),

          pw.SizedBox(height: 12),
          pw.Text('Popularidad por característica (favoritos)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: basePrimary)),
          pw.SizedBox(height: 8),
          if (barFeatures != null)
            pw.Center(
              child: pw.Container(
                width: 350,
                height: 150,
                child: pw.Image(pw.MemoryImage(barFeatures), fit: pw.BoxFit.contain),
              ),
            ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Característica', 'Favs'],
            data: List<List<String>>.generate(
              (data['popularFeatures'] as List?)?.length ?? 0,
              (i) {
                final row = (data['popularFeatures'] as List)[i];
                return [row['feature'].toString(), (row['cantidad'] ?? 0).toString()];
              },
            ),
          ),
        ];
      },
    ),
  );

  return pdf.save();
}

pw.Widget _buildStatBox(String label, String value, PdfColor color) {
  return pw.Container(
    width: 100,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: color, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 6),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ),
  );
}

// --- CLASE PRINCIPAL ---
class InformeAdminPage extends StatefulWidget {
  const InformeAdminPage({super.key});
  @override
  State<InformeAdminPage> createState() => _InformeAdminPageState();
}

class _InformeAdminPageState extends State<InformeAdminPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final d = await _fetchAdminReport();
    setState(() {
      _data = d;
      _isLoading = false;
    });
  }

  int _getTotalUsers() => (List.from(
    _data?['usuariosTipo'] ?? [],
  )).fold(0, (s, e) => s + (e['cantidad'] as int));
  int _getTotalAds() => (List.from(
  _data?['anunciosPorTipo'] ?? [],
  )).fold(0, (s, e) => s + (e['cantidad'] as int));

  Future<void> _exportPdf() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final totalU = _getTotalUsers();

      // Capturamos con dimensiones más conservadoras para el PDF
      Uint8List? pieImageBytes = await _captureOffscreenChart(
        _UserTypePieChart(
          data: List.from(_data?['usuariosTipo'] ?? []),
          total: totalU,
        ),
        width: 600,
        height: 400,
      );

      // Captura de gráficos nuevos
      Uint8List? barTypesBytes = await _captureOffscreenChart(
        _SimpleBarChart(data: List.from(_data?['popularTypes'] ?? []), labelKey: 'tipo', valueKey: 'favoritos'),
        width: 800,
        height: 400,
      );

      Uint8List? barFeaturesBytes = await _captureOffscreenChart(
        _SimpleBarChart(data: List.from(_data?['popularFeatures'] ?? []), labelKey: 'feature', valueKey: 'cantidad'),
        width: 800,
        height: 400,
      );

      Uint8List logoBytes = await rootBundle
          .load('assets/logo/LogoSinFondo.png')
          .then((bd) => bd.buffer.asUint8List());

      final payload = {
        'data': _data,
        'logo': logoBytes,
  'pie': pieImageBytes,
  'barTypes': barTypesBytes,
  'barFeatures': barFeaturesBytes,
        'totalUsers': totalU,
        'totalAds': _getTotalAds(),
        'activeUsers': _data?['usuariosActivos'] ?? 0,
      };

      Uint8List bytes = await _generatePdfBytes(payload);
      await Printing.sharePdf(bytes: bytes, filename: 'informe_habitalink.pdf');
    } catch (e) {
      debugPrint("Error generando PDF: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<Uint8List?> _captureOffscreenChart(
    Widget chart, {
    double width = 800,
    double height = 400,
  }) async {
    final key = GlobalKey();
    final overlay = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -5000, // Fuera de la pantalla
        child: SizedBox(
          width: width,
          height: height,
          child: RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: Material(color: Colors.white, child: chart),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(milliseconds: 300));

    RenderRepaintBoundary? boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    ui.Image image = await boundary!.toImage(
      pixelRatio: 1.5,
    ); // Reducido de 2.0 a 1.5
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    overlay.remove();
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control - Informes'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeaderStats(),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Distribución de Usuarios (%)"),
                  SizedBox(
                    height: 220,
                    child: _UserTypePieChart(
                      data: List.from(_data?['usuariosTipo'] ?? []),
                      total: _getTotalUsers(),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Inventario por Tipo de Anuncio"),
                  // Gráfico: Popularidad por tipo (favoritos)
                  _buildSectionTitle("Popularidad por Tipo (favoritos)"),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    child: _SimpleBarChart(
                      data: List.from(_data?['popularTypes'] ?? []),
                      labelKey: 'tipo',
                      valueKey: 'favoritos',
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Gráfico: Popularidad por característica (favoritos)
                  _buildSectionTitle("Popularidad por Característica (favoritos)"),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    child: _SimpleBarChart(
                      data: List.from(_data?['popularFeatures'] ?? []),
                      labelKey: 'feature',
                      valueKey: 'cantidad',
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _isGenerating
                          ? 'Generando...'
                          : 'Exportar PDF Profesional',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderStats() {
    return Row(
      children: [
        _statCard(
          'Total Usuarios',
          _getTotalUsers().toString(),
          Icons.people,
          AppColors.primary,
        ),
        _statCard(
          'Total Anuncios',
          _getTotalAds().toString(),
          Icons.analytics,
          Colors.green,
        ),
        _statCard(
          'Activos Hoy',
          (_data?['usuariosActivos'] ?? 0).toString(),
          Icons.bolt,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _statCard(String t, String v, IconData i, Color c) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(i, color: c, size: 20),
              Text(
                v,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                t,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// --- GRÁFICOS ---
class _UserTypePieChart extends StatelessWidget {
  final List data;
  final int total;
  const _UserTypePieChart({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    if (data.isEmpty) return const Center(child: Text("Sin datos"));
    return PieChart(
      PieChartData(
        sections: List.generate(data.length, (i) {
          final double value = (data[i]['cantidad'] as num).toDouble();
          final String pct = total > 0
              ? (value / total * 100).toStringAsFixed(1)
              : "0";
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title: '${data[i]['tipo']}\n$pct%',
            radius: 70,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }
}

class _AdsBarChart extends StatelessWidget {
  final List data;
  const _AdsBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("Sin datos"));
    return BarChart(
      BarChartData(
        barGroups: List.generate(data.length, (i) {
          // Colorear por índice para distinguir tipos
          final colors = [AppColors.primary, Colors.green, Colors.orange, Colors.purple, Colors.teal];
          Color barColor = colors[i % colors.length];

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (data[i]['cantidad'] as num).toDouble(),
                color: barColor,
                width: 35,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                int index = v.toInt();
                if (index < 0 || index >= data.length) return const Text("");
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index]['estado'],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }
}

// Widget reutilizable de gráfico de barras: recibe lista, clave de etiqueta y clave de valor
class _SimpleBarChart extends StatelessWidget {
  final List data;
  final String labelKey;
  final String valueKey;
  const _SimpleBarChart({required this.data, required this.labelKey, required this.valueKey});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("Sin datos"));

    final colors = [AppColors.primary, Colors.green, Colors.orange, Colors.purple, Colors.teal];

    return BarChart(
      BarChartData(
        barGroups: List.generate(data.length, (i) {
          final val = (data[i][valueKey] ?? 0) as num;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val.toDouble(),
                color: colors[i % colors.length],
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                int index = v.toInt();
                if (index < 0 || index >= data.length) return const Text("");
                final label = data[index][labelKey] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> _fetchAdminReport() async {
  try {
    final res = await http.get(
      Uri.parse('http://localhost:3000/api/admin/informe'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['data'] ?? {};
  } catch (_) {}
  // Datos de prueba si falla la API
  return {
    'usuariosTipo': [
      {'tipo': 'Propietarios', 'cantidad': 12},
      {'tipo': 'Inquilinos', 'cantidad': 45},
    ],
    'anunciosPorTipo': [
      {'estado': 'Venta', 'cantidad': 15},
      {'estado': 'Alquiler', 'cantidad': 2},
    ],
    'popularTypes': [
      {'tipo': 'Venta', 'favoritos': 20},
      {'tipo': 'Alquiler', 'favoritos': 8},
      {'tipo': 'Obra nueva', 'favoritos': 3},
    ],
    'popularFeatures': [
      {'feature': 'piscina', 'cantidad': 14},
      {'feature': 'jardin', 'cantidad': 9},
      {'feature': 'garaje', 'cantidad': 7},
      {'feature': 'terraza', 'cantidad': 5},
    ],
    'usuariosActivos': 8,
    'alertasSinImagen': 3,
  };
}
