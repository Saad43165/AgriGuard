import 'package:flutter/material.dart';

class StepTwo extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController farmSizeController;

  const StepTwo({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.locationController,
    required this.farmSizeController,
  });

  @override
  State<StepTwo> createState() => StepTwoState();
}

class StepTwoState extends State<StepTwo> {
  bool _phoneFocused = false;
  bool _locationFocused = false;
  bool _farmSizeFocused = false;
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
              'Farm Details',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your farm (Optional)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            _buildInputField(
              context,
              label: 'Phone Number',
              controller: widget.phoneController,
              icon: Icons.phone_rounded,
              isDark: isDark,
              isFocused: _phoneFocused,
              keyboardType: TextInputType.phone,
              onFocusChange: (focus) => setState(() => _phoneFocused = focus),
              isOptional: true,
            ),

            const SizedBox(height: 20),

            _buildInputField(
              context,
              label: 'Location',
              controller: widget.locationController,
              icon: Icons.location_on_rounded,
              isDark: isDark,
              isFocused: _locationFocused,
              onFocusChange: (focus) => setState(() => _locationFocused = focus),
              isOptional: true,
            ),

            const SizedBox(height: 20),

            _buildInputField(
              context,
              label: 'Farm Size',
              controller: widget.farmSizeController,
              icon: Icons.agriculture_rounded,
              isDark: isDark,
              isFocused: _farmSizeFocused,
              keyboardType: TextInputType.number,
              onFocusChange: (focus) => setState(() => _farmSizeFocused = focus),
              isOptional: true,
            ),

            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can skip this step and add details later from your profile',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
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

  Widget _buildInputField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required IconData icon,
        required bool isDark,
        required bool isFocused,
        required Function(bool) onFocusChange,
        TextInputType? keyboardType,
        bool isOptional = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedOpacity(
          opacity: isFocused || controller.text.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (isOptional) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(OPTIONAL)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
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
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
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
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
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
                        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ],
                    ).createShader(bounds),
                    child: Icon(icon, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 40,
                  width: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
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
                      hintText: label == 'Phone Number'
                          ? '+92 300 1234567'
                          : label == 'Location'
                          ? 'Punjab, Pakistan'
                          : '5.0 acres',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
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
      ],
    );
  }
}