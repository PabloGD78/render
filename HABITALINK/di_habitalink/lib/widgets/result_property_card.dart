import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/property_model.dart'; // Para PropertySummary

class ResultPropertyCard extends StatelessWidget {
  final PropertySummary property;
  final VoidCallback? onDetailsPressed;

  final Color backgroundColor;
  final Color titleColor;
  final Color detailsColor;
  final Color priceColor;

  const ResultPropertyCard({
    super.key,
    required this.property,
    this.onDetailsPressed,
    this.backgroundColor = const Color(0xFFF0E5D0),
    this.titleColor = const Color(0xFF855227),
    this.detailsColor = AppColors.hintTextColor,
    this.priceColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
  final String priceText = property.formattedPrice;
    final String fullImageUrl = property.imageUrl;

    // Definimos la altura de la imagen/contenido para el Row
    const double contentHeight = 200.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              fullImageUrl,
              width: contentHeight,
              height: contentHeight,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: contentHeight,
                  height: contentHeight,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            // FIX: Le damos una altura máxima definida (200) a la columna
            child: SizedBox(
              height: contentHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Precio: $priceText',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: priceColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.details,
                    style: TextStyle(fontSize: 14, color: detailsColor),
                  ),

                  // Spacer, que ahora funciona dentro de la altura limitada (200)
                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onDetailsPressed,
                        child: const Text(
                          'Más detalles ↗',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Llamar',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Contactar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
