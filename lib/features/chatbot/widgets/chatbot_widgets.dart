import 'dart:io';
import 'package:flutter/material.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import '../chatbot_constants.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  const MessageBubble({super.key, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 16)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(message.imagePath!),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (message.imagePath != null) const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 14, height: 1.4,
                      color: isUser ? Colors.white : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  final bool isDark;
  const TypingIndicator({super.key, required this.isDark});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 30, height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16)),
            border: Border.all(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final val = ((_ctrl.value + i * 0.33) % 1.0);
                final scale = 0.6 + (val < 0.5 ? val * 0.8 : (1 - val) * 0.8);
                return Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.scale(scale: scale,
                    child: Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        shape: BoxShape.circle))));
              })),
          ),
        ),
      ]),
    );
  }
}

class SuggestionsRow extends StatelessWidget {
  final List<({String text, IconData icon})> suggestions;
  final void Function(String) onTap;
  final bool isDark;
  const SuggestionsRow({super.key, required this.suggestions, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = suggestions[i];
            return GestureDetector(
              onTap: () { onTap(s.text); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.icon, size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(s.text,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isDark;
  final String hintText;
  final void Function(String) onSend;
  final VoidCallback? onImageTap;
  const ChatInputBar({super.key, required this.controller, required this.isLoading, required this.isDark,
      required this.hintText, required this.onSend, this.onImageTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(children: [
        if (onImageTap != null)
          GestureDetector(
            onTap: isLoading ? null : onImageTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: TextField(
              controller: controller,
              maxLines: 4, minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                    color: isDark ? AppColors.darkCaption : AppColors.lightCaption, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: isLoading ? null : onSend,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isLoading ? null : () => onSend(controller.text),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isLoading
                  ? (isDark ? AppColors.darkCard : AppColors.lightBg)
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(21),
            ),
            child: isLoading
                ? const Center(child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                : Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}