import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:agriguard_fyp/core/widgets/app_themes.dart';

/// Shows assets/legal/privacy_policy.md. The same file can be published at a
/// public URL for app store listings.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/legal/privacy_policy.md'),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text('Could not load the privacy policy.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: _blocks(context, snap.data!),
          );
        },
      ),
    );
  }

  /// Minimal markdown rendering: headings, bullets, quotes, paragraphs.
  /// Table rows are shown as "a: b" lines.
  List<Widget> _blocks(BuildContext context, String md) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    String clean(String s) => s.replaceAll('**', '').replaceAll('`', '');

    for (final raw in md.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty || RegExp(r'^\|[-| ]+\|$').hasMatch(line.trim())) continue;

      if (line.startsWith('# ')) {
        widgets.add(Text(clean(line.substring(2)), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Text(clean(line.substring(3)), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ));
      } else if (line.startsWith('|')) {
        final cells = line.split('|').map((c) => clean(c.trim())).where((c) => c.isNotEmpty).toList();
        if (cells.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(cells.join(' — '), style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ));
        }
      } else if (line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, top: 3),
          child: Text('•  ${clean(line.substring(2))}', style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ));
      } else if (line.startsWith('> ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(clean(line.substring(2)), style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, height: 1.5)),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(clean(line), style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ));
      }
    }
    return widgets;
  }
}
