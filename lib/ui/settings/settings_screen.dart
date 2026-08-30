import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/session_provider.dart';
import '../onboarding/api_key_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  backgroundImage: session.account?.photoUrl != null
                      ? NetworkImage(session.account!.photoUrl!)
                      : null,
                  child: session.account?.photoUrl == null
                      ? const Icon(Icons.person_outline, color: AppColors.primary)
                      : null,
                ),
                title: Text(session.account?.displayName ?? 'Not signed in'),
                subtitle: Text(session.account?.email ?? 'Sign in from the API key screen'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Gemini API key',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.vpn_key_outlined),
                title: Text(session.apiKey == null ? 'No key saved' : 'Key connected'),
                subtitle: Text(session.apiKey == null
                    ? 'Add your own key to start generating voice-overs.'
                    : '•••• •••• ${session.apiKey!.length > 4 ? session.apiKey!.substring(session.apiKey!.length - 4) : ''}'),
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ApiKeyScreen()),
                  ),
                  child: Text(session.apiKey == null ? 'Add' : 'Change'),
                ),
              ),
              if (session.apiKey != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link_off, color: AppColors.danger),
                  title: const Text('Remove saved key', style: TextStyle(color: AppColors.danger)),
                  onTap: () => _confirmRemoveKey(context, session),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'About',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: Text(_version, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('How billing works'),
                subtitle: const Text('Every voice-over is generated using your own Gemini key and billed to your own Google account.'),
                onTap: () => launchUrl(
                  Uri.parse('https://ai.google.dev/gemini-api/docs/pricing'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (session.account != null || session.apiKey != null)
            OutlinedButton.icon(
              onPressed: () async {
                await session.signOutAndClearKey();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const ApiKeyScreen(isInitialSetup: true)),
                    (route) => false,
                  );
                }
              },
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out & remove key'),
            ),
        ],
      ),
    );
  }

  void _confirmRemoveKey(BuildContext context, SessionProvider session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove API key?'),
        content: const Text('You\'ll need to add a key again before generating any more voice-overs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              session.clearKeyOnly();
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _SectionCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
