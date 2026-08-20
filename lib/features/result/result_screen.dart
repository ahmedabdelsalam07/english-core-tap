import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../data/models/pronunciation_result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/services_provider.dart';
import '../../widgets/copy_button.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final PronunciationResult result;
  const ResultScreen({super.key, required this.result});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late PronunciationResult _result;
  late VoiceGender _voice;

  @override
  void initState() {
    super.initState();
    _result = widget.result;
    _voice = widget.result.voice;
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final text = StringBuffer()
      ..writeln('${l10n.resultEnglish}:')
      ..writeln(_result.englishText)
      ..writeln()
      ..writeln('${l10n.resultArabicPronunciation}:')
      ..writeln(_result.arabicPhonetic)
      ..writeln()
      ..writeln('${l10n.resultTranslation}:')
      ..writeln(_result.arabicTranslation)
      ..writeln()
      ..writeln('â€” ENGLISH CORE (MR. THARWAT TAWFIQ)');
    await Share.share(text.toString(), subject: 'ENGLISH CORE');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesControllerProvider);
    final isFavorite = favorites.any(
      (e) => e.result.englishText == _result.englishText,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(l10n, isFavorite),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EnglishSection(
                      result: _result,
                      voice: _voice,
                      onVoiceChanged: (v) => setState(() => _voice = v),
                    ),
                    const SizedBox(height: 16),
                    _ArabicPhoneticSection(result: _result),
                    const SizedBox(height: 16),
                    _TranslationSection(result: _result),
                    if (_result.nativeAudioUrl != null) ...[
                      const SizedBox(height: 16),
                      _NativeAudioCard(url: _result.nativeAudioUrl!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n, bool isFavorite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: Text(
              l10n.resultTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _share,
            tooltip: l10n.resultShare,
            icon: const Icon(Icons.share_rounded),
          ),
          IconButton(
            onPressed: () async {
              final controller = ref.read(favoritesControllerProvider.notifier);
              await controller.toggle(_result);
              final nowFav = controller.isFavorite(_result.englishText);
              _result = _result.copyWith(favorite: nowFav);
              if (mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        nowFav
                            ? l10n.resultFavoriteAdd
                            : l10n.resultFavoriteRemove,
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
              }
            },
            tooltip: l10n.resultAddFavorite,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                color: isFavorite ? AppColors.danger : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnglishSection extends ConsumerWidget {
  final PronunciationResult result;
  final VoiceGender voice;
  final ValueChanged<VoiceGender> onVoiceChanged;
  const _EnglishSection({
    required this.result,
    required this.voice,
    required this.onVoiceChanged,
  });

@override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionLabel(icon: Icons.text_fields_rounded, label: l10n.resultEnglish),
              const Spacer(),
              CopyButton(text: result.englishText),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            result.englishText,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
          ),
          const SizedBox(height: 12),
          _VoiceSelector(voice: voice, onChanged: onVoiceChanged),
          const SizedBox(height: 14),
          AudioPlayerWidget(
            text: result.englishText,
            voice: voice,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSoft,
          ),
        ),
      ],
    );
  }
}

