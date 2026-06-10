import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/workspace_model.dart';
import '../../services/cloud_api_service.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class WorkspacesPanel extends StatefulWidget {
  final List<WorkspaceModel> workspaces;
  final VoidCallback onCreateWorkspace;
  final void Function(WorkspaceModel workspace) onOpenWorkspace;
  final void Function(Map<String, dynamic> chat) onOpenChat;
  final void Function(WorkspaceModel workspace) onAddDocuments;
  final void Function(WorkspaceModel workspace) onRenameWorkspace;
  final void Function(WorkspaceModel workspace, String documentId)
      onRemoveDocument;
  final void Function(WorkspaceModel workspace) onDeleteWorkspace;

  const WorkspacesPanel({
    super.key,
    required this.workspaces,
    required this.onCreateWorkspace,
    required this.onOpenWorkspace,
    required this.onOpenChat,
    required this.onAddDocuments,
    required this.onRenameWorkspace,
    required this.onRemoveDocument,
    required this.onDeleteWorkspace,
  });

  @override
  State<WorkspacesPanel> createState() => _WorkspacesPanelState();
}

class _WorkspacesPanelState extends State<WorkspacesPanel> {
  final Set<String> expandedWorkspaceIds = {};

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool isExpanded(WorkspaceModel workspace) {
    return expandedWorkspaceIds.contains(workspace.workspaceId);
  }

  void toggleExpanded(WorkspaceModel workspace) {
    setState(() {
      if (expandedWorkspaceIds.contains(workspace.workspaceId)) {
        expandedWorkspaceIds.remove(workspace.workspaceId);
      } else {
        expandedWorkspaceIds.add(workspace.workspaceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.aiWorkspaces,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: widget.onCreateWorkspace,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.createWorkspaceButton),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (widget.workspaces.isEmpty)
          SectionCard(
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_mosaic_rounded,
                  color: AppTheme.accent,
                  size: 38,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    l10n.workspaceEmptyDescription,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.onCreateWorkspace,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.newWorkspace),
                ),
              ],
            ),
          )
        else
          ...widget.workspaces.map(
            (workspace) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SectionCard(
                onTap: () => toggleExpanded(workspace),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${workspace.documents.length} ${l10n.documentCountLabel}',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _WorkspaceChatCount(
                                    workspaceId: workspace.workspaceId,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${l10n.updatedAt} ${formatDate(workspace.updatedAt)}',
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
                          tooltip: isExpanded(workspace)
                              ? 'Contraer workspace'
                              : 'Expandir workspace',
                          onPressed: () => toggleExpanded(workspace),
                          icon: Icon(
                            isExpanded(workspace)
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Renombrar workspace',
                          onPressed: () => widget.onRenameWorkspace(workspace),
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Eliminar workspace',
                          onPressed: () => widget.onDeleteWorkspace(workspace),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (isExpanded(workspace)) ...[
                      const SizedBox(height: 14),
                      _WorkspaceDocumentsPreview(
                        documents: workspace.documents,
                        onRemoveDocument: (documentId) {
                          widget.onRemoveDocument(workspace, documentId);
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  widget.onOpenWorkspace(workspace),
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                              ),
                              label: Text(
                                l10n.openWorkspace,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => widget.onAddDocuments(workspace),
                              icon: const Icon(
                                Icons.add_rounded,
                              ),
                              label: const Text(
                                'Agregar PDFs',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WorkspaceChatCount extends StatefulWidget {
  final String workspaceId;

  const _WorkspaceChatCount({
    required this.workspaceId,
  });

  @override
  State<_WorkspaceChatCount> createState() => _WorkspaceChatCountState();
}

class _WorkspaceChatCountState extends State<_WorkspaceChatCount> {
  int chatCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCount();
  }

  Future<void> loadCount() async {
    try {
      final chats = await CloudApiService.getChats(
        workspaceId: widget.workspaceId,
      );

      if (!mounted) return;

      setState(() {
        chatCount = chats.length;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        chatCount = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppTheme.accent,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            isLoading ? '...' : '$chatCount chats',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceDocumentsPreview extends StatelessWidget {
  final List<dynamic> documents;
  final void Function(String documentId) onRemoveDocument;

  const _WorkspaceDocumentsPreview({
    required this.documents,
    required this.onRemoveDocument,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleDocuments = documents.take(4).toList();
    final remaining = documents.length - visibleDocuments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos incluidos',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...visibleDocuments.map(
              (document) {
                final fileName = document.fileName?.toString() ?? 'Documento';
                final documentId = document.documentId?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppTheme.accent,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 190,
                        ),
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: documentId.isEmpty
                            ? null
                            : () => onRemoveDocument(documentId),
                        child: const Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppTheme.textMuted,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (remaining > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '+$remaining más',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
