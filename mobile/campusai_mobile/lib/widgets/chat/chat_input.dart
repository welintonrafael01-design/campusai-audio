import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        18,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 6,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Pregunta sobre el documento...',
                filled: true,
                fillColor: AppTheme.card,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            height: 56,
            width: 56,
            child: ElevatedButton(
              onPressed:
                  isLoading ? null : onSend,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                padding: EdgeInsets.zero,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}