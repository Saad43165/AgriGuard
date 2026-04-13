import 'package:flutter/material.dart';
import 'widgets/location_tile.dart';
import 'utils/file_name_generator.dart';

class SaveOptionsDialog extends StatefulWidget {
  final String currentFileName;

  const SaveOptionsDialog({super.key, required this.currentFileName});

  @override
  State<SaveOptionsDialog> createState() => _SaveOptionsDialogState();
}

class _SaveOptionsDialogState extends State<SaveOptionsDialog> {
  late TextEditingController _fileNameController;
  String _selectedLocation = 'downloads';
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(
      text: FileNameGenerator.generate(),
    );
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1E2E), const Color(0xFF2A2A3E)]
                : [Colors.white, const Color(0xFFFAFAFA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed header
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildHeader(isDark),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFileNameSection(isDark),
                    const SizedBox(height: 18),
                    _buildLocationSection(isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Fixed buttons at bottom
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 20,
              ),
              child: _buildActions(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'Save PDF',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFileNameSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'File Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF059669).withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'REQUIRED',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: _isFocused
                ? LinearGradient(
              colors: [
                const Color(0xFF059669).withValues(alpha: 0.1),
                const Color(0xFF059669).withValues(alpha: 0.05),
              ],
            )
                : null,
            color: _isFocused
                ? null
                : (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? const Color(0xFF059669)
                  : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1)),
              width: _isFocused ? 2 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: TextField(
            controller: _fileNameController,
            focusNode: _focusNode,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: 'Enter file name',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
              ),
              suffixText: '.pdf',
              suffixStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF059669).withValues(alpha: 0.7),
              ),
              prefixIcon: Icon(
                Icons.description_rounded,
                size: 18,
                color: _isFocused
                    ? const Color(0xFF059669)
                    : (isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4)),
              ),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Save Location',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF059669).withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        LocationTile(
          icon: Icons.download_rounded,
          title: 'Downloads',
          subtitle: '/Download/',
          color: const Color(0xFF059669),
          isSelected: _selectedLocation == 'downloads',
          onTap: () => setState(() => _selectedLocation = 'downloads'),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        LocationTile(
          icon: Icons.folder_special_rounded,
          title: 'AgriGuard Folder',
          subtitle: '/Download/AgriGuard/',
          color: const Color(0xFF6366F1),
          isSelected: _selectedLocation == 'agriguard',
          onTap: () => setState(() => _selectedLocation = 'agriguard'),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        LocationTile(
          icon: Icons.folder_outlined,
          title: 'Documents',
          subtitle: '/Documents/',
          color: const Color(0xFFF59E0B),
          isSelected: _selectedLocation == 'documents',
          onTap: () => setState(() => _selectedLocation = 'documents'),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleSave(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 18),
                SizedBox(width: 6),
                Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleSave(BuildContext context) {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please enter a file name'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'fileName': '$fileName.pdf',
      'location': _selectedLocation,
    });
  }
}