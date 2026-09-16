import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Formats and shares trip status and ETA with family or colleagues.
/// Adheres strictly to formal, secular Egyptian Arabic transit phrasing
/// without any religious expressions.
class TripSharingService {
  TripSharingService._();

  static const String appUrl = "https://guidy-app.web.app";

  static Future<void> shareTrip({
    required BuildContext context,
    required String destinationName,
    String? transitMode,
    String? estimatedArrival,
    String? durationMinutes,
    String lang = 'ar',
  }) {
    final String text;
    if (lang == 'ar') {
      final modeText = transitMode != null && transitMode.isNotEmpty
          ? 'بواسطة $transitMode'
          : 'بالمواصلات العامة';
      final timeText = estimatedArrival != null && estimatedArrival.isNotEmpty
          ? 'ومتوقع أوصل حوالي الساعة $estimatedArrival'
          : (durationMinutes != null ? 'خلال حوالي $durationMinutes دقيقة' : '');

      text = 'أنا في طريقي إلى $destinationName $modeText $timeText.\n'
          'تقدر تتابع تفاصيل الرحلة عبر تطبيق Guidy:\n'
          '$appUrl';
    } else {
      final modeText = transitMode != null && transitMode.isNotEmpty
          ? 'via $transitMode'
          : 'via public transit';
      final timeText = estimatedArrival != null && estimatedArrival.isNotEmpty
          ? 'estimated arrival around $estimatedArrival'
          : (durationMinutes != null ? 'in about $durationMinutes minutes' : '');

      text = 'I am on my way to $destinationName $modeText $timeText.\n'
          'You can track the trip on Guidy:\n'
          '$appUrl';
    }

    final box = context.findRenderObject() as RenderBox?;
    // ignore: deprecated_member_use
    return Share.share(
      text,
      subject: lang == 'ar' ? 'مشاركة تفاصيل مشواري' : 'Trip Details',
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }
}
