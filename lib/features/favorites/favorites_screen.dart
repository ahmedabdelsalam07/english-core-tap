import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../data/models/favorite_entry.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/empty_state.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: favorites.isEmpty
          ? EmptyState(
              title: l10n.favoritesEmpty,
              subtitle: l10n.favoritesEmptyHint,
              useLogo: true,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _FavoriteCard(entry: favorites[index]),
            ),
    );
  }
}

class _FavoriteCard extends ConsumerWidget {
  final FavoriteEntry entry;
  const _FavoriteCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final tts = ref.watch(ttsServiceProvider);
    final result = entry.result;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.lg,
      child: InkWell(
        borderRadius: AppRadius.lg,
        onTap: () => context.push('/result', extra: result),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.englishText,
                      textDirection: TextDirection.ltr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.favoritesDelete,
                    onPressed: () async {
                      await ref
                          .read(favoritesControllerProvider.notifier)
                          .remove(result.englishText);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                result.arabicPhonetic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.arabicTranslation,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 14,
                  color: palette.textSoft,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    _date(result.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSoft,
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: tts.isSpeaking,
                    builder: (_, isSpeakingValue, __) {
                      return IconButton.filledTonal(
                        tooltip: l10n.resultPlay,
                        onPressed: () async {
                          if (isSpeakingValue) {
                            await tts.stop();
                          } else {
                            await tts.speak(
                              result.englishText,
                              gender: ref
                                  .read(settingsControllerProvider)
                                  .defaultVoice,
                              speed: result.speed,
                            );
                          }
                        },
                        icon: Icon(
                          isSpeakingValue
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                          color: palette.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _date(DateTime t) => '${t.day}/${t.month}/${t.year}';
}
