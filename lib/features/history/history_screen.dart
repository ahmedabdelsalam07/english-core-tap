import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../data/models/history_entry.dart';
import '../../data/models/pronunciation_result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/history_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.historyTitle),
        content: Text(l10n.historyDeleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.historyCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.historyDeleteYes,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyControllerProvider.notifier).clearAll();
    }
  }

  Future<void> _confirmDelete(HistoryEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.historyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.historyCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.historyDeleteYes,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(historyControllerProvider.notifier)
          .removeEntry(entry.englishText);
    }
  }

  void _open(HistoryEntry entry) {
    final result = PronunciationResult(
      englishText: entry.englishText,
      arabicTranslation: entry.arabicTranslation ?? '',
      arabicPhonetic: entry.arabicPhonetic ?? '',
      accent: 'en-US',
      voice: ref.read(settingsControllerProvider).defaultVoice,
      speed: 1.0,
      createdAt: entry.timestamp,
    );
    context.push('/result', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(historyControllerProvider);
    final filtered = _query.trim().isEmpty
        ? all
        : all
            .where((e) =>
                e.englishText.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          if (all.isNotEmpty)
            IconButton(
              tooltip: l10n.historyDeleteAll,
              onPressed: _confirmDeleteAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: all.isEmpty
          ? EmptyState(
              title: l10n.historyEmpty,
              subtitle: l10n.historyEmptyHint,
              useLogo: true,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: l10n.historySearch,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          title: 'No results',
                          useLogo: false,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => _HistoryTile(
                            entry: filtered[index],
                            onTap: () => _open(filtered[index]),
                            onDelete: () => _confirmDelete(filtered[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsServiceProvider);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.md,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.englishText,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if ((entry.arabicPhonetic ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.arabicPhonetic!,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      _relative(entry.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Play',
                onPressed: () => tts.speak(entry.englishText),
                icon: const Icon(Icons.play_circle_outline_rounded,
                    color: AppColors.primary, size: 22),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textSoft, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.day}/${time.month}/${time.year}';
  }
}
