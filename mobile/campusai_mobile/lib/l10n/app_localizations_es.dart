// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'StudyBook AI';

  @override
  String get dashboardTitle => 'Panel principal';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get plansTitle => 'Planes';

  @override
  String get chatTitle => 'Chat';

  @override
  String get examTitle => 'Exámenes';

  @override
  String get flashcardsTitle => 'Flashcards';

  @override
  String get uploadDocument => 'Subir documento';

  @override
  String get currentPlan => 'Plan actual';

  @override
  String get manageSubscription => 'Administrar suscripción';

  @override
  String get syncPlan => 'Sincronizar plan';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get language => 'Idioma';

  @override
  String get preferences => 'Preferencias';

  @override
  String get settingsSubtitle => 'Personaliza tu experiencia StudyBook AI.';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get darkModeDescription => 'Cambia entre tema claro y oscuro.';

  @override
  String get languageDescription => 'Selecciona el idioma de la aplicación.';

  @override
  String get clearHistory => 'Limpiar historial';

  @override
  String get clearHistoryDescription => 'Elimina documentos y datos locales.';

  @override
  String get historyCleared => 'Historial eliminado correctamente.';

  @override
  String get planAndSubscription => 'Plan y suscripción';

  @override
  String get planAndSubscriptionDescription =>
      'Sincroniza tu plan real desde Supabase. El selector manual solo se activa en modo desarrollo.';

  @override
  String get syncReal => 'Sincronizar real';

  @override
  String get useFree => 'Usar Free';

  @override
  String get usePro => 'Usar Pro';

  @override
  String get useEducator => 'Usar Educator';

  @override
  String get usageTitle => 'Uso del plan';

  @override
  String get loadingPlanUsage => 'Cargando uso del plan...';

  @override
  String get activePlan => 'Plan activo';

  @override
  String get pdfsUploadedToday => 'PDFs subidos hoy';

  @override
  String get chatMessagesToday => 'Mensajes de chat hoy';

  @override
  String get exams => 'Exámenes';

  @override
  String get exports => 'Exportaciones';

  @override
  String get today => 'hoy';

  @override
  String get perPdf => 'por PDF';
}
