import 'package:flutter/material.dart';

import '../../models/workspace_model.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class WorkspacesPanel extends StatelessWidget {
  final List<WorkspaceModel> workspaces;
  final VoidCallback onCreateWorkspace;
  final void Function(WorkspaceModel workspace) onOpenWorkspace;
  final void Function(WorkspaceModel workspace) onDeleteWorkspace;

  const WorkspacesPanel({
    super.key,
    required this.workspaces,
    required this.onCreateWorkspace,
    required this.onOpenWorkspace,
    required this.onDeleteWorkspace,
  });

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Workspaces IA',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: onCreateWorkspace,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear workspace'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (workspaces.isEmpty)
          SectionCard(
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_mosaic_rounded,
                  color: AppTheme.accent,
                  size: 38,
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Text(
                    'Crea espacios inteligentes para agrupar documentos por proyecto, investigación, materia o tema.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onCreateWorkspace,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
          )
        else
          ...workspaces.map(
            (workspace) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SectionCard(
                onTap: () => onOpenWorkspace(workspace),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.folder_special_rounded,
                            color: AppTheme.accent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                workspace.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.card,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${workspace.documents.length} documentos',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Text(
                                    'Actualizado ${formatDate(workspace.updatedAt)}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () =>
                              onDeleteWorkspace(workspace),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                onOpenWorkspace(workspace),
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                            ),
                            label: const Text(
                              'Abrir workspace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
