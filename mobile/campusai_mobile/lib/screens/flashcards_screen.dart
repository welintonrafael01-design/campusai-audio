import 'dart:convert';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/study_result.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../services/plan_guard_service.dart';
import '../utils/upgrade_dialog.dart';
import '../services/study_result_service.dart';
import '../services/study_result_repository.dart';
import '../services/cloud_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class FlashcardsScreen extends StatefulWidget {
  final String documentId;
  final List<Map<String, dynamic>> initialFlashcards;

  const FlashcardsScreen({
    super.key,
    required this.documentId,
    this.initialFlashcards = const [],
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  bool isLoading = false;
  String errorMessage = '';
  int currentIndex = 0;

  List<Map<String, dynamic>> flashcards = [];

  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    if (widget.initialFlashcards.isNotEmpty) {
      flashcards = _parseFlashcards(widget.initialFlashcards);
      currentIndex = 0;
    } else {
      loadSavedFlashcards();
    }
  }

  Future<void> loadSavedFlashcards() async {
    final savedResult = await const StudyResultRepository().getResult(
      documentId: widget.documentId,
      type: 'flashcards',
    );

    if (savedResult == null) return;

    final parsed = _parseFlashcards(savedResult.content);

    if (!mounted) return;

    setState(() {
      flashcards = parsed;
      currentIndex = 0;
    });
  }

  Future<void> generateFlashcards() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await ApiService.generateFlashcardsByDocumentId(
        documentId: widget.documentId,
        numberOfCards: 10,
      );

      final parsed = _parseFlashcards(data['flashcards']);
      if (parsed.isEmpty) {
        throw const FormatException('Flashcards incompletas.');
      }

      if (!mounted) return;

      setState(() {
        flashcards = parsed;
        currentIndex = 0;
      });

      final content = jsonEncode(parsed);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: widget.documentId,
          type: 'flashcards',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      try {
        await CloudApiService.saveStudyResult(
          documentId: widget.documentId,
          type: 'flashcards',
          content: content,
        );
      } catch (cloudError) {
        debugPrint(
          'No se pudo guardar flashcards cloud (${cloudError.runtimeType}).',
        );
      }
    } catch (error) {
      debugPrint(
        'No se pudieron generar las flashcards (${error.runtimeType}).',
      );
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Booky no pudo preparar las flashcards esta vez. Podemos intentarlo otra vez.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseFlashcards(dynamic raw) {
    dynamic decoded = raw;

    if (raw is String) {
      final clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();

      decoded = jsonDecode(clean);
    }

    if (decoded is Map<String, dynamic>) {
      final list = decoded['flashcards'] ?? decoded['tarjetas'] ?? [];

      if (list is List) {
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(_normalizedFlashcard)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_normalizedFlashcard)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    return [];
  }

  Map<String, dynamic>? _normalizedFlashcard(Map<String, dynamic> item) {
    final front = (item['front'] ?? item['question'] ?? item['pregunta'])
            ?.toString()
            .trim() ??
        '';
    final back = (item['back'] ?? item['answer'] ?? item['respuesta'])
            ?.toString()
            .trim() ??
        '';
    if (front.isEmpty || back.isEmpty) return null;
    return {...item, 'front': front, 'back': back};
  }

  String getFront(Map<String, dynamic> item) {
    return (item['front'] ??
            item['question'] ??
            item['pregunta'] ??
            l10n.questionNotAvailable)
        .toString();
  }

  String getBack(Map<String, dynamic> item) {
    return (item['back'] ??
            item['answer'] ??
            item['respuesta'] ??
            l10n.answerNotAvailable)
        .toString();
  }

  String buildFlashcardsExportContent() {
    return flashcards.map((card) {
      return """
${l10n.examExportQuestion}:
${getFront(card)}

${l10n.answerLabel}:
${getBack(card)}
""";
    }).join("\n\n--------------------\n\n");
  }

  Future<void> exportFlashcardsToPdf() async {
    if (!const PlanGuardService().canExportPdf) {
      showUpgradeRequired(
        context,
        featureName: l10n.exportFlashcardsToPdf,
      );
      return;
    }

    if (flashcards.isEmpty) return;

    await ExportService.exportTextToPdf(
      title: 'Flashcards',
      content: buildFlashcardsExportContent(),
    );
  }

  Future<void> exportFlashcardsToDocx() async {
    if (!const PlanGuardService().canExportDocx) {
      showUpgradeRequired(
        context,
        featureName: l10n.exportFlashcardsToWord,
      );
      return;
    }

    if (flashcards.isEmpty) return;

    await ExportService.exportTextToDocx(
      title: 'Flashcards',
      content: buildFlashcardsExportContent(),
    );
  }

  void previousCard() {
    if (flashcards.isEmpty || currentIndex == 0) return;

    setState(() {
      currentIndex--;
    });
  }

  void nextCard() {
    if (flashcards.isEmpty || currentIndex >= flashcards.length - 1) return;

    setState(() {
      currentIndex++;
    });
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.style_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.flashcardsAiTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.flashcardsSubtitle,
            style: TextStyle(
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Tooltip(
                message: l10n.exportWord,
                child: IconButton(
                  onPressed: flashcards.isEmpty ? null : exportFlashcardsToDocx,
                  icon: const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Tooltip(
                message: l10n.exportPdf,
                child: IconButton(
                  onPressed: flashcards.isEmpty ? null : exportFlashcardsToPdf,
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPremiumCard() {
    if (flashcards.isEmpty) return const SizedBox.shrink();

    final item = flashcards[currentIndex];
    final front = getFront(item);
    final back = getBack(item);

    return Column(
      children: [
        Row(
          children: [
            Text(
              '${currentIndex + 1} / ${flashcards.length}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: currentIndex == 0
                  ? null
                  : () => setState(() => currentIndex = 0),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reiniciar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (currentIndex + 1) / flashcards.length,
          minHeight: 8,
          borderRadius: BorderRadius.circular(20),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 360,
          child: FlipCard(
            key: ValueKey(currentIndex),
            direction: FlipDirection.HORIZONTAL,
            front: _CardFace(
              title: l10n.flashcardQuestion,
              content: front,
              icon: Icons.help_outline_rounded,
              gradient: AppTheme.mainGradient,
              footer: l10n.tapToSeeAnswer,
            ),
            back: _CardFace(
              title: l10n.flashcardAnswer,
              content: back,
              icon: Icons.lightbulb_rounded,
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.indigo.shade700,
                ],
              ),
              footer: l10n.tapToReturnQuestion,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: currentIndex == 0 ? null : previousCard,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.previous),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    currentIndex >= flashcards.length - 1 ? null : nextCard,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l10n.next),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildEmptyResult() {
    if (isLoading || errorMessage.isNotEmpty || flashcards.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      child: Text(
        l10n.flashcardsEmptyPrompt,
        style: TextStyle(
          color: AppTheme.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(l10n.flashcardsAiTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            buildHeader(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : generateFlashcards,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                flashcards.isEmpty
                    ? l10n.generateFlashcards
                    : l10n.regenerateFlashcards,
              ),
            ),
            const SizedBox(height: 20),
            buildEmptyResult(),
            if (isLoading)
              SectionCard(
                child: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.generatingFlashcards,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            if (errorMessage.isNotEmpty)
              SectionCard(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            buildPremiumCard(),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Gradient gradient;
  final String footer;

  const _CardFace({
    required this.title,
    required this.content,
    required this.icon,
    required this.gradient,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            footer,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
