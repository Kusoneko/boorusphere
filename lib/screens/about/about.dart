import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../entity/app_version.dart';
import '../../source/changelog.dart';
import '../../source/version.dart';
import '../../utils/extensions/asyncvalue.dart';
import '../../utils/extensions/buildcontext.dart';
import '../app_router.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentVer = ref.watch(versionCurrentProvider
        .select((it) => it.maybeValue ?? AppVersion.zero));
    final latestVer = ref.watch(versionLatestProvider);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorScheme.onBackground,
                ),
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Image.asset(
                  'assets/icons/exported/logo.png',
                  height: 48,
                ),
              ),
              Text(
                'Boorusphere',
                style: context.theme.textTheme.headline6
                    ?.copyWith(fontWeight: FontWeight.w300),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Version $currentVer - ${VersionDataSource.arch}',
                  style: context.theme.textTheme.subtitle2
                      ?.copyWith(fontWeight: FontWeight.w400),
                ),
              ),
              latestVer.when(
                data: (data) => data.isNewerThan(currentVer)
                    ? Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('New update is available'),
                          ),
                          ElevatedButton(
                            onPressed: () => launchUrlString(data.apkUrl,
                                mode: LaunchMode.externalApplication),
                            style: ElevatedButton.styleFrom(elevation: 0),
                            child: Text('Download v$data'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.router.push(
                                ChangelogRoute(
                                  option: ChangelogOption(
                                    type: ChangelogType.git,
                                    version: data,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(elevation: 0),
                            child: const Text('View changes'),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: () => ref.refresh(versionLatestProvider),
                        style: ElevatedButton.styleFrom(elevation: 0),
                        icon: const Icon(Icons.done),
                        label: const Text('You\'re on latest version'),
                      ),
                loading: () => ElevatedButton.icon(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(elevation: 0),
                  icon: Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(),
                  ),
                  label: const Text('Checking for update...'),
                ),
                error: (e, s) => ElevatedButton.icon(
                  onPressed: () => ref.refresh(versionLatestProvider),
                  style: ElevatedButton.styleFrom(elevation: 0),
                  icon: const Icon(Icons.update),
                  label: const Text('Check for update'),
                ),
              ),
              const Divider(height: 32),
              ListTile(
                title: const Text('Changelog'),
                leading: const Icon(Icons.list_alt_rounded),
                onTap: () {
                  context.router.push(
                    ChangelogRoute(
                      option: const ChangelogOption(type: ChangelogType.assets),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('GitHub'),
                leading: const FaIcon(FontAwesomeIcons.github),
                onTap: () => launchUrlString(VersionDataSource.gitUrl,
                    mode: LaunchMode.externalApplication),
              ),
              ListTile(
                title: const Text('Open source licenses'),
                leading: const Icon(Icons.collections_bookmark),
                onTap: () => context.router.push(const LicensesRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
