import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../data/services/update_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/section_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth.valueOrNull;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        actions: const [LanguageSwitcher()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _SettingsSection(
            title: l10n.settingsAppearance,
            icon: Icons.palette_outlined,
            child: SegmentedButton<AppThemeMode>(
              segments: [
                ButtonSegment(
                  value: AppThemeMode.light,
                  label: Text(l10n.settingsLight),
                  icon: const Icon(Icons.light_mode_outlined, size: 16),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  label: Text(l10n.settingsDark),
                  icon: const Icon(Icons.dark_mode_outlined, size: 16),
                ),
                ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text(l10n.settingsSystem),
                  icon: const Icon(Icons.brightness_auto_outlined, size: 16),
                ),
              ],
              selected: {settings.themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => controller.setThemeMode(s.first),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsDefaultVoice,
            icon: Icons.record_voice_over_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<VoiceGender>(
                  segments: [
                    ButtonSegment(
                      value: VoiceGender.auto,
                      label: Text(l10n.settingsAuto),
                    ),
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
                  selected: {settings.defaultVoice},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      controller.setDefaultVoice(s.first),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable:
                            ref.watch(ttsServiceProvider).activeVoiceName,
                        builder: (context, name, __) => Text(
                          name.isEmpty ? '—' : '🔊 $name',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textSoft,
                          ),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: l10n.resultPlay,
                      onPressed: () async {
                        final messenger =
                            ScaffoldMessenger.of(context);
                        try {
                          await ref
                              .read(ttsServiceProvider)
                              .speak(
                                'Hello, this is my English Core voice.',
                                gender: settings.defaultVoice,
                                speed: settings.playbackSpeed,
                              );
                        } catch (_) {
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(l10n.ttsError)),
                            );
                        }
                      },
                      icon: Icon(Icons.play_arrow_rounded,
                          size: 22, color: palette.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsSpeed,
            icon: Icons.speed_rounded,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in playbackSpeeds)
                  ChoiceChip(
                    label: Text('${s}x'),
                    selected: settings.playbackSpeed == s,
                    onSelected: (_) => controller.setPlaybackSpeed(s),
                    labelStyle: TextStyle(
                      color: settings.playbackSpeed == s
                          ? Colors.white
                          : palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: palette.surfaceAlt,
                    showCheckmark: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsAccent,
            icon: Icons.flag_rounded,
            child: _SettingRow(
              icon: Icons.star_rounded,
              label: l10n.settingsAccentUs,
              trailing: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsArabicPhonetic,
            icon: Icons.translate_rounded,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsArabicPhoneticOn),
              value: settings.showArabicPhonetic,
              onChanged: controller.setShowArabicPhonetic,
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsLanguage,
            icon: Icons.language_rounded,
            child: SegmentedButton<AppLocale>(
              segments: [
                ButtonSegment(
                  value: AppLocale.ar,
                  label: Text(l10n.settingsArabic),
                ),
const ButtonSegment(
                  value: AppLocale.en,
                  label: Text('English'),
                ),
              ],
              selected: {settings.locale},
              showSelectedIcon: false,
              onSelectionChanged: (s) => controller.setLocale(s.first),
            ),
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: l10n.settingsAccount,
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.badge_outlined,
                  label: l10n.settingsUsername,
                  value: user?.username ?? '—',
                ),
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(l10n.settingsLogout),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.historyTitle,
            icon: Icons.history_rounded,
            child: _SettingRow(
              icon: Icons.delete_sweep_outlined,
              label: l10n.settingsClearHistory,
              trailing: IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () async {
                  await ref.read(historyControllerProvider.notifier).clearAll();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.privacyTitle,
            icon: Icons.shield_outlined,
            child: _SettingRow(
              icon: Icons.privacy_tip_outlined,
              label: l10n.privacyTitle,
              onTap: () => context.push('/privacy'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsTerms,
            icon: Icons.description_outlined,
            child: _SettingRow(
              icon: Icons.article_outlined,
              label: l10n.settingsTerms,
              onTap: () => context.push('/terms'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsAbout,
            icon: Icons.info_outline_rounded,
            child: _SettingRow(
              icon: Icons.star_rounded,
              label: l10n.settingsAbout,
              onTap: () => context.push('/about'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsCheckUpdate,
            icon: Icons.system_update_alt_rounded,
            child: _UpdateSection(palette: palette),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${l10n.settingsAppVersion} ${Constants.appVersion}',
              style: TextStyle(
                fontSize: 12,
                color: palette.textSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsLogout),
        content: Text(l10n.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.historyCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsLogout,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.logoutSuccess)),
        );
      }
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      icon: icon,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      borderRadius: AppRadius.md,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: TextStyle(color: palette.textSoft, fontSize: 13),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _UpdateSection extends StatefulWidget {
  final AppPalette palette;
  const _UpdateSection({required this.palette});

  @override
  State<_UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<_UpdateSection> {
  final UpdateService _updater = UpdateService();
  bool _checking = false;

  Future<void> _check() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checking = true);
    try {
      final info = await _updater.checkForUpdate();
      if (!mounted) return;
      if (info.updateAvailable) {
        await _showUpdateDialog(info);
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.updateUpToDate)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.updateFailed)));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _showUpdateDialog(UpdateInfo info) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.updateLater),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(l10n.updateNow),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _updater.applyUpdate(info);
      // On web applyUpdate reloads the page; on Android it opens the browser.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '${l10n.settingsAppVersion} ${Constants.appVersion}',
            style: TextStyle(color: widget.palette.textSoft, fontSize: 13),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: _checking ? null : _check,
          icon: _checking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(l10n.settingsCheckUpdate),
        ),
      ],
    );
  }
}
