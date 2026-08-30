import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/session_provider.dart';
import '../home/home_screen.dart';

class ApiKeyScreen extends StatefulWidget {
  final bool isInitialSetup;
  const ApiKeyScreen({super.key, this.isInitialSetup = false});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAiStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/apikey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isInitialSetup)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              const SizedBox(height: 8),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                'Connect your own Gemini account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Voice Studio never uses the developer\'s API credits. Every '
                'voice you generate is billed to your own free Google Gemini '
                'API key, on your own device.',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.4),
              ),
              const SizedBox(height: 28),

              // Step 1: optional Google sign-in, to confirm identity.
              _StepCard(
                stepNumber: '1',
                title: 'Sign in with Google',
                subtitle: session.account != null
                    ? 'Signed in as ${session.account!.email}'
                    : 'Confirms which Google account you\'ll create your key with. Optional.',
                trailing: session.account != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : OutlinedButton(
                        onPressed: () => session.signInWithGoogle(),
                        child: const Text('Sign in'),
                      ),
              ),
              const SizedBox(height: 14),

              // Step 2: get + paste API key.
              _StepCard(
                stepNumber: '2',
                title: 'Paste your Gemini API key',
                subtitle: 'Free to create at Google AI Studio, under the same account.',
                trailing: TextButton(
                  onPressed: _openAiStudio,
                  child: const Text('Get a key'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'AIza...',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (session.lastError != null) ...[
                const SizedBox(height: 10),
                Text(session.lastError!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: session.isVerifying
                      ? null
                      : () async {
                          final error = await session.saveApiKey(_controller.text);
                          if (error == null && mounted) {
                            if (widget.isInitialSetup) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            } else {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                  child: session.isVerifying
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Verify & Continue'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your key is stored securely on this device only and is never sent anywhere except directly to Google\'s API.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(stepNumber, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
