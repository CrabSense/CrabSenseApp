import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/bloc/sync/sync_bloc.dart';
import '../../../../shared/bloc/sync/sync_event.dart';
import '../../../../shared/bloc/sync/sync_state.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_hub_scaffold.dart';

/// Ngoại tuyến & đồng bộ — SyncBloc + profile triggerSync.
class OfflineSyncScreen extends ConsumerWidget {
  const OfflineSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStateProvider).valueOrNull;
    final syncSummary = profile?.syncSummary;
    final fmt = DateFormat('HH:mm:ss dd/MM/yyyy');

    return ProfileHubScaffold(
      title: 'NGOẠI TUYẾN & ĐỒNG BỘ',
      onRefresh: () async {
        context.read<SyncBloc>().add(const SyncPendingCountRefreshed());
        await ref.read(profileStateProvider.notifier).triggerSync();
      },
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, sync) {
          final lastAt = sync.lastSyncTimestamp ??
              syncSummary?.lastSyncedAt ??
              DateTime.now();
          final pending = sync.pendingCount;
          final queue = syncSummary?.offlineQueueCount ?? pending;
          final conflicts = syncSummary?.conflictCount ?? 0;
          final status = sync.isSyncing
              ? 'Đang đồng bộ…'
              : sync.isOffline
                  ? 'Ngoại tuyến'
                  : (pending > 0 ? 'Có dữ liệu chờ' : 'Đã đồng bộ');

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              HubCard(
                child: Row(
                  children: [
                    Icon(
                      sync.isOffline
                          ? Icons.cloud_off_rounded
                          : Icons.cloud_done_rounded,
                      color: sync.isOffline ? kHomeOrange : kHomeGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sync.isConnected
                                ? 'Đã kết nối mạng'
                                : 'Không có kết nối — dữ liệu lưu trên máy',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          if (sync.errorMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              sync.errorMessage!,
                              style: const TextStyle(
                                color: kHomeOrange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HubCard(
                child: Column(
                  children: [
                    HubTile(
                      icon: Icons.cloud_done_outlined,
                      title: 'Trạng thái đồng bộ',
                      value: status,
                    ),
                    HubTile(
                      icon: Icons.queue_play_next_rounded,
                      title: 'Hàng chờ ngoại tuyến',
                      value: '$queue mục',
                    ),
                    HubTile(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Dữ liệu chờ tải lên',
                      value: '$pending mục',
                    ),
                    HubTile(
                      icon: Icons.access_time_rounded,
                      title: 'Đồng bộ gần nhất',
                      value: fmt.format(lastAt),
                      subtitle: sync.formattedLastSyncTime,
                    ),
                    HubTile(
                      icon: Icons.sync_problem_rounded,
                      title: 'Xung đột dữ liệu',
                      value: conflicts == 0
                          ? 'Không có xung đột'
                          : '$conflicts xung đột',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: sync.isSyncing
                      ? null
                      : () {
                          context
                              .read<SyncBloc>()
                              .add(const SyncManualTriggered());
                          ref.read(profileStateProvider.notifier).triggerSync();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã kích hoạt đồng bộ'),
                            ),
                          );
                        },
                  icon: sync.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    sync.isSyncing ? 'Đang đồng bộ…' : 'Đồng bộ ngay',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: kHomeCyan,
                    foregroundColor: kHomeNavyDeep,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
