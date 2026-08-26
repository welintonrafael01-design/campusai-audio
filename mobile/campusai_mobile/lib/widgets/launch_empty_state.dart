import 'package:flutter/material.dart';

import 'studybook/studybook_states.dart';

class LaunchEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onAction;

  const LaunchEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = '',
    this.icon = Icons.rocket_launch_outlined,
    this.onAction,
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
