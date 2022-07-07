import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../provider/app_theme.dart';
import '../../provider/booru_query.dart';
import '../../routes.dart';

class Settings extends HookConsumerWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booruQuery = ref.watch(booruQueryProvider);
    final booruQueryNotifier = ref.watch(booruQueryProvider.notifier);
    final appTheme = ref.watch(appThemeProvider);

    const themeSettings =
        SettingsThemeData(settingsListBackground: Colors.transparent);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SettingsList(
        lightTheme: themeSettings,
        darkTheme: themeSettings,
        sections: [
          SettingsSection(
            title: const Text('Interface'),
            tiles: [
              SettingsTile.switchTile(
                title: const Text('Darker Theme'),
                description:
                    const Text('Use deeper dark color for the dark mode'),
                leading: const Icon(Icons.brightness_3),
                initialValue: appTheme.isDarkerTheme,
                onToggle: (value) {
                  appTheme.useDarkerTheme(value);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Server'),
            tiles: [
              SettingsTile.switchTile(
                title: const Text('Safe Mode'),
                description: const Text(
                    'Fetch content that are safe.\nNote that rated "safe" on booru-powered site doesn\'t mean "Safe For Work".'),
                leading: const Icon(Icons.phonelink_lock),
                initialValue: booruQuery.safeMode,
                onToggle: (value) {
                  booruQueryNotifier.setSafeMode(value);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Misc'),
            tiles: [
              SettingsTile(
                title: const Text('Open source licenses'),
                leading: const Icon(Icons.collections_bookmark),
                onPressed: (context) =>
                    Navigator.pushNamed(context, Routes.licenses),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
