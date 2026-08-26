import 'package:flutter/material.dart';

import 'studybook/studybook_states.dart';

class AccessibleEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const AccessibleEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = '',
    this.onAction,
    this.icon = Icons.accessibility_new_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return StudyBookEmptyState(
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
    );
  }
}
