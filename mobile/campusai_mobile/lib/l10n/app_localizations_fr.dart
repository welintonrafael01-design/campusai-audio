// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'StudyBook AI';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get plansTitle => 'Forfaits';

  @override
  String get chatTitle => 'Chat';

  @override
  String get examTitle => 'Examens';

  @override
  String get flashcardsTitle => 'Flashcards';

  @override
  String get uploadDocument => 'Importer un document';

  @override
  String get currentPlan => 'Forfait actuel';

  @override
  String get manageSubscription => 'Gérer l’abonnement';

  @override
  String get syncPlan => 'Synchroniser le forfait';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get language => 'Langue';

  @override
  String get preferences => 'Préférences';

  @override
  String get settingsSubtitle => 'Personnalisez votre expérience StudyBook AI.';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get darkModeDescription => 'Basculez entre le thème clair et sombre.';

  @override
  String get languageDescription => 'Sélectionnez la langue de l’application.';

  @override
  String get clearHistory => 'Effacer l’historique';

  @override
  String get clearHistoryDescription =>
      'Supprime les documents et données locaux.';

  @override
  String get historyCleared => 'Historique supprimé correctement.';

  @override
  String get planAndSubscription => 'Forfait et abonnement';

  @override
  String get planAndSubscriptionDescription =>
      'Synchronisez votre forfait réel depuis Supabase. Le sélecteur manuel n’est activé qu’en mode développement.';

  @override
  String get syncReal => 'Synchroniser le forfait';

  @override
  String get useFree => 'Utiliser Free';

  @override
  String get usePro => 'Utiliser Pro';

  @override
  String get useEducator => 'Utiliser Educator';

  @override
  String get usageTitle => 'Utilisation du forfait';

  @override
  String get loadingPlanUsage => 'Chargement de l’utilisation du forfait...';

  @override
  String get activePlan => 'Forfait actif';

  @override
  String get pdfsUploadedToday => 'PDFs importés aujourd’hui';

  @override
  String get chatMessagesToday => 'Messages de chat aujourd’hui';

  @override
  String get exams => 'Examens';

  @override
  String get exports => 'Exportations';

  @override
  String get today => 'aujourd’hui';

  @override
  String get perPdf => 'par PDF';
}
