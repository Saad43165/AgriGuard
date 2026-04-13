# AgriGuard Issues Fix Tasks

## Security
- [ ] 1. Remove .env from pubspec assets (API keys bundled in APK)
- [ ] 2. Add .env to .gitignore

## Logic Bugs
- [ ] 3. Fix ThemeProvider dark/light mismatch on init
- [ ] 4. Fix didChangeDependencies args == true (always false) in HomeScreen
- [ ] 5. Fix _generateContentHash always unique (timestamp appended)
- [ ] 6. Remove dead code: clearImagePickerCache never called, ScanService.getSavedScans empty
- [ ] 7. Move file_picker and csv from dev_dependencies to dependencies
- [ ] 8. Add version constraint to printing dependency

## Deprecated APIs
- [ ] 9. Replace WillPopScope with PopScope in register_screen.dart
- [ ] 10. Replace withOpacity() with withValues(alpha:) across all files

## i18n / Translation
- [ ] 11. Add missing translation keys to en.json (capture screen keys)
- [ ] 12. Fix TranslationService instantiated directly instead of via Provider in CaptureScreen and AdvancedSearchScreen

## UI/UX
- [ ] 13. Fix Settings: hide FCM Token, Test Notification, Diagnostics tiles in production
- [ ] 14. Fix ResultsScreen: misleading "Analyzing image..." loading message during severity lookup
- [ ] 15. Fix AdvancedSearchScreen: add loading indicator during API availability check
- [ ] 16. Fix capture cancel button resetting to step 1 instead of step 2
- [ ] 17. Fix profile screen: show loading skeleton instead of "Loading..." name text

## Theme
- [ ] 18. Fix dark theme: add appBarTheme
- [ ] 19. Fix light theme colorScheme onSurface wrong comment
- [ ] 20. Add cardTheme and dialogTheme to AppTheme for consistency

## Architecture
- [ ] 21. Fix inconsistent feature folder naming (PascalCase vs lowercase)
- [ ] 22. Remove ScanService dead code (getSavedScans empty method)
- [ ] 23. Fix stale file comment in ai_analysis_service.dart
