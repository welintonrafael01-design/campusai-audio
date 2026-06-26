import 'qa_models.dart';

class QaManualChecklistService {
  const QaManualChecklistService();

  List<QaManualChecklistItem> buildChecklist() => const [
        QaManualChecklistItem(title: 'Validar login/logout', area: 'Auth'),
        QaManualChecklistItem(title: 'Cargar Dashboard', area: 'Core'),
        QaManualChecklistItem(
          title: 'Crear curso y plan docente',
          area: 'Teacher Studio',
        ),
        QaManualChecklistItem(
          title: 'Generar recursos por unidad',
          area: 'Academic Engine',
        ),
        QaManualChecklistItem(
          title: 'Abrir Student Dashboard',
          area: 'Student Studio',
        ),
        QaManualChecklistItem(title: 'Probar Voice Tutor texto', area: 'Voice'),
        QaManualChecklistItem(
          title: 'Probar Voice Tutor micrófono',
          area: 'Voice',
        ),
        QaManualChecklistItem(
          title: 'Abrir Marketplace local',
          area: 'Marketplace',
        ),
        QaManualChecklistItem(
          title: 'Abrir Institution local',
          area: 'Institution',
        ),
        QaManualChecklistItem(
            title: 'Verificar billing básico', area: 'Billing'),
      ];
}
