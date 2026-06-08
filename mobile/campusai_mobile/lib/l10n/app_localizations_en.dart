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

  @override
  String get uploadAtLeastOneDocument =>
      'You must upload at least one document first.';

  @override
  String get selectAtLeastOneDocument =>
      'You must select at least one document.';

  @override
  String get workspaceCreatedFromStudyBook =>
      'Workspace created from StudyBook AI';

  @override
  String get cloudConversation => 'Cloud conversation';

  @override
  String get conversationWithoutDocument =>
      'This conversation has no associated document.';

  @override
  String get workspaceWithoutDocuments => 'This workspace has no documents.';

  @override
  String get workspaceWithoutValidDocuments =>
      'This workspace has no valid documents.';

  @override
  String get defaultPdfDocumentName => 'PDF document';

  @override
  String get summaryNotReceived => 'No summary was received.';

  @override
  String get audioGenerationErrorPrefix => 'Audio could not be generated';

  @override
  String get audioPlaybackErrorPrefix => 'Audio could not be played';

  @override
  String get audioReplayErrorPrefix => 'Audio could not be restarted';

  @override
  String get documentLoaded => 'Document loaded';

  @override
  String get documentDeletedFromHistory => 'Document removed from history.';

  @override
  String get historyDeleted => 'History cleared.';

  @override
  String get searchResult => 'Search result';

  @override
  String get uploadOrSelectDocumentFirst =>
      'Upload or select a document first.';

  @override
  String get activeDocument => 'Active document';

  @override
  String get createWorkspace => 'Create workspace';

  @override
  String get workspaceName => 'Workspace name';

  @override
  String get workspaceNameHint => 'E.g.: Thesis, Criminal Law, Final project';

  @override
  String get selectDocuments => 'Select documents';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get myWorkspace => 'My workspace';

  @override
  String get heroSubtitle => 'Your intelligent AI study hub.';

  @override
  String get docsShort => 'Docs';

  @override
  String get ragReady => 'Ready';

  @override
  String get ragActive => 'Active';

  @override
  String get aiTools => 'AI Tools';

  @override
  String get aiToolsSubtitle => 'Explore intelligent features to study faster.';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get uploadPdfDescription => 'Upload documents to summarize with AI.';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get aiChatDescription => 'Ask questions about the active document.';

  @override
  String get aiExam => 'AI Exam';

  @override
  String get aiExamDescription => 'Generate automatic questions.';

  @override
  String get flashcardsDescription => 'Create smart study cards.';

  @override
  String get documents => 'Documents';

  @override
  String get aiStatus => 'AI Status';

  @override
  String get noDocument => 'No document';

  @override
  String get ready => 'Ready';

  @override
  String get recentDocuments => 'Recent documents';

  @override
  String get aiWorkspaces => 'AI Workspaces';

  @override
  String get createWorkspaceButton => 'Create workspace';

  @override
  String get newWorkspace => 'New';

  @override
  String get workspaceEmptyDescription =>
      'Create intelligent spaces to group documents by project, research, subject, or topic.';

  @override
  String get documentCountLabel => 'documents';

  @override
  String get updatedAt => 'Updated';

  @override
  String get openWorkspace => 'Open workspace';

  @override
  String get recentConversations => 'Recent conversations';

  @override
  String get renameConversation => 'Rename conversation';

  @override
  String get newName => 'New name';

  @override
  String get save => 'Save';

  @override
  String get renameConversationError =>
      'The conversation could not be renamed.';

  @override
  String get deleteConversationError =>
      'The conversation could not be deleted.';

  @override
  String get loadingConversations => 'Loading conversations...';

  @override
  String get noSavedConversations => 'You do not have saved conversations yet.';

  @override
  String get untitledConversation => 'Untitled conversation';

  @override
  String get deleteConversation => 'Delete conversation';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get historyEmptyDescription => 'Uploaded documents will appear here.';

  @override
  String get recentHistory => 'Recent history';

  @override
  String get historyHint => 'Tap a document to activate it again.';

  @override
  String get clear => 'Clear';
}
