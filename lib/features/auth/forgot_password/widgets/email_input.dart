import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';

class EmailInput extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;

  const EmailInput({
    super.key,
    required this.formKey,
    required this.emailController,
  });

  @override
  State<EmailInput> createState() => _EmailInputState();
}

class _EmailInputState extends State<EmailInput> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floating Label
          AnimatedOpacity(
            opacity: _isFocused || widget.emailController.text.isNotEmpty ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'EMAIL ADDRESS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // Modern Input Field
          Focus(
            onFocusChange: (hasFocus) {
              setState(() => _isFocused = hasFocus);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFocused
                      ? Theme.of(context).colorScheme.primary
                      : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  width: _isFocused ? 2 : 1.5,
                ),

              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Animated Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isFocused
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: _isFocused
                              ? [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ]
                              : [
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ],
                        ).createShader(bounds),
                        child: Icon(
                          AppIcons.email,
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Vertical Divider
                    Container(
                      height: 40,
                      width: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),

                    const SizedBox(width: 16),

                    // Text Field - IMPROVED AREA
                    Expanded(
                      child: TextFormField(
                        controller: widget.emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.2,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'yourname@example.com',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          filled: false,
                        ),
                        cursorColor: Theme.of(context).colorScheme.primary,
                        cursorWidth: 2,
                        cursorHeight: 22,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    // Clear Button
                    if (widget.emailController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            widget.emailController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Helper Text
          AnimatedOpacity(
            opacity: _isFocused ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, top: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'We\'ll send a password reset link to this email',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}