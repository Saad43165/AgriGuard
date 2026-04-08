import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';

class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onForgotPassword;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onForgotPassword,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Input
          _buildInputLabel('Email Address', _emailFocused || widget.emailController.text.isNotEmpty),
          const SizedBox(height: 12),
          Focus(
            onFocusChange: (hasFocus) => setState(() => _emailFocused = hasFocus),
            child: _buildInputContainer(
              isDark: isDark,
              isFocused: _emailFocused,
              child: Row(
                children: [
                  // Icon with background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _emailFocused
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildIcon(AppIcons.email, _emailFocused),
                  ),

                  const SizedBox(width: 12),

                  // Vertical Divider
                  Container(
                    height: 40,
                    width: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
                  ),

                  const SizedBox(width: 16),

                  // Text Field
                  Expanded(
                    child: TextFormField(
                      controller: widget.emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: _inputTextStyle(context),
                      decoration: InputDecoration(
                        hintText: 'yourname@example.com',
                        hintStyle: _hintStyle(context),
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
                    _buildClearButton(() => setState(() => widget.emailController.clear())),
                ],
              ),
            ),
          ),


          // Password Input
          _buildInputLabel('Password', _passwordFocused || widget.passwordController.text.isNotEmpty),
          const SizedBox(height: 12),
          Focus(
            onFocusChange: (hasFocus) => setState(() => _passwordFocused = hasFocus),
            child: _buildInputContainer(
              isDark: isDark,
              isFocused: _passwordFocused,
              child: Row(
                children: [
                  // Icon with background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _passwordFocused
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildIcon(AppIcons.password, _passwordFocused),
                  ),

                  const SizedBox(width: 12),

                  // Vertical Divider
                  Container(
                    height: 40,
                    width: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
                  ),

                  const SizedBox(width: 16),

                  // Text Field
                  Expanded(
                    child: TextFormField(
                      controller: widget.passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      style: _inputTextStyle(context),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: _hintStyle(context),
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

                  // Visibility Toggle
                  GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_reset_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reset password',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
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

  Widget _buildInputLabel(String label, bool show) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
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
    );
  }

  Widget _buildInputContainer({
    required bool isDark,
    required bool isFocused,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // ✅ Increased from 4 to 16
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
      child: child,
    );
  }

  Widget _buildIcon(IconData icon, bool isFocused) {
    return ShaderMask(
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
    );
  }

  Widget _buildClearButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }

  TextStyle _inputTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
      letterSpacing: 0.2,
      height: 1.5,
    );
  }

  TextStyle _hintStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
      fontWeight: FontWeight.w400,
      fontSize: 15,
      letterSpacing: 0.2,
    );
  }
}