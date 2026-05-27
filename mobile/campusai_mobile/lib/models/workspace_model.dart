import 'recent_document_model.dart';

class WorkspaceModel {
  final String workspaceId;
  final String name;
  final List<RecentDocumentModel> documents;
  final DateTime updatedAt;

  const WorkspaceModel({
    required this.workspaceId,
    required this.name,
    required this.documents,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'workspaceId': workspaceId,
      'name': name,
      'documents': documents.map((item) => item.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    final rawDocuments = json['documents'];

    return WorkspaceModel(
      workspaceId: json['workspaceId'] ?? '',
      name: json['name'] ?? 'Workspace',
      documents: rawDocuments is List
          ? rawDocuments
              .map((item) => RecentDocumentModel.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList()
          : [],
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
