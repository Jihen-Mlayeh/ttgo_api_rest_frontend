import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Map<String, DateTime> _lastNotifications = {};
  final int _cooldownSeconds = 30;

  void showThresholdNotification(
      BuildContext context,
      String type,
      String message,
      IconData icon,
      Color color,
      ) {
    final now = DateTime.now();
    final key = '$type-$message';

    if (_lastNotifications.containsKey(key)) {
      final lastTime = _lastNotifications[key]!;
      final difference = now.difference(lastTime).inSeconds;

      if (difference < _cooldownSeconds) {
        return;
      }
    }

    _lastNotifications[key] = now;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void clearHistory() {
    _lastNotifications.clear();
  }
}