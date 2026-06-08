// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'StudyBook AI';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get plansTitle => 'Plans';

  @override
  String get chatTitle => 'Chat';

  @override
  String get examTitle => 'Exams';

  @override
  String get flashcardsTitle => 'Flashcards';

  @override
  String get uploadDocument => 'Upload document';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get syncPlan => 'Sync plan';

  @override
  String get signOut => 'Sign out';

  @override
  String get language => 'Language';

  @override
  String get preferences => 'Preferences';

  @override
  String get settingsSubtitle => 'Customize your StudyBook AI experience.';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeDescription => 'Switch between light and dark theme.';

  @override
  String get languageDescription => 'Select the app language.';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryDescription => 'Delete local documents and data.';

  @override
  String get historyCleared => 'History cleared successfully.';

  @override
  String get planAndSubscription => 'Plan and subscription';

  @override
  String get planAndSubscriptionDescription =>
      'Sync your real plan from Supabase. The manual selector is only enabled in development mode.';

  @override
  String get syncReal => 'Sync real plan';

  @override
  String get useFree => 'Use Free';

  @override
  String get usePro => 'Use Pro';

  @override
  String get useEducator => 'Use Educator';

  @override
  String get usageTitle => 'Plan usage';

  @override
  String get loadingPlanUsage => 'Loading plan usage...';

  @override
  String get activePlan => 'Active plan';

  @override
  String get pdfsUploadedToday => 'PDFs uploaded today';

  @override
  String get chatMessagesToday => 'Chat messages today';

  @override
  String get exams => 'Exams';

  @override
  String get exports => 'Exports';

  @override
  String get today => 'today';

  @override
  String get perPdf => 'per PDF';
}
