import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_icons.dart';
import '../profile_image_picker.dart';

class StepOne extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final File? imageFile;
  final VoidCallback onImagePick;

  const StepOne({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.imageFile,
    required this.onImagePick,
  });

  @override
  State<StepOne> createState() => StepOneState();
}

class StepOneState extends State<StepOne> {
  bool _nameFocused = false;
  bool _emailFocused = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // ADDED: Public method to enable autovalidation
  void enableAutoValidation() {
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(
              'Let\'s Get Started',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your AgriGuard account',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            ProfileImagePicker(
              imageFile: widget.imageFile,
              onImagePressed: widget.onImagePick,
              isLoading: false,
            ),

            const SizedBox(height: 40),

            _buildInputField(
              context,
              label: 'Full Name',
              controller: widget.nameController,
              icon: Icons.person_rounded,
              isDark: isDark,
              isFocused: _nameFocused,
              onFocusChange: (focus) => setState(() => _nameFocused = focus),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildInputField(
              context,
              label: 'Email Address',
              controller: widget.emailController,
              icon: AppIcons.email,
              isDark: isDark,
              isFocused: _emailFocused,
              keyboardType: TextInputType.emailAddress,
              onFocusChange: (focus) => setState(() => _emailFocused = focus),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required IconData icon,
        required bool isDark,
        required bool isFocused,
        required Function(bool) onFocusChange,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedOpacity(
          opacity: isFocused || controller.text.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        Focus(
          onFocusChange: onFocusChange,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFocused
                    ? Theme.of(context).colorScheme.primary
                    : isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: isFocused ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isFocused
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isFocused
                          ? [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ]
                          : [
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ],
                    ).createShader(bounds),
                    child: Icon(icon, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 40,
                  width: 1,
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.3,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: label == 'Full Name' ? 'John Doe' : 'your@email.com',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      filled: false,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                    cursorColor: Theme.of(context).colorScheme.primary,
                    cursorWidth: 2,
                    cursorHeight: 24,
                    validator: validator,
                    onChanged: (value) {
                      setState(() {
                        if (_autovalidateMode == AutovalidateMode.disabled) {
                          _autovalidateMode = AutovalidateMode.onUserInteraction;
                        }
                      });
                    },
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => controller.clear()),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Custom Error Message
        if (validator != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final errorText = _autovalidateMode != AutovalidateMode.disabled
                  ? validator(value.text)
                  : null;

              if (errorText != null) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6, top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          errorText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }
}