class _VoiceSelector extends StatelessWidget {
  final VoiceGender voice;
  final ValueChanged<VoiceGender> onChanged;
  const _VoiceSelector({required this.voice, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<VoiceGender>(
      segments: [
        ButtonSegment(
          value: VoiceGender.male,
          label: Text(l10n.settingsMale),
          icon: const Icon(Icons.male, size: 16),
        ),
        ButtonSegment(
          value: VoiceGender.female,
          label: Text(l10n.settingsFemale),
          icon: const Icon(Icons.female, size: 16),
        ),
      ],
      selected: {voice},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ArabicPhoneticSection extends StatelessWidget {
  final PronunciationResult result;
  const _ArabicPhoneticSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.softGradient,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionLabel(
                icon: Icons.translate_rounded,
                label: l10n.resultArabicPronunciation,
              ),
              const Spacer(),
              CopyButton(text: result.arabicPhonetic),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.arabicPhonetic,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _TranslationSection extends StatelessWidget {
  final PronunciationResult result;
  const _TranslationSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionLabel(icon: Icons.g_translate_rounded, label: l10n.resultTranslation),
              const Spacer(),
              CopyButton(text: result.arabicTranslation),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.arabicTranslation,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _NativeAudioCard extends ConsumerStatefulWidget {
  final String url;
  const _NativeAudioCard({required this.url});

  @override
  ConsumerState<_NativeAudioCard> createState() => _NativeAudioCardState();
}

class _NativeAudioCardState extends ConsumerState<_NativeAudioCard> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final audio = ref.watch(audioPlayerServiceProvider);
    final playing = ref.watch(audioPlayerServiceProvider).playingUrl.value;
    final isCurrent = playing == widget.url;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lg,
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.resultAccent,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton.filled(
            onPressed: isCurrent ? () => audio.stop() : () => audio.play(widget.url),
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            icon: Icon(isCurrent ? Icons.stop_rounded : Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

/// Full TTS audio player: play / pause / resume / stop / replay + progress
/// + waveform + speed.
class AudioPlayerWidget extends ConsumerStatefulWidget {
  final String text;
  final VoiceGender voice;
  const AudioPlayerWidget({super.key, required this.text, required this.voice});

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  Timer? _timer;
  double _speed = 1.0;
  final int _estimatedMsPerChar = 90;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _estimatedDuration =>
      Duration(milliseconds: (widget.text.length * _estimatedMsPerChar).clamp(800, 30000));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tts = ref.watch(ttsServiceProvider);
    final speaking = ref.watch(ttsServiceProvider).isSpeaking.value;
    final paused = ref.watch(ttsServiceProvider).isPaused.value;
    final progress = ref.watch(ttsServiceProvider).progress.value;

    final duration = _estimatedDuration;
    final current = Duration(milliseconds: (duration.inMilliseconds * progress).round());

    return Column(
      children: [
        _Waveform(progress: progress, active: speaking || paused),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: l10n.resultReplay,
              onPressed: () async {
                try {
                  await tts.replay();
                } catch (_) {}
              },
              icon: const Icon(Icons.replay_rounded),
            ),
            const SizedBox(width: 8),
            Material(
              shape: const CircleBorder(),
              color: AppColors.primary,
              child: InkWell(
                customBorder: const CircleBorder(),
onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    if (speaking) {
                      await tts.pause();
                    } else if (paused) {
                      await tts.resume();
                    } else {
                      await tts.speak(
                        widget.text,
                        gender: widget.voice,
                        speed: _speed,
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(l10n.ttsError)),
                        );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    speaking
                        ? Icons.pause_rounded
                        : paused
                            ? Icons.play_arrow_rounded
                            : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.resultStop,
              onPressed: () => tts.stop(),
              icon: const Icon(Icons.stop_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _fmt(current),
              style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
            ),
            const Spacer(),
            Text(
              _fmt(duration),
              style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speed_rounded, size: 16, color: AppColors.textSoft),
            const SizedBox(width: 8),
            for (final s in playbackSpeeds)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text('${s}x'),
                  selected: _speed == s,
                  onSelected: (_) async {
                    setState(() => _speed = s);
                    await tts.setSpeed(s);
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setPlaybackSpeed(s);
                  },
                  visualDensity: VisualDensity.compact,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _speed == s ? Colors.white : AppColors.primary,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.lavender,
                  showCheckmark: false,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Waveform extends StatefulWidget {
  final double progress;
  final bool active;
  const _Waveform({required this.progress, required this.active});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const int _bars = 24;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_bars, (i) {
              final animated = widget.active
                  ? 0.35 + 0.65 * ((i.isEven ? _controller.value : 1 - _controller.value))
                  : 0.3 + 0.4 * ((i * 7919) % 5) / 5;
              final passed = (i + 1) / _bars <= widget.progress;
              return Container(
                width: 4,
                height: 40 * animated,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: passed ? AppColors.primary : AppColors.lavender,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
