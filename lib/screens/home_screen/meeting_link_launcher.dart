import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import '../../utils/color_constants/color_constants.dart';

Future<void> launchMeetingLink(BuildContext context, String link) async {
  if (link.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meeting link not available'),
        backgroundColor: ColorConstants.redColor,
      ),
    );
    return;
  }

  try {
    String normalized = link.trim();
    if (!normalized.startsWith('http')) {
      normalized = 'https://$normalized';
    }
    final codeMatch = RegExp(r'([a-z]{3}-[a-z]{4}-[a-z]{3})').firstMatch(normalized);
    if (codeMatch != null) {
      normalized = 'https://meet.google.com/${codeMatch.group(1)}';
    }

    Uri uri = Uri.parse(normalized);
    if (uri.host.contains('meet.google.com') && Platform.isAndroid) {
      try {
        final meetIntent = AndroidIntent(
          action: 'action_view',
          data: normalized,
          package: 'com.google.android.apps.meetings',
        );
        await meetIntent.launch();
        return;
      } catch (_) {}
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open meeting link'),
          backgroundColor: ColorConstants.redColor,
        ),
      );
    }
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to open meeting link'),
        backgroundColor: ColorConstants.redColor,
      ),
    );
  }
}
