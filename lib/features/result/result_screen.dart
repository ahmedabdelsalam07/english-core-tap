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
                    _EnglishSection(result: _result),
                    const SizedBox(height: 16),
                    if (showPhonetic) ...[
                      _ArabicPhoneticSection(result: _result),
                      const SizedBox(height: 16),
                    ],
                    _TranslationSection(result: _result),
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
  const _EnglishSection({required this.result});

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
              Expanded(
                child: _SectionLabel(
                  icon: Icons.text_fields_rounded,
                  label: l10n.resultEnglish,
                ),
              ),
              const SizedBox(width: 8),
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
          const SizedBox(height: 14),
          AudioPlayerWidget(
            key: ValueKey('${result.englishText}_${settings.playbackSpeed}'),
            text: result.englishText,
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
        // Ellipsize instead of overflowing on narrow screens.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.textSoft,
            ),
          ),
        ),
      ],
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
              Expanded(
                child: _SectionLabel(
                  icon: Icons.translate_rounded,
                  label: l10n.resultArabicPronunciation,
                ),
              ),
              const SizedBox(width: 8),
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
              Expanded(
                child: _SectionLabel(
                  icon: Icons.g_translate_rounded,
                  label: l10n.resultTranslation,
                ),
              ),
              const SizedBox(width: 8),
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

/// WhatsApp-style voice message audio player bar.
class AudioPlayerWidget extends ConsumerStatefulWidget {
  final String text;
  const AudioPlayerWidget({
    super.key,
    required this.text,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() =>
      _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  double _speed = 1.0;
  bool _speedInitialized = false;
  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tts = ref.watch(ttsServiceProvider);
    final settings = ref.watch(settingsControllerProvider);

    if (!_speedInitialized) {
      _speedInitialized = true;
      _speed = settings.playbackSpeed;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([tts.isSpeaking, tts.isPaused, tts.progress]),
      builder: (context, _) {
        final speaking = tts.isSpeaking.value;
        final paused = tts.isPaused.value;
        final progress = tts.progress.value;
        return _VoiceBar(
          speaking: speaking,
          paused: paused,
          progress: progress,
          speed: _speed,
          dotCtrl: _dotCtrl,
          onPlayPause: () async {
            final messenger = ScaffoldMessenger.of(context);
            final errorText = AppLocalizations.of(context).ttsError;
            try {
              if (speaking) {
                await tts.pause();
              } else if (paused) {
                await tts.resume();
              } else {
                await tts.speak(widget.text, speed: _speed);
              }
            } catch (_) {
              if (mounted) {
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(errorText)));
              }
            }
          },
          onSpeedChanged: (s) async {
            setState(() => _speed = s);
            await tts.setSpeed(s);
            ref.read(settingsControllerProvider.notifier).setPlaybackSpeed(s);
          },
        );
      },
    );
  }
}

class _VoiceBar extends StatelessWidget {
  final bool speaking;
  final bool paused;
  final double progress;
  final double speed;
  final AnimationController dotCtrl;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSpeedChanged;

  const _VoiceBar({
    required this.speaking,
    required this.paused,
    required this.progress,
    required this.speed,
    required this.dotCtrl,
    required this.onPlayPause,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: dotCtrl,
            builder: (context, _) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    AppColors.danger,
                    AppColors.danger.withOpacity(0.3),
                    speaking ? dotCtrl.value : 0.0,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _CompactWaveform(progress: progress, active: speaking),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: (speaking && !paused) ? onPlayPause : null,
            child: Icon(
              Icons.pause_rounded,
              color: (speaking && !paused)
                  ? AppColors.danger
                  : AppColors.darkTextSoft,
              size: 26,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () => _showSpeedSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${speed}x',
                style: const TextStyle(
                  color: AppColors.darkTextSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(
                (speaking || paused)
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet with all available speed presets, matching the chips used
  /// on the settings screen.
  void _showSpeedSheet(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  l10n.resultSpeed,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: palette.text,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in playbackSpeeds)
                    ChoiceChip(
                      label: Text('${s}x'),
                      selected: s == speed,
                      onSelected: (_) {
                        Navigator.of(sheetCtx).pop();
                        onSpeedChanged(s);
                      },
                      labelStyle: TextStyle(
                        color:
                            s == speed ? Colors.white : palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: palette.surfaceAlt,
                      showCheckmark: false,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactWaveform extends StatefulWidget {
  final double progress;
  final bool active;
  const _CompactWaveform({required this.progress, required this.active});

  @override
  State<_CompactWaveform> createState() => _CompactWaveformState();
}

class _CompactWaveformState extends State<_CompactWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const int _bars = 30;
  late final List<double> _phases;
  late final List<double> _speeds;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(11);
    _phases = List.generate(_bars, (_) => rnd.nextDouble() * 2 * math.pi);
    _speeds = List.generate(_bars, (_) => 0.6 + rnd.nextDouble() * 1.0);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _CompactWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _level(int i) {
    final t = _ctrl.value * 2 * math.pi;
    final v = (math.sin(t * _speeds[i] + _phases[i]).abs() * 0.7 +
            math.sin(t * _speeds[i] * 2.3 + _phases[i] * 1.7).abs() * 0.3)
        .clamp(0.0, 1.0);
    return (0.12 + 0.88 * math.pow(v, 1.4)).clamp(0.10, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // Bar count adapts to the available width so the waveform never
        // overflows on narrow screens.
        return SizedBox(
          height: 32,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double barWidth = 2.5;
              const double gap = 2.4;
              final int count = math.max(
                12,
                ((constraints.maxWidth + gap) / (barWidth + gap)).floor(),
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(count, (i) {
                  final h = widget.active
                      ? _level(i % _bars)
                      : 0.12 + (i % 4 == 0 ? 0.1 : 0.0);
                  final passed = (i + 1) / count <= widget.progress &&
                      widget.progress > 0;
                  return Container(
                    width: barWidth,
                    height: 32 * h,
                    decoration: BoxDecoration(
                      color: passed
                          ? AppColors.primaryOnDark
                          : Colors.white.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}

