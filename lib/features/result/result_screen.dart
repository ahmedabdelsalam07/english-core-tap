import 'dart:async';
import 'dart:math' as math;

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
  VoiceGender _voice = VoiceGender.auto;

  @override
  void initState() {
    super.initState();
    _result = widget.result;
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
      ..writeln('— ENGLISH CORE (MR. THARWAT TAWFIQ)');
    await Share.share(text.toString(), subject: 'ENGLISH CORE');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final favorites = ref.watch(favoritesControllerProvider);
    final isFavorite = favorites.any(
      (e) => e.result.englishText == _result.englishText,
    );
    // The result screen follows the app-wide default voice.
    _voice = settings.defaultVoice;
    final showPhonetic =
        settings.showArabicPhonetic && _result.arabicPhonetic.isNotEmpty;

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
                      onVoiceChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setDefaultVoice(v),
                    ),
                    const SizedBox(height: 16),
                    if (showPhonetic) ...[
                      _ArabicPhoneticSection(result: _result),
                      const SizedBox(height: 16),
                    ],
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
          // HEART — favorite toggle, clearly visible in light & dark.
          IconButton(
            onPressed: () async {
              final controller = ref.read(favoritesControllerProvider.notifier);
              await controller.toggle(_result);
              final nowFav = controller.isFavorite(_result.englishText);
              setState(() => _result = _result.copyWith(favorite: nowFav));
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
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                size: 26,
                color: isFavorite ? AppColors.danger : AppColors.danger,
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
    final settings = ref.watch(settingsControllerProvider);
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
                  color: AppPalette.of(context).text,
                ),
          ),
          const SizedBox(height: 12),
          _VoiceSelector(voice: voice, onChanged: onVoiceChanged),
          const SizedBox(height: 4),
          ValueListenableBuilder<String>(
            valueListenable: ref.watch(ttsServiceProvider).activeVoiceName,
            builder: (context, name, __) => name.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '🔊 $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPalette.of(context).textSoft,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          AudioPlayerWidget(
            key: ValueKey('${result.englishText}_${result.voice.name}_'
                '${settings.playbackSpeed}'),
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
    final palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: palette.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: palette.textSoft,
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
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: palette.softGradient,
        borderRadius: AppRadius.lg,
        border: Border.all(color: palette.primary.withOpacity(0.25)),
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
          SelectableText(
            result.arabicPhonetic,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.secondary,
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
          SelectableText(
            result.arabicTranslation.isEmpty ? '—' : result.arabicTranslation,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.of(context).text,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _NativeAudioCard extends ConsumerWidget {
  final String url;
  const _NativeAudioCard({required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final audio = ref.watch(audioPlayerServiceProvider);
    final playing = ref.watch(audioPlayerServiceProvider).playingUrl.value;
    final isCurrent = playing == url;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lg,
      ),
      child: Row(
        children: [
          Icon(Icons.record_voice_over_rounded,
              color: AppPalette.of(context).primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.resultAccent,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton.filled(
            onPressed:
                isCurrent ? () => audio.stop() : () => audio.play(url),
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
  const AudioPlayerWidget({
    super.key,
    required this.text,
    required this.voice,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  Timer? _timer;
  double _speed = 1.0;
  bool _speedInitialized = false;
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
    final palette = AppPalette.of(context);
    final tts = ref.watch(ttsServiceProvider);
    final settings = ref.watch(settingsControllerProvider);

    // Start from the persisted speed preference exactly once.
    if (!_speedInitialized) {
      _speedInitialized = true;
      _speed = settings.playbackSpeed;
    }

    final duration = _estimatedDuration;

    // Rebuild on every TTS state tick so the waveform, icons and timers
    // react instantly while the voice plays.
    return AnimatedBuilder(
      animation: Listenable.merge(
        [tts.isSpeaking, tts.isPaused, tts.progress],
      ),
      builder: (context, _) {
        final speaking = tts.isSpeaking.value;
        final paused = tts.isPaused.value;
        final progress = tts.progress.value;
        final current = Duration(
          milliseconds: (duration.inMilliseconds * progress).round(),
        );
        return Column(
          children: [
            _Waveform(progress: progress, active: speaking),
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
                            gender:
                                ref.read(settingsControllerProvider).defaultVoice,
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
                  style: TextStyle(fontSize: 11, color: palette.textSoft),
                ),
                const Spacer(),
                Text(
                  _fmt(duration),
                  style: TextStyle(fontSize: 11, color: palette.textSoft),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in playbackSpeeds)
                  ChoiceChip(
                    label: Text('${s}x'),
                    selected: _speed == s,
                    onSelected: (_) async {
                      setState(() => _speed = s);
                      // Apply to the engine immediately and persist app-wide.
                      await tts.setSpeed(s);
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setPlaybackSpeed(s);
                    },
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _speed == s ? Colors.white : palette.primary,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: palette.surfaceAlt,
                    showCheckmark: false,
                  ),
              ],
            ),
          ],
        );
      },
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
  static const int _bars = 30;
  // Per-bar random phase + speed so the wave looks organic, like a real
  // audio level meter (WhatsApp-style), instead of bars moving in sync.
  late final List<double> _phases;
  late final List<double> _speeds;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(11);
    _phases = List.generate(_bars, (_) => rnd.nextDouble() * 2 * math.pi);
    _speeds = List.generate(_bars, (_) => 0.55 + rnd.nextDouble() * 1.0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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

  double _level(int i) {
    final t = _controller.value * 2 * math.pi;
    final v = (math.sin(t * _speeds[i] + _phases[i]).abs() * 0.7 +
            math.sin(t * _speeds[i] * 2.3 + _phases[i] * 1.7).abs() * 0.3)
        .clamp(0.0, 1.0);
    return (0.15 + 0.85 * math.pow(v, 1.4)).clamp(0.12, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_bars, (i) {
              final animated = widget.active ? _level(i) : 0.10 + (i % 3) * 0.04;
              final passed = (i + 1) / _bars <= widget.progress;
              return Container(
                width: 3.5,
                height: 44 * animated,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color:
                      passed ? palette.primary : palette.divider,
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
