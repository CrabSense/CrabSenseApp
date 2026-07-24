// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/operation_log.dart';
import '../../domain/usecases/get_all_operation_logs_usecase.dart';
import '../widgets/operation_timeline.dart';

/// Màn hình "Lịch sử vận hành" — hiển thị toàn bộ nhật ký vận hành
/// đã ghi nhận trên thiết bị (offline-first) theo dòng thời gian,
/// có tìm kiếm và bộ lọc theo loại / hộp / khoảng ngày.
///
/// Phong cách hologram đồng bộ với trang home.
class OperationHistoryScreen extends StatefulWidget {
  const OperationHistoryScreen({super.key});

  @override
  State<OperationHistoryScreen> createState() => _OperationHistoryScreenState();
}

class _OperationHistoryScreenState extends State<OperationHistoryScreen> {
  static const _pageSize = 50;

  final GetAllOperationLogsUseCase _getLogs = sl<GetAllOperationLogsUseCase>();

  final List<OperationLog> _logs = [];
  OperationTimelineFilter _filter = const OperationTimelineFilter();

  bool _isLoading = true;
  bool _hasMore = false;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({required bool refresh}) async {
    final targetPage = refresh ? 1 : _page + 1;
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final result = await _getLogs(
      GetAllOperationLogsParams(page: targetPage, pageSize: _pageSize),
    );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        if (refresh) _error = failure.message;
      }),
      (logs) => setState(() {
        _isLoading = false;
        _error = null;
        if (refresh) _logs.clear();
        _logs.addAll(logs);
        _page = targetPage;
        _hasMore = logs.length == _pageSize;
      }),
    );
  }

  // ── Lọc trong bộ nhớ ──────────────────────────────────────────────────────

  List<OperationLog> get _filteredLogs => _logs.where((log) {
        final f = _filter;
        if (f.operationType != null && log.type != f.operationType) {
          return false;
        }
        if (f.boxId != null && !log.boxIds.contains(f.boxId)) {
          return false;
        }
        if (f.dateRange != null) {
          final r = f.dateRange!;
          final start = DateTime(r.start.year, r.start.month, r.start.day);
          final endExclusive = DateTime(r.end.year, r.end.month, r.end.day)
              .add(const Duration(days: 1));
          if (log.timestamp.isBefore(start) ||
              !log.timestamp.isBefore(endExclusive)) {
            return false;
          }
        }
        if (f.searchQuery.isNotEmpty &&
            !log.notes.toLowerCase().contains(f.searchQuery.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

  List<String> get _availableBoxIds {
    final ids = <String>{for (final log in _logs) ...log.boxIds};
    final sorted = ids.toList()..sort();
    return sorted;
  }

  Future<void> _openCreateLog() async {
    await context.push(RoutePaths.operations);
    if (mounted) await _load(refresh: true);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
            ),
            border: Border(
              bottom: BorderSide(
                color: kHomeBorderBlue.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 18,
              color: kHomeBlueLight,
              shadows: [
                Shadow(
                  color: kHomeBlueLight.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Text(
              'LỊCH SỬ VẬN HÀNH',
              style: TextStyle(
                color: kHomeBlueLight,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kHomeBlue.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openCreateLog,
          backgroundColor: kHomeBlue,
          foregroundColor: Colors.white,
          tooltip: 'Thêm nhật ký',
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      body: Stack(
        children: [
          // Họa tiết lưới khay nuôi + cua (đồng bộ trang home)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.05),
                  trayExtent: 30,
                ),
              ),
            ),
          ),
          if (_error != null)
            _ErrorBody(message: _error!, onRetry: () => _load(refresh: true))
          else
            RefreshIndicator(
              color: kHomeBlue,
              backgroundColor: kHomeNavy,
              onRefresh: () => _load(refresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: OperationTimeline(
                  logs: filtered,
                  totalCount: filtered.length,
                  availableBoxIds: _availableBoxIds,
                  isLoading: _isLoading,
                  hasMoreItems: _hasMore,
                  onLoadMore: () => _load(refresh: false),
                  onFilterChanged: (filter) => setState(() => _filter = filter),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Trạng thái lỗi ────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tải được lịch sử',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kHomeBlueLight,
                  side: BorderSide(
                    color: kHomeBorderBlue.withValues(alpha: 0.6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
}
