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
      'Collection created from StudyBook AI';

  @override
  String get cloudConversation => 'Cloud conversation';

  @override
  String get conversationWithoutDocument =>
      'This conversation has no associated document.';

  @override
  String get workspaceWithoutDocuments => 'This collection has no documents.';

  @override
  String get workspaceWithoutValidDocuments =>
      'This collection has no valid documents.';

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
  String get createWorkspace => 'Create collection';

  @override
  String get workspaceName => 'Collection name';

  @override
  String get workspaceNameHint => 'E.g.: Thesis, Criminal Law, Final project';

  @override
  String get selectDocuments => 'Select documents';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get myWorkspace => 'My collection';

  @override
  String get heroSubtitle => 'Your intelligent AI study hub.';

  @override
  String get docsShort => 'Docs';

  @override
  String get ragReady => 'Ready';

  @override
  String get ragActive => 'Content connected';

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
  String get aiWorkspaces => 'AI collections';

  @override
  String get createWorkspaceButton => 'Create collection';

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
  String get openWorkspace => 'Open collection';

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

  @override
  String get generatedAudio => 'Generated audio';

  @override
  String get audioNotGeneratedSubtitle =>
      'Turn the summary into an audio lesson.';

  @override
  String get audioGeneratedSubtitle =>
      'Listen to the summary as an audio lesson.';

  @override
  String get audioNotGeneratedDescription =>
      'The audio has not been generated yet. You can create it now without blocking the document load.';

  @override
  String get generating => 'Generating...';

  @override
  String get generateAudio => 'Generate audio';

  @override
  String get smartAudiobook => 'Smart audiobook';

  @override
  String get pauseAudio => 'Pause audio';

  @override
  String get playAudio => 'Play audio';

  @override
  String get aiSummary => 'AI Summary';

  @override
  String get summarySubtitle => 'Clear synthesis of the uploaded document.';

  @override
  String get exportSummaryToWord => 'Export summary to Word';

  @override
  String get exportSummaryToPowerPoint => 'Export summary to PowerPoint';

  @override
  String get exportSummaryToPdf => 'Export summary to PDF';

  @override
  String get processingDocument => 'Processing document...';

  @override
  String get processingDocumentDescription =>
      'Preparing the document summary, audio, and sources.';

  @override
  String get activeWorkspace => 'Active collection';

  @override
  String get documentReadyToStudy => 'Document ready to study';

  @override
  String get aiReady => 'AI ready';

  @override
  String get audioAvailable => 'Audio available';

  @override
  String get openAiChat => 'Open AI Chat';

  @override
  String workspaceChatWelcome(Object count) {
    return 'Hi. I am StudyBook AI.\n\nI am ready to help you study this collection with $count documents.\n\nYou can ask for comparisons, cross-document summaries, or combined analysis.';
  }

  @override
  String documentChatWelcome(Object fileName) {
    return 'Hi. I am StudyBook AI.\n\nI am ready to help you understand the document \"$fileName\".\n\nYou can ask questions, request explanations, summaries, key concepts, or academic analysis.';
  }

  @override
  String get noAnswerReceived => 'No answer was received.';

  @override
  String get chatTemporaryError =>
      'I could not answer right now.\n\nCheck the backend connection or try again.';

  @override
  String get exportChatToWord => 'Export chat to Word';

  @override
  String get exportChatToPdf => 'Export chat to PDF';

  @override
  String get userRole => 'User';

  @override
  String get noContentToExport => 'There is no content to export.';

  @override
  String get chatExportWordError => 'Word export failed';

  @override
  String get chatExportPdfError => 'PDF export failed';

  @override
  String get chatTitlePrefix => 'Chat';

  @override
  String get workspaceAiChat => 'Collection chat';

  @override
  String get contextualAiChat => 'Contextual AI chat';

  @override
  String get activeContext => 'Active context';

  @override
  String get workspaceRagContext =>
      'Answers based on the documents in this collection.';

  @override
  String get documentRagContext => 'Answers based on the selected document.';

  @override
  String get contextHintConcepts =>
      'You can ask for key concepts, a simple explanation, or a summary.';

  @override
  String get contextHintAcademic =>
      'You can also request academic analysis of the content.';

  @override
  String get contextHintSources => 'Answers are based on the active document.';

  @override
  String get examSubtitle => 'Practice, answer, and measure your learning.';

  @override
  String get exportWord => 'Export Word';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExamToPdf => 'Export exam to PDF';

  @override
  String get exportExamToWord => 'Export exam to Word';

  @override
  String get examEmptyPrompt =>
      'Press the button to generate an exam from the active document.';

  @override
  String get questionNotAvailable => 'Question not available.';

  @override
  String get notSpecifiedInDocument => 'Not specified in the document.';

  @override
  String get allOfTheAbove => 'All of the above.';

  @override
  String get noneOfTheAbove => 'None of the above.';

  @override
  String questionOf(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get answerLabel => 'Answer';

  @override
  String get restart => 'Restart';

  @override
  String get viewResult => 'View result';

  @override
  String get next => 'Next';

  @override
  String get verify => 'Verify';

  @override
  String get correct => 'Correct';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get correctAnswer => 'Correct answer';

  @override
  String get finalResult => 'Final result';

  @override
  String get retakeExam => 'Retake exam';

  @override
  String get generateExam => 'Generate exam';

  @override
  String get regenerateExam => 'Regenerate exam';

  @override
  String get generatingExam => 'Generating exam with AI...';

  @override
  String get examExportQuestion => 'QUESTION';

  @override
  String get examExportOptions => 'OPTIONS';

  @override
  String get examExportCorrectAnswer => 'CORRECT ANSWER';

  @override
  String get examExportExplanation => 'EXPLANATION';

  @override
  String get flashcardsAiTitle => 'AI Flashcards';

  @override
  String get flashcardsSubtitle => 'Premium study mode with 3D cards.';

  @override
  String get exportFlashcardsToPdf => 'Export flashcards to PDF';

  @override
  String get exportFlashcardsToWord => 'Export flashcards to Word';

  @override
  String get answerNotAvailable => 'Answer not available.';

  @override
  String get flashcardQuestion => 'Question';

  @override
  String get flashcardAnswer => 'Answer';

  @override
  String get tapToSeeAnswer => 'Tap to see the answer';

  @override
  String get tapToReturnQuestion => 'Tap to return to the question';

  @override
  String get previous => 'Previous';

  @override
  String get flashcardsEmptyPrompt =>
      'Press the button to generate flashcards from the active document.';

  @override
  String get generateFlashcards => 'Generate flashcards';

  @override
  String get regenerateFlashcards => 'Regenerate flashcards';

  @override
  String get generatingFlashcards => 'Generating cards with AI...';

  @override
  String get plansStudyBookTitle => 'StudyBook AI Plans';

  @override
  String checkoutSuccessMessage(Object planName) {
    return 'Payment completed successfully. Your current plan is $planName.';
  }

  @override
  String get checkoutCancelMessage => 'Payment canceled.';

  @override
  String get checkoutTestModeMessage =>
      'Your payment request was processed by Stripe in test mode.';

  @override
  String get plansIntro =>
      'Choose the plan that fits the way you study or teach.';

  @override
  String paymentStartError(Object planName) {
    return 'We couldn\'t start payment for $planName. Please try again.';
  }

  @override
  String get pdfsPerDay => 'PDFs per day';

  @override
  String get chatsPerDay => 'Chats per day';

  @override
  String get flashcardsPerPdf => 'Flashcards per PDF';

  @override
  String get examQuestionsPerPdf => 'Exam questions per PDF';

  @override
  String get exportDocx => 'Export DOCX';

  @override
  String get exportPptx => 'Export PPTX';

  @override
  String get advancedAnalytics => 'Advanced analytics';

  @override
  String get teacherTools => 'Teacher tools';

  @override
  String get guidedVoice => 'Guided voice';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String upgradeToPlan(Object planName) {
    return 'Upgrade to $planName';
  }

  @override
  String get completeEmailAndPassword => 'Complete email and password.';

  @override
  String get loginSubtitle => 'Sign in to continue.';

  @override
  String get signupSubtitle => 'Create your account to get started.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get premiumAi => 'Premium AI';

  @override
  String get premiumAiDescription =>
      'Full AI reading and cloud sync coming soon.';

  @override
  String upgradeRequiredMessage(Object featureName) {
    return 'To use \"$featureName\", you need to upgrade your plan.';
  }

  @override
  String get viewPlans => 'View plans';

  @override
  String get askAboutDocumentHint => 'Ask about the document...';

  @override
  String get answerCopied => 'Answer copied to clipboard.';

  @override
  String get aiThinking => 'StudyBook AI is thinking...';

  @override
  String get sourceLoadError => 'Could not load the source';

  @override
  String get unknownConfidence => 'Unknown confidence';

  @override
  String get highConfidence => 'High confidence';

  @override
  String get mediumConfidence => 'Medium confidence';

  @override
  String get lowConfidence => 'Low confidence';

  @override
  String get pdfOpenError => 'Could not open the PDF.';

  @override
  String get sourceCopied => 'Source copied to clipboard.';

  @override
  String get citedSource => 'Cited source';

  @override
  String get copySource => 'Copy source';

  @override
  String get close => 'Close';

  @override
  String get document => 'Document';

  @override
  String get page => 'Page';

  @override
  String get chunk => 'Chunk';

  @override
  String get metadata => 'Metadata';

  @override
  String get fields => 'fields';

  @override
  String get originalFragment => 'Original fragment';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get smartSearch => 'Smart Search';

  @override
  String get searchAllDocumentsHint => 'Search all documents...';

  @override
  String get search => 'Search';

  @override
  String get score => 'Score';

  @override
  String get voiceMode => 'Voice mode';

  @override
  String get startListening => 'Speak';

  @override
  String get stopListening => 'Stop';

  @override
  String get listening => 'Listening...';

  @override
  String get voiceNotAvailable =>
      'Speech recognition is not available in this browser.';

  @override
  String get microphonePermissionDenied => 'Microphone permission denied.';

  @override
  String get voiceInputTooltip => 'Dictate question by voice';

  @override
  String get voiceModeActive => 'Voice mode active';

  @override
  String get voiceModeInactive => 'Voice mode inactive';

  @override
  String get voiceModeReady =>
      'Speak your question. It will be sent automatically when the microphone stops.';

  @override
  String get voiceAnswerGeneratingAudio => 'Generating audio response...';

  @override
  String get voiceAnswerPlaybackError => 'Could not play the audio response';

  @override
  String get voiceAnswerAudioTitle => 'StudyBook AI response';

  @override
  String get listenAnswer => 'Listen to answer';

  @override
  String get generatingAnswerAudio => 'Generating answer audio...';

  @override
  String get answerAudioError => 'Could not generate or play the answer audio';

  @override
  String get aiAudio => 'AI Audio';

  @override
  String get premiumFeatureTitle => 'Premium Feature';

  @override
  String get premiumFeatureDescription =>
      'Unlock more StudyBook AI tools to study, listen, and work with your documents in a more advanced way.';

  @override
  String get premiumBenefitAudio => 'Listen to summaries and answers in audio.';

  @override
  String get premiumBenefitVoice => 'Use voice mode to ask without typing.';

  @override
  String get premiumBenefitExports => 'Access exports and advanced features.';

  @override
  String get notNow => 'Not now';

  @override
  String get upgradePlan => 'Upgrade plan';
}
