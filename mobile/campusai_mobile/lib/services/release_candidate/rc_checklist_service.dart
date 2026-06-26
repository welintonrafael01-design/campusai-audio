import 'rc_models.dart';

class RcChecklistService {
  const RcChecklistService();

  List<RcChecklistItem> buildChecklist() => const [
        RcChecklistItem(
          id: 'backend_compile',
          title: 'Backend compila con py_compile',
        ),
        RcChecklistItem(
          id: 'flutter_analyze',
          title: 'Flutter analyze sin errores',
        ),
        RcChecklistItem(
            id: 'manual_smoke', title: 'Smoke test manual completo'),
        RcChecklistItem(id: 'security_scan', title: 'Security scan revisado'),
        RcChecklistItem(
          id: 'performance_review',
          title: 'Performance readiness revisado',
        ),
        RcChecklistItem(id: 'rollback_plan', title: 'Rollback documentado'),
      ];
}
