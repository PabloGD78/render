import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'contact_item.dart';

class FooterWidget extends StatelessWidget {
  final bool compact;
  const FooterWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.symmetric(
        horizontal: AppColors.kPadding,
        vertical: compact ? 16 : 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contacta con nosotros',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ContactItem(icon: Icons.phone, text: '+34 641 85 39 23'),
          const SizedBox(height: 5),
          ContactItem(icon: Icons.email, text: 'habitalink@gmail.com'),
        ],
      ),
    );
  }
}
