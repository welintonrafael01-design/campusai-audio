import 'dart:convert';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';

import '../models/study_result.dart';
import '../services/api_service.dart';
import '../services/study_result_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class FlashcardsScreen extends StatefulWidget {
  final String documentId;

  const FlashcardsScreen({
    super.key,
    required this.documentId,
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

  @override
  void initState() {
    super.initState();
    loadSavedFlashcards();
  }

  Future<void> loadSavedFlashcards() async {
    final savedResult = await StudyResultService.getResult(
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

      if (!mounted) return;

      setState(() {
        flashcards = parsed;
        currentIndex = 0;
      });

      await StudyResultService.saveResult(
        StudyResult(
          documentId: widget.documentId,
          type: 'flashcards',
          content: jsonEncode(parsed),
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error: $error';
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
      final clean = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      decoded = jsonDecode(clean);
    }

    if (decoded is Map<String, dynamic>) {
      final list = decoded['flashcards'] ?? decoded['tarjetas'] ?? [];

      if (list is List) {
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  String getFront(Map<String, dynamic> item) {
    return (item['front'] ??
            item['question'] ??
            item['pregunta'] ??
            'Pregunta no disponible.')
        .toString();
  }

  String getBack(Map<String, dynamic> item) {
    return (item['back'] ??
            item['answer'] ??
            item['respuesta'] ??
            'Respuesta no disponible.')
        .toString();
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.style_rounded, color: Colors.white, size: 36),
          SizedBox(height: 16),
          Text(
            'Flashcards IA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Modo estudio premium con tarjetas 3D.',
            style: TextStyle(color: Colors.white, height: 1.4),
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
        Text(
          '${currentIndex + 1} / ${flashcards.length}',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w800,
          ),
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
              title: 'Pregunta',
              content: front,
              icon: Icons.help_outline_rounded,
              gradient: AppTheme.mainGradient,
              footer: 'Toca para ver la respuesta',
            ),
            back: _CardFace(
              title: 'Respuesta',
              content: back,
              icon: Icons.lightbulb_rounded,
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.indigo.shade700,
                ],
              ),
              footer: 'Toca para volver a la pregunta',
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
                label: const Text('Anterior'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: currentIndex >= flashcards.length - 1
                    ? null
                    : nextCard,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Siguiente'),
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

    return const SectionCard(
      child: Text(
        'Presiona el botón para generar flashcards del documento activo.',
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
      appBar: AppBar(title: const Text('Flashcards IA')),
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
                    ? 'Generar flashcards'
                    : 'Regenerar flashcards',
              ),
            ),
            const SizedBox(height: 20),
            buildEmptyResult(),
            if (isLoading)
              const SectionCard(
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Generando tarjetas con IA...',
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
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const Spacer(),
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