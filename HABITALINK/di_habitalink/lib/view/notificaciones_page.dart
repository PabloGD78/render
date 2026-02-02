import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/footer_widget.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.kPadding,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //vorbe atrah
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  Image.asset(
                    'assets/logo/LogoSinFondo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppColors.kPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mis Notificaciones",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _NotificationItem(
                    title: "Cita confirmada",
                    message:
                        "Tu visita al piso de Santa Cruz está programada para mañana a las 10:00.",
                    time: "Hace 2 horas",
                    isUnread: true,
                  ),
                  const SizedBox(height: 15),

                  const _NotificationItem(
                    title: "Nueva propiedad en tu zona",
                    message:
                        "Se ha publicado un nuevo chalet en Alfalfa que coincide con tus filtros.",
                    time: "Ayer",
                    isUnread: false,
                  ),
                  const SizedBox(height: 15),

                  // Notificación 3
                  const _NotificationItem(
                    title: "Bajada de precio",
                    message:
                        "El ático que guardaste en favoritos ha bajado un 5% su valor.",
                    time: "Hace 3 días",
                    isUnread: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const FooterWidget(compact: true),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isUnread;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        //Testurash
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Pa destaca q el notah no lee la noti todaviah
        border: isUnread
            ? Border.all(color: AppColors.accent, width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //iconillo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnread
                  ? Icons.notifications_active
                  : Icons.notifications_outlined,
              color: AppColors.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),

          // Testosh
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.hintTextColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
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
