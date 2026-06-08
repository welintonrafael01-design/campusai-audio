import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

void showUpgradeRequired(
  BuildContext context, {
  required String featureName,
}) {
  final l10n = AppLocalizations.of(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        l10n.upgradeRequiredMessage(featureName),
      ),
      action: SnackBarAction(
        label: l10n.viewPlans,
        onPressed: () {
          context.go('/plans');
        },
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.textPrimary,
    ),
  );
}
