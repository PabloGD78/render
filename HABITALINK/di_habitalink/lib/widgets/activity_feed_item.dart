import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ActivityFeedItem extends StatelessWidget {
  final String userName;
  final String actionText;
  final String targetText;
  final String timeAgo;
  final bool isAlert;

  const ActivityFeedItem({
    Key? key,
    required this.userName,
    required this.actionText,
    required this.targetText,
    required this.timeAgo,
    this.isAlert = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isAlert ? Colors.red[50] : AppColors.cardBackground,
            child: Icon(
              isAlert ? Icons.warning_amber_rounded : Icons.person_outline,
              color: isAlert ? Colors.red : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.text, fontSize: 14),
                children: [
                  TextSpan(text: "$userName ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "$actionText "),
                  TextSpan(text: targetText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          ),
          Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}