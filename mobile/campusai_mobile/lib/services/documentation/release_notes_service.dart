import '../campus_intelligence/enterprise_result_repository.dart';
import 'documentation_models.dart';

class ReleaseNotesService {
  final EnterpriseResultRepository repository;
  const ReleaseNotesService({
    this.repository = const EnterpriseResultRepository(),
  });

  Future<ReleaseNote> buildRc1Notes() async {
    final notes = ReleaseNote(
      date: DateTime.now(),
      highlights: const [
        'RC1 readiness foundation',
        'QA scenario inventory',
        'Performance readiness checks',
        'Security scan hardening',
        'Documentation inventory',
      ],
      knownRisks: const [
        'Marketplace e Institution siguen local-first/foundation',
        'Voice streaming real queda fuera de RC1',
      ],
    );
    await repository.save(
      documentId: 'release_notes_rc1',
      type: 'release_notes',
      payload: notes.toJson(),
    );
    return notes;
  }
}
