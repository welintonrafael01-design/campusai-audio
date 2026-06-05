import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

void showUpgradeRequired(
  BuildContext context, {
  required String featureName,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'La función "$featureName" requiere actualizar tu plan.',
      ),
      action: SnackBarAction(
        label: 'Ver planes',
        onPressed: () {
          context.go('/plans');
        },
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.textPrimary,
    ),
  );
}
