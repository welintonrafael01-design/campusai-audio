import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'StudyBook AI'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel principal'**
  String get dashboardTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @plansTitle.
  ///
  /// In es, this message translates to:
  /// **'Planes'**
  String get plansTitle;

  /// No description provided for @chatTitle.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @examTitle.
  ///
  /// In es, this message translates to:
  /// **'Exámenes'**
  String get examTitle;

  /// No description provided for @flashcardsTitle.
  ///
  /// In es, this message translates to:
  /// **'Flashcards'**
  String get flashcardsTitle;

  /// No description provided for @uploadDocument.
  ///
  /// In es, this message translates to:
  /// **'Subir documento'**
  String get uploadDocument;

  /// No description provided for @currentPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan actual'**
  String get currentPlan;

  /// No description provided for @manageSubscription.
  ///
  /// In es, this message translates to:
  /// **'Administrar suscripción'**
  String get manageSubscription;

  /// No description provided for @syncPlan.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar plan'**
  String get syncPlan;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @preferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get preferences;

  /// No description provided for @settingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Personaliza tu experiencia StudyBook AI.'**
  String get settingsSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get darkMode;

  /// No description provided for @darkModeDescription.
  ///
  /// In es, this message translates to:
  /// **'Cambia entre tema claro y oscuro.'**
  String get darkModeDescription;

  /// No description provided for @languageDescription.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el idioma de la aplicación.'**
  String get languageDescription;

  /// No description provided for @clearHistory.
  ///
  /// In es, this message translates to:
  /// **'Limpiar historial'**
  String get clearHistory;

  /// No description provided for @clearHistoryDescription.
  ///
  /// In es, this message translates to:
  /// **'Elimina documentos y datos locales.'**
  String get clearHistoryDescription;

  /// No description provided for @historyCleared.
  ///
  /// In es, this message translates to:
  /// **'Historial eliminado correctamente.'**
  String get historyCleared;

  /// No description provided for @planAndSubscription.
  ///
  /// In es, this message translates to:
  /// **'Plan y suscripción'**
  String get planAndSubscription;

  /// No description provided for @planAndSubscriptionDescription.
  ///
  /// In es, this message translates to:
  /// **'Sincroniza tu plan real desde Supabase. El selector manual solo se activa en modo desarrollo.'**
  String get planAndSubscriptionDescription;

  /// No description provided for @syncReal.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar real'**
  String get syncReal;

  /// No description provided for @useFree.
  ///
  /// In es, this message translates to:
  /// **'Usar Free'**
  String get useFree;

  /// No description provided for @usePro.
  ///
  /// In es, this message translates to:
  /// **'Usar Pro'**
  String get usePro;

  /// No description provided for @useEducator.
  ///
  /// In es, this message translates to:
  /// **'Usar Educator'**
  String get useEducator;

  /// No description provided for @usageTitle.
  ///
  /// In es, this message translates to:
  /// **'Uso del plan'**
  String get usageTitle;

  /// No description provided for @loadingPlanUsage.
  ///
  /// In es, this message translates to:
  /// **'Cargando uso del plan...'**
  String get loadingPlanUsage;

  /// No description provided for @activePlan.
  ///
  /// In es, this message translates to:
  /// **'Plan activo'**
  String get activePlan;

  /// No description provided for @pdfsUploadedToday.
  ///
  /// In es, this message translates to:
  /// **'PDFs subidos hoy'**
  String get pdfsUploadedToday;

  /// No description provided for @chatMessagesToday.
  ///
  /// In es, this message translates to:
  /// **'Mensajes de chat hoy'**
  String get chatMessagesToday;

  /// No description provided for @exams.
  ///
  /// In es, this message translates to:
  /// **'Exámenes'**
  String get exams;

  /// No description provided for @exports.
  ///
  /// In es, this message translates to:
  /// **'Exportaciones'**
  String get exports;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'hoy'**
  String get today;

  /// No description provided for @perPdf.
  ///
  /// In es, this message translates to:
  /// **'por PDF'**
  String get perPdf;

  /// No description provided for @uploadAtLeastOneDocument.
  ///
  /// In es, this message translates to:
  /// **'Primero debes subir al menos un documento.'**
  String get uploadAtLeastOneDocument;

  /// No description provided for @selectAtLeastOneDocument.
  ///
  /// In es, this message translates to:
  /// **'Debes seleccionar al menos un documento.'**
  String get selectAtLeastOneDocument;

  /// No description provided for @workspaceCreatedFromStudyBook.
  ///
  /// In es, this message translates to:
  /// **'Workspace creado desde StudyBook AI'**
  String get workspaceCreatedFromStudyBook;

  /// No description provided for @cloudConversation.
  ///
  /// In es, this message translates to:
  /// **'Conversación cloud'**
  String get cloudConversation;

  /// No description provided for @conversationWithoutDocument.
  ///
  /// In es, this message translates to:
  /// **'Esta conversación no tiene documento asociado.'**
  String get conversationWithoutDocument;

  /// No description provided for @workspaceWithoutDocuments.
  ///
  /// In es, this message translates to:
  /// **'Este workspace no tiene documentos.'**
  String get workspaceWithoutDocuments;

  /// No description provided for @workspaceWithoutValidDocuments.
  ///
  /// In es, this message translates to:
  /// **'Este workspace no tiene documentos válidos.'**
  String get workspaceWithoutValidDocuments;

  /// No description provided for @defaultPdfDocumentName.
  ///
  /// In es, this message translates to:
  /// **'Documento PDF'**
  String get defaultPdfDocumentName;

  /// No description provided for @summaryNotReceived.
  ///
  /// In es, this message translates to:
  /// **'No se recibió resumen.'**
  String get summaryNotReceived;

  /// No description provided for @audioGenerationErrorPrefix.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar el audio'**
  String get audioGenerationErrorPrefix;

  /// No description provided for @audioPlaybackErrorPrefix.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reproducir el audio'**
  String get audioPlaybackErrorPrefix;

  /// No description provided for @audioReplayErrorPrefix.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reiniciar el audio'**
  String get audioReplayErrorPrefix;

  /// No description provided for @documentLoaded.
  ///
  /// In es, this message translates to:
  /// **'Documento cargado'**
  String get documentLoaded;

  /// No description provided for @documentDeletedFromHistory.
  ///
  /// In es, this message translates to:
  /// **'Documento eliminado del historial.'**
  String get documentDeletedFromHistory;

  /// No description provided for @historyDeleted.
  ///
  /// In es, this message translates to:
  /// **'Historial eliminado.'**
  String get historyDeleted;

  /// No description provided for @searchResult.
  ///
  /// In es, this message translates to:
  /// **'Resultado de búsqueda'**
  String get searchResult;

  /// No description provided for @uploadOrSelectDocumentFirst.
  ///
  /// In es, this message translates to:
  /// **'Primero sube o selecciona un documento.'**
  String get uploadOrSelectDocumentFirst;

  /// No description provided for @activeDocument.
  ///
  /// In es, this message translates to:
  /// **'Documento activo'**
  String get activeDocument;

  /// No description provided for @createWorkspace.
  ///
  /// In es, this message translates to:
  /// **'Crear workspace'**
  String get createWorkspace;

  /// No description provided for @workspaceName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del workspace'**
  String get workspaceName;

  /// No description provided for @workspaceNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Tesis, Derecho Penal, Proyecto final'**
  String get workspaceNameHint;

  /// No description provided for @selectDocuments.
  ///
  /// In es, this message translates to:
  /// **'Selecciona documentos'**
  String get selectDocuments;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get create;

  /// No description provided for @myWorkspace.
  ///
  /// In es, this message translates to:
  /// **'Mi workspace'**
  String get myWorkspace;

  /// No description provided for @heroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu centro inteligente de estudio con IA.'**
  String get heroSubtitle;

  /// No description provided for @docsShort.
  ///
  /// In es, this message translates to:
  /// **'Docs'**
  String get docsShort;

  /// No description provided for @ragReady.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get ragReady;

  /// No description provided for @ragActive.
  ///
  /// In es, this message translates to:
  /// **'RAG activo'**
  String get ragActive;

  /// No description provided for @aiTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas IA'**
  String get aiTools;

  /// No description provided for @aiToolsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Explora funciones inteligentes para estudiar más rápido.'**
  String get aiToolsSubtitle;

  /// No description provided for @uploadPdf.
  ///
  /// In es, this message translates to:
  /// **'Subir PDF'**
  String get uploadPdf;

  /// No description provided for @uploadPdfDescription.
  ///
  /// In es, this message translates to:
  /// **'Carga documentos para resumir con IA.'**
  String get uploadPdfDescription;

  /// No description provided for @aiChat.
  ///
  /// In es, this message translates to:
  /// **'Chat IA'**
  String get aiChat;

  /// No description provided for @aiChatDescription.
  ///
  /// In es, this message translates to:
  /// **'Pregunta sobre el documento activo.'**
  String get aiChatDescription;

  /// No description provided for @aiExam.
  ///
  /// In es, this message translates to:
  /// **'Examen IA'**
  String get aiExam;

  /// No description provided for @aiExamDescription.
  ///
  /// In es, this message translates to:
  /// **'Genera preguntas automáticas.'**
  String get aiExamDescription;

  /// No description provided for @flashcardsDescription.
  ///
  /// In es, this message translates to:
  /// **'Crea tarjetas de estudio inteligentes.'**
  String get flashcardsDescription;

  /// No description provided for @documents.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get documents;

  /// No description provided for @aiStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado IA'**
  String get aiStatus;

  /// No description provided for @noDocument.
  ///
  /// In es, this message translates to:
  /// **'Sin documento'**
  String get noDocument;

  /// No description provided for @ready.
  ///
  /// In es, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @recentDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos recientes'**
  String get recentDocuments;

  /// No description provided for @aiWorkspaces.
  ///
  /// In es, this message translates to:
  /// **'Workspaces IA'**
  String get aiWorkspaces;

  /// No description provided for @createWorkspaceButton.
  ///
  /// In es, this message translates to:
  /// **'Crear workspace'**
  String get createWorkspaceButton;

  /// No description provided for @newWorkspace.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newWorkspace;

  /// No description provided for @workspaceEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Crea espacios inteligentes para agrupar documentos por proyecto, investigación, materia o tema.'**
  String get workspaceEmptyDescription;

  /// No description provided for @documentCountLabel.
  ///
  /// In es, this message translates to:
  /// **'documentos'**
  String get documentCountLabel;

  /// No description provided for @updatedAt.
  ///
  /// In es, this message translates to:
  /// **'Actualizado'**
  String get updatedAt;

  /// No description provided for @openWorkspace.
  ///
  /// In es, this message translates to:
  /// **'Abrir workspace'**
  String get openWorkspace;

  /// No description provided for @recentConversations.
  ///
  /// In es, this message translates to:
  /// **'Conversaciones recientes'**
  String get recentConversations;

  /// No description provided for @renameConversation.
  ///
  /// In es, this message translates to:
  /// **'Renombrar conversación'**
  String get renameConversation;

  /// No description provided for @newName.
  ///
  /// In es, this message translates to:
  /// **'Nuevo nombre'**
  String get newName;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @renameConversationError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo renombrar la conversación.'**
  String get renameConversationError;

  /// No description provided for @deleteConversationError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la conversación.'**
  String get deleteConversationError;

  /// No description provided for @loadingConversations.
  ///
  /// In es, this message translates to:
  /// **'Cargando conversaciones...'**
  String get loadingConversations;

  /// No description provided for @noSavedConversations.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes conversaciones guardadas.'**
  String get noSavedConversations;

  /// No description provided for @untitledConversation.
  ///
  /// In es, this message translates to:
  /// **'Conversación sin título'**
  String get untitledConversation;

  /// No description provided for @deleteConversation.
  ///
  /// In es, this message translates to:
  /// **'Eliminar conversación'**
  String get deleteConversation;

  /// No description provided for @noHistoryYet.
  ///
  /// In es, this message translates to:
  /// **'Sin historial todavía'**
  String get noHistoryYet;

  /// No description provided for @historyEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Cuando subas documentos aparecerán aquí.'**
  String get historyEmptyDescription;

  /// No description provided for @recentHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial reciente'**
  String get recentHistory;

  /// No description provided for @historyHint.
  ///
  /// In es, this message translates to:
  /// **'Toca un documento para activarlo nuevamente.'**
  String get historyHint;

  /// No description provided for @clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get clear;

  /// No description provided for @generatedAudio.
  ///
  /// In es, this message translates to:
  /// **'Audio generado'**
  String get generatedAudio;

  /// No description provided for @audioNotGeneratedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Convierte el resumen en una audioclase.'**
  String get audioNotGeneratedSubtitle;

  /// No description provided for @audioGeneratedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escucha el resumen como audioclase.'**
  String get audioGeneratedSubtitle;

  /// No description provided for @audioNotGeneratedDescription.
  ///
  /// In es, this message translates to:
  /// **'El audio aún no ha sido generado. Puedes crearlo ahora sin bloquear la carga del documento.'**
  String get audioNotGeneratedDescription;

  /// No description provided for @generating.
  ///
  /// In es, this message translates to:
  /// **'Generando...'**
  String get generating;

  /// No description provided for @generateAudio.
  ///
  /// In es, this message translates to:
  /// **'Generar audio'**
  String get generateAudio;

  /// No description provided for @smartAudiobook.
  ///
  /// In es, this message translates to:
  /// **'Audiolibro inteligente'**
  String get smartAudiobook;

  /// No description provided for @pauseAudio.
  ///
  /// In es, this message translates to:
  /// **'Pausar audio'**
  String get pauseAudio;

  /// No description provided for @playAudio.
  ///
  /// In es, this message translates to:
  /// **'Reproducir audio'**
  String get playAudio;

  /// No description provided for @aiSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen IA'**
  String get aiSummary;

  /// No description provided for @summarySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Síntesis clara del documento cargado.'**
  String get summarySubtitle;

  /// No description provided for @exportSummaryToWord.
  ///
  /// In es, this message translates to:
  /// **'Exportar resumen a Word'**
  String get exportSummaryToWord;

  /// No description provided for @exportSummaryToPowerPoint.
  ///
  /// In es, this message translates to:
  /// **'Exportar resumen a PowerPoint'**
  String get exportSummaryToPowerPoint;

  /// No description provided for @exportSummaryToPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar resumen a PDF'**
  String get exportSummaryToPdf;

  /// No description provided for @processingDocument.
  ///
  /// In es, this message translates to:
  /// **'Procesando documento...'**
  String get processingDocument;

  /// No description provided for @processingDocumentDescription.
  ///
  /// In es, this message translates to:
  /// **'Generando resumen IA, audio y embeddings RAG.'**
  String get processingDocumentDescription;

  /// No description provided for @activeWorkspace.
  ///
  /// In es, this message translates to:
  /// **'Workspace activo'**
  String get activeWorkspace;

  /// No description provided for @documentReadyToStudy.
  ///
  /// In es, this message translates to:
  /// **'Documento listo para estudiar'**
  String get documentReadyToStudy;

  /// No description provided for @aiReady.
  ///
  /// In es, this message translates to:
  /// **'IA lista'**
  String get aiReady;

  /// No description provided for @audioAvailable.
  ///
  /// In es, this message translates to:
  /// **'Audio disponible'**
  String get audioAvailable;

  /// No description provided for @openAiChat.
  ///
  /// In es, this message translates to:
  /// **'Abrir Chat IA'**
  String get openAiChat;

  /// No description provided for @workspaceChatWelcome.
  ///
  /// In es, this message translates to:
  /// **'Hola. Soy StudyBook AI.\n\nEstoy listo para ayudarte a estudiar este workspace con {count} documentos.\n\nPuedes pedir comparaciones, síntesis cruzadas o análisis combinados.'**
  String workspaceChatWelcome(Object count);

  /// No description provided for @documentChatWelcome.
  ///
  /// In es, this message translates to:
  /// **'Hola. Soy StudyBook AI.\n\nEstoy listo para ayudarte a comprender el documento \"{fileName}\".\n\nPuedes hacer preguntas, pedir explicaciones, resúmenes, conceptos clave o análisis académicos.'**
  String documentChatWelcome(Object fileName);

  /// No description provided for @noAnswerReceived.
  ///
  /// In es, this message translates to:
  /// **'No se recibió respuesta.'**
  String get noAnswerReceived;

  /// No description provided for @chatTemporaryError.
  ///
  /// In es, this message translates to:
  /// **'No pude responder en este momento.\n\nVerifica la conexión con el backend o intenta nuevamente.'**
  String get chatTemporaryError;

  /// No description provided for @exportChatToWord.
  ///
  /// In es, this message translates to:
  /// **'Exportar chat a Word'**
  String get exportChatToWord;

  /// No description provided for @exportChatToPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar chat a PDF'**
  String get exportChatToPdf;

  /// No description provided for @userRole.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get userRole;

  /// No description provided for @noContentToExport.
  ///
  /// In es, this message translates to:
  /// **'No hay contenido para exportar.'**
  String get noContentToExport;

  /// No description provided for @chatExportWordError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo exportar Word'**
  String get chatExportWordError;

  /// No description provided for @chatExportPdfError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo exportar el PDF'**
  String get chatExportPdfError;

  /// No description provided for @chatTitlePrefix.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chatTitlePrefix;

  /// No description provided for @workspaceAiChat.
  ///
  /// In es, this message translates to:
  /// **'Chat IA de workspace'**
  String get workspaceAiChat;

  /// No description provided for @contextualAiChat.
  ///
  /// In es, this message translates to:
  /// **'Chat IA contextual'**
  String get contextualAiChat;

  /// No description provided for @activeContext.
  ///
  /// In es, this message translates to:
  /// **'Contexto activo'**
  String get activeContext;

  /// No description provided for @workspaceRagContext.
  ///
  /// In es, this message translates to:
  /// **'RAG activo sobre múltiples documentos del workspace.'**
  String get workspaceRagContext;

  /// No description provided for @documentRagContext.
  ///
  /// In es, this message translates to:
  /// **'RAG activo para responder con base en el documento seleccionado.'**
  String get documentRagContext;

  /// No description provided for @contextHintConcepts.
  ///
  /// In es, this message translates to:
  /// **'Puedes pedir conceptos clave, explicación simple o resumen.'**
  String get contextHintConcepts;

  /// No description provided for @contextHintAcademic.
  ///
  /// In es, this message translates to:
  /// **'También puedes solicitar análisis académico del contenido.'**
  String get contextHintAcademic;

  /// No description provided for @contextHintSources.
  ///
  /// In es, this message translates to:
  /// **'Las respuestas se basan en el documento activo.'**
  String get contextHintSources;

  /// No description provided for @examSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Practica, responde y mide tu aprendizaje.'**
  String get examSubtitle;

  /// No description provided for @exportWord.
  ///
  /// In es, this message translates to:
  /// **'Exportar Word'**
  String get exportWord;

  /// No description provided for @exportPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar PDF'**
  String get exportPdf;

  /// No description provided for @exportExamToPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar examen a PDF'**
  String get exportExamToPdf;

  /// No description provided for @exportExamToWord.
  ///
  /// In es, this message translates to:
  /// **'Exportar examen a Word'**
  String get exportExamToWord;

  /// No description provided for @examEmptyPrompt.
  ///
  /// In es, this message translates to:
  /// **'Presiona el botón para generar el examen del documento activo.'**
  String get examEmptyPrompt;

  /// No description provided for @questionNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'Pregunta no disponible.'**
  String get questionNotAvailable;

  /// No description provided for @notSpecifiedInDocument.
  ///
  /// In es, this message translates to:
  /// **'No se especifica en el documento.'**
  String get notSpecifiedInDocument;

  /// No description provided for @allOfTheAbove.
  ///
  /// In es, this message translates to:
  /// **'Todas las anteriores.'**
  String get allOfTheAbove;

  /// No description provided for @noneOfTheAbove.
  ///
  /// In es, this message translates to:
  /// **'Ninguna de las anteriores.'**
  String get noneOfTheAbove;

  /// No description provided for @questionOf.
  ///
  /// In es, this message translates to:
  /// **'Pregunta {current} de {total}'**
  String questionOf(Object current, Object total);

  /// No description provided for @answerLabel.
  ///
  /// In es, this message translates to:
  /// **'Respuesta'**
  String get answerLabel;

  /// No description provided for @restart.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get restart;

  /// No description provided for @viewResult.
  ///
  /// In es, this message translates to:
  /// **'Ver resultado'**
  String get viewResult;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @verify.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get verify;

  /// No description provided for @correct.
  ///
  /// In es, this message translates to:
  /// **'Correcto'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In es, this message translates to:
  /// **'Incorrecto'**
  String get incorrect;

  /// No description provided for @correctAnswer.
  ///
  /// In es, this message translates to:
  /// **'Respuesta correcta'**
  String get correctAnswer;

  /// No description provided for @finalResult.
  ///
  /// In es, this message translates to:
  /// **'Resultado final'**
  String get finalResult;

  /// No description provided for @retakeExam.
  ///
  /// In es, this message translates to:
  /// **'Repetir examen'**
  String get retakeExam;

  /// No description provided for @generateExam.
  ///
  /// In es, this message translates to:
  /// **'Generar examen'**
  String get generateExam;

  /// No description provided for @regenerateExam.
  ///
  /// In es, this message translates to:
  /// **'Regenerar examen'**
  String get regenerateExam;

  /// No description provided for @generatingExam.
  ///
  /// In es, this message translates to:
  /// **'Generando examen con IA...'**
  String get generatingExam;

  /// No description provided for @examExportQuestion.
  ///
  /// In es, this message translates to:
  /// **'PREGUNTA'**
  String get examExportQuestion;

  /// No description provided for @examExportOptions.
  ///
  /// In es, this message translates to:
  /// **'OPCIONES'**
  String get examExportOptions;

  /// No description provided for @examExportCorrectAnswer.
  ///
  /// In es, this message translates to:
  /// **'RESPUESTA CORRECTA'**
  String get examExportCorrectAnswer;

  /// No description provided for @examExportExplanation.
  ///
  /// In es, this message translates to:
  /// **'EXPLICACIÓN'**
  String get examExportExplanation;

  /// No description provided for @flashcardsAiTitle.
  ///
  /// In es, this message translates to:
  /// **'Flashcards IA'**
  String get flashcardsAiTitle;

  /// No description provided for @flashcardsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Modo estudio premium con tarjetas 3D.'**
  String get flashcardsSubtitle;

  /// No description provided for @exportFlashcardsToPdf.
  ///
  /// In es, this message translates to:
  /// **'Exportar flashcards a PDF'**
  String get exportFlashcardsToPdf;

  /// No description provided for @exportFlashcardsToWord.
  ///
  /// In es, this message translates to:
  /// **'Exportar flashcards a Word'**
  String get exportFlashcardsToWord;

  /// No description provided for @answerNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'Respuesta no disponible.'**
  String get answerNotAvailable;

  /// No description provided for @flashcardQuestion.
  ///
  /// In es, this message translates to:
  /// **'Pregunta'**
  String get flashcardQuestion;

  /// No description provided for @flashcardAnswer.
  ///
  /// In es, this message translates to:
  /// **'Respuesta'**
  String get flashcardAnswer;

  /// No description provided for @tapToSeeAnswer.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver la respuesta'**
  String get tapToSeeAnswer;

  /// No description provided for @tapToReturnQuestion.
  ///
  /// In es, this message translates to:
  /// **'Toca para volver a la pregunta'**
  String get tapToReturnQuestion;

  /// No description provided for @previous.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get previous;

  /// No description provided for @flashcardsEmptyPrompt.
  ///
  /// In es, this message translates to:
  /// **'Presiona el botón para generar flashcards del documento activo.'**
  String get flashcardsEmptyPrompt;

  /// No description provided for @generateFlashcards.
  ///
  /// In es, this message translates to:
  /// **'Generar flashcards'**
  String get generateFlashcards;

  /// No description provided for @regenerateFlashcards.
  ///
  /// In es, this message translates to:
  /// **'Regenerar flashcards'**
  String get regenerateFlashcards;

  /// No description provided for @generatingFlashcards.
  ///
  /// In es, this message translates to:
  /// **'Generando tarjetas con IA...'**
  String get generatingFlashcards;

  /// No description provided for @plansStudyBookTitle.
  ///
  /// In es, this message translates to:
  /// **'Planes StudyBook AI'**
  String get plansStudyBookTitle;

  /// No description provided for @checkoutSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Pago completado correctamente. Tu plan actual es {planName}.'**
  String checkoutSuccessMessage(Object planName);

  /// No description provided for @checkoutCancelMessage.
  ///
  /// In es, this message translates to:
  /// **'Pago cancelado.'**
  String get checkoutCancelMessage;

  /// No description provided for @checkoutTestModeMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud de pago fue procesada por Stripe en modo prueba.'**
  String get checkoutTestModeMessage;

  /// No description provided for @plansIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige el plan que se adapte a tu forma de estudiar o enseñar.'**
  String get plansIntro;

  /// No description provided for @paymentStartError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar el pago de {planName}: {error}'**
  String paymentStartError(Object planName, Object error);

  /// No description provided for @pdfsPerDay.
  ///
  /// In es, this message translates to:
  /// **'PDFs por día'**
  String get pdfsPerDay;

  /// No description provided for @chatsPerDay.
  ///
  /// In es, this message translates to:
  /// **'Chats por día'**
  String get chatsPerDay;

  /// No description provided for @flashcardsPerPdf.
  ///
  /// In es, this message translates to:
  /// **'Flashcards por PDF'**
  String get flashcardsPerPdf;

  /// No description provided for @examQuestionsPerPdf.
  ///
  /// In es, this message translates to:
  /// **'Preguntas de examen por PDF'**
  String get examQuestionsPerPdf;

  /// No description provided for @exportDocx.
  ///
  /// In es, this message translates to:
  /// **'Exportar DOCX'**
  String get exportDocx;

  /// No description provided for @exportPptx.
  ///
  /// In es, this message translates to:
  /// **'Exportar PPTX'**
  String get exportPptx;

  /// No description provided for @advancedAnalytics.
  ///
  /// In es, this message translates to:
  /// **'Analytics avanzado'**
  String get advancedAnalytics;

  /// No description provided for @teacherTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas profesor'**
  String get teacherTools;

  /// No description provided for @guidedVoice.
  ///
  /// In es, this message translates to:
  /// **'Voz guiada'**
  String get guidedVoice;

  /// No description provided for @yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @upgradeToPlan.
  ///
  /// In es, this message translates to:
  /// **'Actualizar a {planName}'**
  String upgradeToPlan(Object planName);

  /// No description provided for @completeEmailAndPassword.
  ///
  /// In es, this message translates to:
  /// **'Completa correo y contraseña.'**
  String get completeEmailAndPassword;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar.'**
  String get loginSubtitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta para empezar.'**
  String get signupSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get loginButton;

  /// No description provided for @createAccountButton.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get createAccountButton;

  /// No description provided for @createAccountLink.
  ///
  /// In es, this message translates to:
  /// **'Crear una cuenta'**
  String get createAccountLink;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get alreadyHaveAccount;

  /// No description provided for @dashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @premiumAi.
  ///
  /// In es, this message translates to:
  /// **'Premium AI'**
  String get premiumAi;

  /// No description provided for @premiumAiDescription.
  ///
  /// In es, this message translates to:
  /// **'Lectura completa IA y sincronización cloud próximamente.'**
  String get premiumAiDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
