class SemanticSearchModel {
  final String documentId;
  final int chunkIndex;
  final double distance;
  final String preview;

  const SemanticSearchModel({
    required this.documentId,
    required this.chunkIndex,
    required this.distance,
    required this.preview,
  });

  factory SemanticSearchModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return SemanticSearchModel(
      documentId:
          map['document_id'] ?? '',
      chunkIndex:
          map['chunk_index'] ?? 0,
      distance:
          (map['distance'] ?? 0)
              .toDouble(),
      preview:
          map['preview'] ?? '',
    );
  }
}
