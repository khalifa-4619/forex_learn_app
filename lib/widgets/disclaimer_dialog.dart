import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DisclaimerDialog {
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Risk Disclaimer'),
        content: const Text(
          'Forex trading involves substantial risk of loss and is not suitable for all investors. '
          'This app provides educational content only and does not guarantee profits or financial success. '
          'You should carefully consider your financial situation before trading.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}