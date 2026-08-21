import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/services_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/error_mapper.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/section_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

static const List<String> _examples = [
    'hello',
    'good morning',
    'how are you',
    'beautiful',
    'مرحباً',
    'صباح الخير',
    'كيف حالك',
    'جميل',
  ];

  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  @override
  void initState() {
    super.initState();
    _listenForResult();
    _autoCheckForUpdate();
  }

  /// Tags already offered this session. Guards against an endless
  /// prompt-reload-prompt loop if the running build's version constant ever
  /// drifts from the latest release tag.
  static final Set<String> _promptedUpdateTags = <String>{};

  /// Silent update check once per app launch: if a newer GitHub release
  /// exists, offer it immediately — users never have to hunt for updates.
  Future<void> _autoCheckForUpdate() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || kDebugMode) return;
    try {
      final info = await ref.read(updateCheckerProvider).checkForUpdate();
      if (!mounted ||
          !info.updateAvailable ||
          _promptedUpdateTags.contains(info.latestTag)) {
        return;
      }
      _promptedUpdateTags.add(info.latestTag);
      final l10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.updateNewVersion(info.latestTag)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                info.releaseNotes.isEmpty ? info.latestTag : info.releaseNotes,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.updateLater),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(updateCheckerProvider).applyUpdate(info);
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(l10n.updateNow),
            ),
          ],
        ),
      );
    } catch (_) {
      // Silent failure: connectivity hiccups must not annoy the user.
    }
  }

  void _listenForResult() {
    Future.microtask(() {
      if (!mounted) return;
      ref.listenManual(homeControllerProvider, (prev, next) {
        if (next.phase == HomePhase.done && next.result != null) {
          context.push('/result', extra: next.result);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _process([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inputEmptyError)),
      );
      return;
    }
    if (_controller.text != text) _controller.text = text;
    FocusScope.of(context).unfocus();
    final settings = ref.read(settingsControllerProvider);
    await ref.read(homeControllerProvider.notifier).process(
          text,
          voice: settings.defaultVoice,
          speed: settings.playbackSpeed,
        );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
    }
  }

  Future<void> _speechToText() async {
    final l10n = AppLocalizations.of(context);
    final speech = ref.read(speechServiceProvider);
    if (!speech.isAvailable.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.speechNotAvailable)),
      );
      return;
    }
    final permitted = await speech.requestPermission();
    if (!permitted) {
      _showMicPermissionDialog(l10n);
      return;
    }
    final result = await speech.listen();
    if (result != null && result.isNotEmpty) {
      _controller.text = result;
      await speech.stop();
      await _process(result);
    } else {
      await speech.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.speechNoResult)),
        );
      }
    }
  }

  void _showMicPermissionDialog(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.micPermissionTitle),
        content: Text(l10n.micPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.micPermissionCancel),
          ),
        ],
      ),
    );
  }

  void _clear() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = ref.watch(homeControllerProvider);
    final phase = home.phase;
    final loading = phase == HomePhase.analyzing ||
        phase == HomePhase.preparing ||
        phase == HomePhase.translating;
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundDecoration(),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(settings.themeMode),
                  const SizedBox(height: 18),
                  _buildTitle(l10n),
                  const SizedBox(height: 22),
                  _buildInputCard(l10n),
                  const SizedBox(height: 16),
                  _buildVoiceSpeedRow(l10n, settings),
                  const SizedBox(height: 18),
                  _buildCta(l10n, loading, phase),
                  if (loading) ...[
                    const SizedBox(height: 18),
                    _LoadingIndicator(
                      message: switch (phase) {
                        HomePhase.analyzing => l10n.mainCtaLoading1,
                        HomePhase.preparing => l10n.mainCtaLoading2,
                        _ => l10n.mainCtaLoading3,
                      },
                    ),
                  ],
                  if (home.error != null) ...[
                    const SizedBox(height: 18),
                    ErrorBanner(
                      message: errorMessage(context, home.error!),
                      onRetry: () => _process(),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _buildExamples(l10n),
                  const SizedBox(height: 18),
                  _RecentHistory(onTap: _process),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeMode mode) {
    final palette = AppPalette.of(context);
    final headerL10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final username = auth.valueOrNull?.username;
    return Row(
      children: [
        // LOGO ONLY — brand symbol, no name/number from the full asset.
        const LogoMark(size: 46),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username == null || username.isEmpty
                    ? 'English Core'
                    : '${headerL10n.homeWelcome}، $username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      color: palette.text,
                    ),
              ),
              Text(
                'MR. THARWAT TAWFIQ',
                style: TextStyle(
                  fontSize: 10,
                  color: palette.textSoft,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: mode == AppThemeMode.dark ? 'Light mode' : 'Dark mode',
          icon: Icon(
            mode == AppThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_outlined,
            color: palette.textSoft,
          ),
          onPressed: () {
            final controller = ref.read(settingsControllerProvider.notifier);
            controller.setThemeMode(
              mode == AppThemeMode.dark
                  ? AppThemeMode.light
                  : AppThemeMode.dark,
            );
          },
        ),
        LanguageSwitcher(iconColor: palette.textSoft),
      ],
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        Text(
          l10n.homeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.homeAccent,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.secondary,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.homeSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSoft,
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget _buildInputCard(AppLocalizations l10n) {
    final palette = AppPalette.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, __) {
              final isArabic = _arabicRegex.hasMatch(value.text);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _process(),
                    style: TextStyle(fontSize: 18, color: palette.text),
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: l10n.inputPlaceholder,
                      hintStyle: TextStyle(color: palette.textSoft),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: isArabic
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      isArabic ? 'عربي → English' : 'English → عربي',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ToolButton(
                icon: Icons.content_paste_rounded,
                label: l10n.inputPaste,
                onTap: _paste,
              ),
              const SizedBox(width: 8),
              _ToolButton(
                icon: Icons.mic_none_rounded,
                label: l10n.inputMic,
                onTap: _speechToText,
              ),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (_, value, __) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: l10n.inputClear,
                    icon: Icon(Icons.close_rounded,
                        color: AppPalette.of(context).textSoft),
                    onPressed: _clear,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSpeedRow(AppLocalizations l10n, settings) {
    final palette = AppPalette.of(context);
    final dropdownStyle = TextStyle(
      color: palette.text,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Expanded(
          child: SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.resultVoice,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<VoiceGender>(
                    value: settings.defaultVoice,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: palette.surface,
                    style: dropdownStyle,
                    items: [
                      for (final v in VoiceGender.values)
                        DropdownMenuItem(
                          value: v,
                          child: Text(voiceLabel(context, v)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setDefaultVoice(v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.resultSpeed,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: settings.playbackSpeed,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: palette.surface,
                    style: dropdownStyle,
                    items: [
                      for (final s in playbackSpeeds)
                        DropdownMenuItem(
                          value: s,
                          child: Text('${s}x'),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setPlaybackSpeed(v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCta(AppLocalizations l10n, bool loading, HomePhase phase) {
    final label = switch (phase) {
      HomePhase.analyzing => l10n.mainCtaLoading1,
      HomePhase.preparing => l10n.mainCtaLoading2,
      HomePhase.translating => l10n.mainCtaLoading3,
      _ => l10n.mainCta,
    };
    return Material(
      borderRadius: AppRadius.md,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        child: InkWell(
          onTap: loading ? null : _process,
          child: Container(
            height: 58,
            alignment: Alignment.center,
            child: loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        l10n.mainCta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamples(AppLocalizations l10n) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.tryExamples} ',
          style: TextStyle(
            fontSize: 13,
            color: palette.textSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final example in _examples)
              ActionChip(
                label: Text(
                  example,
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  _controller.text = example;
                  _process(example);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.surfaceAlt,
      borderRadius: AppRadius.pill,
      child: InkWell(
        borderRadius: AppRadius.pill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: palette.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final String message;
  const _LoadingIndicator({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: TextStyle(
            color: palette.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RecentHistory extends ConsumerWidget {
  final ValueChanged<String> onTap;
  const _RecentHistory({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(historyControllerProvider);
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    if (entries.isEmpty) return const SizedBox.shrink();
    final recent = entries.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded,
                size: 18, color: palette.textSoft),
            const SizedBox(width: 6),
            Text(
              l10n.recentHistory,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.textSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final e in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.md,
              child: InkWell(
                borderRadius: AppRadius.md,
                onTap: () => onTap(e.englishText),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.volume_up_outlined,
                          size: 18, color: palette.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.englishText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: palette.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.surfaceAlt.withOpacity(0.55),
              palette.background,
            ],
            stops: const [0.0, 0.45],
          ),
        ),
      ),
    );
  }
}
