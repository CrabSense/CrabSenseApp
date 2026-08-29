import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../../profile/presentation/widgets/profile_hub_scaffold.dart';
import '../../data/firebase_hub_models.dart';
import '../../data/firebase_hub_repository.dart';

final firebaseHubRepositoryProvider = Provider((ref) => FirebaseHubRepository());

final firebaseHubSnapshotProvider =
    FutureProvider((ref) => ref.watch(firebaseHubRepositoryProvider).load());

/// Hub Firebase — 4 dịch vụ + hướng dẫn setup.
class FirebaseHubScreen extends ConsumerWidget {
  const FirebaseHubScreen({super.key, this.initialKind});

  final FirebaseServiceKind? initialKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialKind != null) {
      return FirebaseServiceDetailScreen(kind: initialKind!);
    }

    final async = ref.watch(firebaseHubSnapshotProvider);

    return ProfileHubScaffold(
      title: 'FIREBASE',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: () => ref.invalidate(firebaseHubSnapshotProvider),
          icon: const Icon(Icons.refresh_rounded, color: kHomeCyan),
        ),
      ],
      onRefresh: () async {
        ref.invalidate(firebaseHubSnapshotProvider);
        await ref.read(firebaseHubSnapshotProvider.future);
      },
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: kHomeCyan),
        ),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HubCard(child: Text('$e', style: const TextStyle(color: Colors.white70))),
          ],
        ),
        data: (snap) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            HubCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        snap.coreReady
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: snap.coreReady ? kHomeGreen : kHomeOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          snap.coreReady
                              ? 'Firebase Core đã khởi tạo'
                              : 'Firebase Core chưa sẵn sàng',
                          style: const TextStyle(
                            color: kHomeTextMain,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Project: ${snap.projectId}',
                    style: TextStyle(
                      color: const Color(0xFF5A7184),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Package: ${FirebaseSetupGuides.packageName}',
                    style: TextStyle(
                      color: const Color(0xFF5A7184),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(FirebaseSetupGuides.consoleUrl);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Mở Firebase Console'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kHomeCyan,
                      side: BorderSide(color: kHomeCyan.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            HubCard(
              child: Column(
                children: [
                  for (var i = 0; i < snap.statuses.length; i++)
                    HubTile(
                      icon: switch (snap.statuses[i].kind) {
                        FirebaseServiceKind.authentication =>
                          Icons.lock_person_outlined,
                        FirebaseServiceKind.storage => Icons.cloud_upload_outlined,
                        FirebaseServiceKind.crashlytics => Icons.bug_report_outlined,
                        FirebaseServiceKind.cloudMessaging =>
                          Icons.notifications_active_outlined,
                      },
                      title: snap.statuses[i].kind.titleVi,
                      subtitle: snap.statuses[i].kind.subtitleVi,
                      value: snap.statuses[i].statusLabel,
                      onTap: () => context.push(
                        '/firebase?service=${snap.statuses[i].kind.queryValue}',
                      ),
                      showDivider: i != snap.statuses.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            HubCard(
              child: Text(
                'Chạm từng mục để xem hướng dẫn bật trên Console và kiểm tra trong app. '
                'Sau khi thêm plugin mới cần full rebuild (flutter run).',
                style: TextStyle(
                  color: const Color(0xFF5A7184),
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FirebaseServiceDetailScreen extends ConsumerStatefulWidget {
  const FirebaseServiceDetailScreen({super.key, required this.kind});

  final FirebaseServiceKind kind;

  @override
  ConsumerState<FirebaseServiceDetailScreen> createState() =>
      _FirebaseServiceDetailScreenState();
}

class _FirebaseServiceDetailScreenState
    extends ConsumerState<FirebaseServiceDetailScreen> {
  bool _busy = false;

  static String _maskToken(String token) {
    if (token.length <= 16) return '••••••••';
    return '${token.substring(0, 8)}…${token.substring(token.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final async = ref.watch(firebaseHubSnapshotProvider);
    final status = async.valueOrNull?.statuses
        .where((s) => s.kind == kind)
        .firstOrNull;
    final steps = FirebaseSetupGuides.stepsFor(kind);
    final fcmToken = async.valueOrNull?.fcmToken;

    return ProfileHubScaffold(
      title: kind.titleVi.toUpperCase(),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: () => ref.invalidate(firebaseHubSnapshotProvider),
          icon: const Icon(Icons.refresh_rounded, color: kHomeCyan),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          HubCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status?.statusLabel ?? 'Đang tải…',
                  style: TextStyle(
                    color: (status?.ready ?? false) ? kHomeGreen : kHomeOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (status?.detail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    status!.detail!,
                    style: TextStyle(
                      color: const Color(0xFF5A7184),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  kind.subtitleVi,
                  style: TextStyle(
                    color: const Color(0xFF5A7184),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          HubCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HƯỚNG DẪN SETUP',
                  style: TextStyle(
                    color: kHomePrimaryDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < steps.length; i++) ...[
                  Text(
                    steps[i].title,
                    style: const TextStyle(
                      color: kHomeTextMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i].detail,
                    style: TextStyle(
                      color: const Color(0xFF5A7184),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (i != steps.length - 1) ...[
                    const SizedBox(height: 12),
                    Divider(color: kHomeBorderBlue.withValues(alpha: 0.35)),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
          if (kind == FirebaseServiceKind.cloudMessaging &&
              fcmToken != null &&
              fcmToken.isNotEmpty) ...[
            const SizedBox(height: 14),
            HubCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FCM TOKEN',
                    style: TextStyle(
                      color: kHomePrimaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDebugMode
                        ? fcmToken
                        : _maskToken(fcmToken),
                    style: TextStyle(
                      color: const Color(0xFF5A7184),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: fcmToken));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã copy FCM token (debug only)'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy token (debug)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: kHomeCyan,
                        foregroundColor: kHomeBg,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Token đã che ở bản release. Dùng debug build để copy đầy đủ.',
                      style: TextStyle(
                        color: const Color(0xFF5A7184),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (kind == FirebaseServiceKind.crashlytics) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await ref
                              .read(firebaseHubRepositoryProvider)
                              .sendTestCrashlyticsLog();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã gửi báo cáo thử nghiệm — kiểm tra Crashlytics Console sau vài phút',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                icon: const Icon(Icons.bug_report_rounded),
                label: Text(_busy ? 'Đang gửi…' : 'Gửi lỗi thử nghiệm'),
                style: FilledButton.styleFrom(
                  backgroundColor: kHomeCyan,
                  foregroundColor: kHomeBg,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              await launchUrl(
                Uri.parse(FirebaseSetupGuides.consoleUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Mở Firebase Console'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kHomeCyan,
              side: BorderSide(color: kHomeCyan.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
