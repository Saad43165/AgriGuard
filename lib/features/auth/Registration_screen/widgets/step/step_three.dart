import 'package:flutter/material.dart';

class StepThree extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const StepThree({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<StepThree> createState() => StepThreeState();
}

class StepThreeState extends State<StepThree> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordFocused = false;
  bool _confirmPasswordFocused = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Public method to enable autovalidation
  void enableAutoValidation() {
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });
  }

  // Password validation getters
  bool get _hasMinLength => widget.passwordController.text.length >= 6;

  // Check for alphanumeric (letters AND numbers)
  bool get _hasLettersAndNumbers {
    final password = widget.passwordController.text;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    return hasLetter && hasNumber;
  }

  // ADDED: Check for special characters
  bool get _hasSpecialChar {
    final password = widget.passwordController.text;
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    return hasSpecial;
  }

  bool get _passwordsMatch =>
      widget.passwordController.text == widget.confirmPasswordController.text &&
          widget.confirmPasswordController.text.isNotEmpty;

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
              'Secure Your Account',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a strong password',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            _buildPasswordField(
              context,
              label: 'Password',
              controller: widget.passwordController,
              isDark: isDark,
              isFocused: _passwordFocused,
              obscureText: _obscurePassword,
              onFocusChange: (focus) => setState(() => _passwordFocused = focus),
              onVisibilityToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                // Check for letters
                if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                  return 'Password must contain letters';
                }
                // Check for numbers
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Password must contain numbers';
                }
                // ADDED: Check for special characters
                if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                  return 'Password must contain special characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildPasswordField(
              context,
              label: 'Confirm Password',
              controller: widget.confirmPasswordController,
              isDark: isDark,
              isFocused: _confirmPasswordFocused,
              obscureText: _obscureConfirmPassword,
              onFocusChange: (focus) => setState(() => _confirmPasswordFocused = focus),
              onVisibilityToggle: () =>
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != widget.passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Password Requirements - UPDATED
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Password Requirements',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Requirement 1: Length
                  _buildRequirement(
                    'At least 6 characters long',
                    _hasMinLength,
                  ),
                  const SizedBox(height: 8),

                  // Requirement 2: Alphanumeric
                  _buildRequirement(
                    'Contains both letters and numbers',
                    _hasLettersAndNumbers,
                  ),
                  const SizedBox(height: 8),

                  // Requirement 3: Special Characters - ADDED
                  _buildRequirement(
                    'Contains special characters (!@#\$%^&*)',
                    _hasSpecialChar,
                  ),
                  const SizedBox(height: 8),

                  // Requirement 4: Match
                  _buildRequirement(
                    'Passwords match',
                    _passwordsMatch,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet, {bool isOptional = false}) {
    return Row(
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : isOptional
              ? Icons.info_outline_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: isMet
              ? Colors.green
              : isOptional
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isMet
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required bool isDark,
        required bool isFocused,
        required bool obscureText,
        required Function(bool) onFocusChange,
        required VoidCallback onVisibilityToggle,
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
                    child: const Icon(Icons.lock_rounded, size: 22),
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
                    obscureText: obscureText,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: obscureText ? 2.0 : 0.3,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter ${label.toLowerCase()}',
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
                GestureDetector(
                  onTap: onVisibilityToggle,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
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