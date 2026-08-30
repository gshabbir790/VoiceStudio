import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/language.dart';
import '../../data/models/project.dart';
import '../../data/models/voice.dart';
import '../../providers/session_provider.dart';
import '../../providers/studio_provider.dart';
import '../onboarding/api_key_screen.dart';
import '../widgets/audio_play_button.dart';

class StudioScreen extends StatefulWidget {
  final VoiceProject? existingProject;
  const StudioScreen({super.key, this.existingProject});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  late final TextEditingController _scriptController;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProject;
    _scriptController = TextEditingController(text: existing?.script ?? '');
    _titleController = TextEditingController(text: existing?.title ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studio = context.read<StudioProvider>();
      studio.resetGenerationState();
      if (existing != null) {
        studio.setLanguage(AppLanguage.fromCode(existing.languageCode));
        studio.setVoice(TtsVoice.byName(existing.voiceName));
        studio.setStyle(existing.style);
      }
    });
  }

  @override
  void dispose() {
    _scriptController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final session = context.read<SessionProvider>();
    final studio = context.read<StudioProvider>();

    if (session.apiKey == null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ApiKeyScreen()));
      return;
    }

    await studio.generate(
      apiKey: session.apiKey!,
      script: _scriptController.text,
      existingProjectId: widget.existingProject?.id,
      title: _titleController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioProvider>();
    final isGenerating = studio.generationState == GenerationState.generating;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProject == null ? 'New voice-over' : 'Edit voice-over'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Project title (optional)'),
            ),
            const SizedBox(height: 14),

            _SectionLabel('Language'),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppLanguage.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final lang = AppLanguage.all[i];
                  final selected = studio.language.code == lang.code;
                  return ChoiceChip(
                    label: Text(lang.displayName),
                    selected: selected,
                    onSelected: (_) => studio.setLanguage(lang),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            _SectionLabel('Script'),
            const SizedBox(height: 8),
            TextField(
              controller: _scriptController,
              maxLines: 8,
              minLines: 5,
              textDirection: studio.language.isRtl ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(hintText: studio.language.placeholder),
            ),
            const SizedBox(height: 18),

            _SectionLabel('Voice'),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: TtsVoice.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final v = TtsVoice.all[i];
                  final selected = studio.voice.name == v.name;
                  return _VoiceChip(voice: v, selected: selected, onTap: () => studio.setVoice(v));
                },
              ),
            ),
            const SizedBox(height: 18),

            _SectionLabel('Style'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: speakingStyles.map((s) {
                final selected = studio.style == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => studio.setStyle(s),
                );
              }).toList(),
            ),

            if (studio.generationState == GenerationState.error && studio.generationError != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(studio.generationError!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                  ],
                ),
              ),
            ],

            if (studio.generationState == GenerationState.success && studio.lastResult != null) ...[
              const SizedBox(height: 18),
              _ResultCard(project: studio.lastResult!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isGenerating ? null : _generate,
              icon: isGenerating
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Icon(Icons.graphic_eq_rounded),
              label: Text(isGenerating ? 'Generating with your Gemini key...' : 'Generate voice-over'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  final TtsVoice voice;
  final bool selected;
  final VoidCallback onTap;
  const _VoiceChip({required this.voice, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.12) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(voice.gender == 'Male' ? Icons.male : Icons.female, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(voice.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              voice.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final VoiceProject project;
  const _ResultCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AudioPlayButton(audioPath: project.audioPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Voice-over ready', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${project.durationSeconds.toStringAsFixed(1)}s • ${project.voiceName}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          if (project.audioPath != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.shareXFiles(
                [XFile(project.audioPath!)],
                text: project.title,
              ),
            ),
        ],
      ),
    );
  }
}
