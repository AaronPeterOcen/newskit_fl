// Settings screen for choosing theme mode and viewing accessibility notes.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_mode_provider.dart';

/// Settings screen for managing app appearance and accessibility.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Map of theme modes to user-friendly labels
  static const _labels = {
    ThemeMode.system: 'System',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current theme mode setting
    final currentMode = ref.watch(themeModeProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section title: Appearance
            Text(
              'Appearance',
              style: CupertinoTheme.of(
                context,
              ).textTheme.navLargeTitleTextStyle.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 16),
            // Theme selection control
            CupertinoFormSection(
              header: const Text('Theme'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  // Segmented control for theme selection
                  child: CupertinoSegmentedControl<ThemeMode>(
                    groupValue: currentMode,
                    onValueChanged: (value) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value);
                    },
                    children: {
                      for (final entry in _labels.entries)
                        entry.key: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          child: Text(entry.value),
                        ),
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Accessibility information
            CupertinoFormSection(
              header: const Text('Accessibility'),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                  child: Text(
                    'Light and dark themes are selected to provide strong contrast and preserve text readability across the app.',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
