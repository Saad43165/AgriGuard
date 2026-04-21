// lib/features/support/widgets/faq_search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/translation_service.dart';

class FaqSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearchChanged;
  final VoidCallback onClear;

  const FaqSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  State<FaqSearchBar> createState() => _FaqSearchBarState();
}

class _FaqSearchBarState extends State<FaqSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onClear();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = widget.controller.text.isNotEmpty;
    final translation = Provider.of<TranslationService>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: _isFocused ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: _isFocused ? 12 : 6,
            offset: Offset(0, _isFocused ? 4 : 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: (_) => widget.onSearchChanged(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: translation.get('search_faqs'),
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                isDense: true,
              ),
            ),
          ),

          // Clear Button
          if (hasText)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleClear,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}