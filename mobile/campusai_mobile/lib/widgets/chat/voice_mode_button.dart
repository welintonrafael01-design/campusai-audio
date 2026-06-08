import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/voice_service.dart';
import '../../theme/app_theme.dart';

class VoiceModeButton extends StatefulWidget {
  final bool isDisabled;
  final void Function(String text) onTextRecognized;
  final VoidCallback? onListeningStopped;

  const VoiceModeButton({
    super.key,
    required this.onTextRecognized,
    this.isDisabled = false,
    this.onListeningStopped,
  });

  @override
  State<VoiceModeButton> createState() => _VoiceModeButtonState();
}

class _VoiceModeButtonState extends State<VoiceModeButton> {
  final VoiceService _voiceService = VoiceService();

  bool isListening = false;
  bool isInitializing = false;
  Timer? _autoStopTimer;

  String localeIdFor(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;

    return switch (code) {
      'en' => 'en_US',
      'pt' => 'pt_BR',
      'fr' => 'fr_FR',
      _ => 'es_ES',
    };
  }

  Future<void> stopListening() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    await _voiceService.stopListening();
    await _voiceService.cancelListening();

    if (!mounted) return;

    setState(() {
      isListening = false;
      isInitializing = false;
    });

    widget.onListeningStopped?.call();
  }

  void scheduleAutoStop() {
    _autoStopTimer?.cancel();

    _autoStopTimer = Timer(
      const Duration(seconds: 8),
      () async {
        if (!mounted || !isListening) return;
        await stopListening();
      },
    );
  }

  Future<void> toggleListening() async {
    if (widget.isDisabled || isInitializing) return;

    final l10n = AppLocalizations.of(context);

    if (isListening) {
      await stopListening();
      return;
    }

    setState(() {
      isInitializing = true;
    });

    try {
      final started = await _voiceService.startListening(
        localeId: localeIdFor(context),
        onResult: (text) {
          widget.onTextRecognized(text);
          scheduleAutoStop();
        },
        onStatus: (status) {
          if (!mounted) return;

          final normalized = status.toLowerCase();

          if (normalized.contains('done') ||
              normalized.contains('notlistening')) {
            _autoStopTimer?.cancel();
            _autoStopTimer = null;

            setState(() {
              isListening = false;
              isInitializing = false;
            });

            widget.onListeningStopped?.call();
          }
        },
        onError: (_) {
          if (!mounted) return;

          _autoStopTimer?.cancel();
          _autoStopTimer = null;

          setState(() {
            isListening = false;
            isInitializing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.voiceNotAvailable),
            ),
          );
        },
      );

      if (!mounted) return;

      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.voiceNotAvailable),
          ),
        );

        setState(() {
          isListening = false;
          isInitializing = false;
        });

        return;
      }

      setState(() {
        isListening = true;
        isInitializing = false;
      });

      scheduleAutoStop();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isListening = false;
        isInitializing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.voiceNotAvailable),
        ),
      );
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _voiceService.cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final backgroundColor =
        isListening ? AppTheme.accent.withValues(alpha: 0.22) : AppTheme.card;

    final iconColor = isListening ? AppTheme.accent : AppTheme.textSecondary;

    return Tooltip(
      message: isListening ? l10n.stopListening : l10n.voiceInputTooltip,
      child: SizedBox(
        height: 56,
        width: 56,
        child: OutlinedButton(
          onPressed: widget.isDisabled ? null : toggleListening,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(
              color: isListening
                  ? AppTheme.accent.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.zero,
          ),
          child: isInitializing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                  ),
                )
              : Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: iconColor,
                ),
        ),
      ),
    );
  }
}
