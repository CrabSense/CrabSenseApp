import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/crab_condition.dart';
import '../../data/models/crab_model.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../widgets/crab_avatar.dart';

/// Chi tiết cua — dùng `/crabs/{id}/profile` (timeline vòng đời) + cân nặng.
class CrabDetailScreen extends StatefulWidget {
  const CrabDetailScreen({
    super.key,
    required this.crabId,
    this.boxId,
    this.boxCode,
    this.initial,
  });

  final String crabId;
  final String? boxId;
  final String? boxCode;
  final CrabModel? initial;

  @override
  State<CrabDetailScreen> createState() => _CrabDetailScreenState();
}

class _CrabDetailScreenState extends State<CrabDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profileCrab;
  Map<String, dynamic>? _location;
  Map<String, dynamic>? _lot;
  Map<String, dynamic>? _ai;
  List<_TimelineItem> _timeline = [];
  List<_WeightPt> _weights = [];
  List<_FeedItem> _feedings = [];
  List<_AlertItem> _alerts = [];
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = sl<ApiClient>();
    try {
      final profileRes =
          await api.get<dynamic>(ApiConstants.crabProfile(widget.crabId));
      final body = _unwrap(profileRes.data);
      if (body is Map) {
        _profileCrab = _asMap(body['crab'] ?? body['Crab']);
        _location = _asMap(body['location'] ?? body['Location']);
        _lot = _asMap(body['lot'] ?? body['Lot']);
        _ai = _asMap(body['ai'] ?? body['Ai']);
        _timeline = _parseTimeline(body['timeline'] ?? body['Timeline']);
        _alerts = _parseAlerts(body['alerts'] ?? body['Alerts']);
        _photos = _parseUrls(
          body['imageUrls'] ??
              body['ImageUrls'] ??
              _profileCrab?['imageUrls'] ??
              _profileCrab?['ImageUrls'],
        );
        final avatar = (_profileCrab?['avatarUrl'] ??
                _profileCrab?['AvatarUrl'])
            ?.toString();
        if (avatar != null &&
            avatar.isNotEmpty &&
            !_photos.contains(avatar)) {
          _photos = [avatar, ..._photos];
        }
      }

      try {
        final wRes =
            await api.get<dynamic>(ApiConstants.crabWeights(widget.crabId));
        _weights = _parseWeights(wRes.data);
      } catch (_) {}

      try {
        final fRes = await api.get<dynamic>(
          ApiConstants.operationsForCrab(widget.crabId),
        );
        _feedings = _parseFeedings(fRes.data);
      } catch (_) {}

      // Profile chưa gồm chuyển hộp — luôn ghép allocations.
      await _mergeBoxMoves(api);
    } catch (e) {
      _error = e.toString();
      try {
        await _mergeBoxMoves(api);
        if (_timeline.isNotEmpty) _error = null;
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _mergeBoxMoves(ApiClient api) async {
    try {
      final allocRes =
          await api.get<dynamic>(ApiConstants.crabAllocations(widget.crabId));
      final moves = _parseAlloc(allocRes.data);
      if (moves.isEmpty && _timeline.isNotEmpty) return;
      if (moves.isEmpty) {
        final moltRes =
            await api.get<dynamic>(ApiConstants.crabMoltings(widget.crabId));
        _timeline = [..._timeline, ..._parseMolt(moltRes.data)]
          ..sort((a, b) => b.at.compareTo(a.at));
        return;
      }
      _timeline = [..._timeline, ...moves]
        ..sort((a, b) => b.at.compareTo(a.at));
    } catch (_) {
      if (_timeline.isEmpty) {
        final moltRes =
            await api.get<dynamic>(ApiConstants.crabMoltings(widget.crabId));
        _timeline = _parseMolt(moltRes.data)
          ..sort((a, b) => b.at.compareTo(a.at));
      }
    }
  }

  static dynamic _unwrap(dynamic raw) {
    dynamic body = raw;
    try {
      body = jsonDecode(jsonEncode(raw));
    } catch (_) {}
    if (body is Map && body['data'] != null) return body['data'];
    return body;
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static List<String> _parseUrls(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item != null && item.toString().trim().isNotEmpty) item.toString(),
    ];
  }

  static List<_TimelineItem> _parseTimeline(dynamic raw) {
    if (raw is! List) return const [];
    final out = <_TimelineItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final at = DateTime.tryParse(
            (item['at'] ?? item['At'] ?? '').toString(),
          )?.toLocal() ??
          DateTime.now();
      out.add(
        _TimelineItem(
          at: at,
          kind: (item['kind'] ?? item['Kind'] ?? '').toString(),
          title: (item['title'] ?? item['Title'] ?? 'Sự kiện').toString(),
          detail: (item['detail'] ?? item['Detail'])?.toString(),
        ),
      );
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  static List<_AlertItem> _parseAlerts(dynamic raw) {
    if (raw is! List) return const [];
    final out = <_AlertItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      out.add(
        _AlertItem(
          title: (item['title'] ?? item['Title'] ?? 'Cảnh báo').toString(),
          detail: (item['detail'] ?? item['Detail'])?.toString(),
          severity: (item['severity'] ?? item['Severity'] ?? '').toString(),
        ),
      );
    }
    return out;
  }

  static List<_WeightPt> _parseWeights(dynamic raw) {
    final data = _unwrap(raw);
    if (data is! List) return const [];
    final out = <_WeightPt>[];
    for (final item in data) {
      if (item is! Map) continue;
      final g = item['weightGram'] ?? item['WeightGram'];
      final at = DateTime.tryParse(
        (item['measuredAt'] ?? item['MeasuredAt'] ?? '').toString(),
      )?.toLocal();
      if (g is num && at != null) {
        out.add(_WeightPt(at: at, grams: g.toDouble()));
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  /// Phiếu chăm sóc ghi theo cua — dùng cho mục "Lịch sử ăn".
  static List<_FeedItem> _parseFeedings(dynamic raw) {
    final data = _unwrap(raw);
    if (data is! List) return const [];
    final out = <_FeedItem>[];
    for (final item in data) {
      if (item is! Map) continue;
      final at = DateTime.tryParse(
        (item['timestamp'] ?? item['Timestamp'] ?? '').toString(),
      )?.toLocal();
      if (at == null) continue;
      final qty = item['quantity'] ?? item['Quantity'];
      out.add(
        _FeedItem(
          at: at,
          appetite: (item['appetite'] ?? item['Appetite'])?.toString(),
          condition: (item['condition'] ?? item['Condition'])?.toString(),
          foodType: (item['foodType'] ?? item['FoodType'])?.toString(),
          quantity: qty is num ? qty.toDouble() : null,
          unit: (item['unit'] ?? item['Unit'])?.toString(),
        ),
      );
    }
    out.sort((a, b) => b.at.compareTo(a.at)); // mới nhất trước
    return out;
  }

  static List<_TimelineItem> _parseAlloc(dynamic raw) {
    final data = _unwrap(raw);
    if (data is! List) return const [];
    final out = <_TimelineItem>[];
    for (final item in data) {
      if (item is! Map) continue;
      final start = DateTime.tryParse(
            (item['startTime'] ?? item['StartTime'] ?? '').toString(),
          )?.toLocal() ??
          DateTime.now();
      final end = item['endTime'] ?? item['EndTime'];
      final box = item['boxCode'] ?? item['boxId'] ?? item['BoxId'];
      out.add(
        _TimelineItem(
          at: start,
          kind: 'allocation',
          title: end == null ? 'Đang ở hộp' : 'Chuyển hộp',
          detail: 'Hộp ${box ?? '—'}',
        ),
      );
    }
    return out;
  }

  static List<_TimelineItem> _parseMolt(dynamic raw) {
    final data = _unwrap(raw);
    if (data is! List) return const [];
    final out = <_TimelineItem>[];
    for (final item in data) {
      if (item is! Map) continue;
      final at = DateTime.tryParse(
            (item['moltedAt'] ??
                    item['MoltedAt'] ??
                    item['moltTime'] ??
                    item['MoltTime'] ??
                    '')
                .toString(),
          )?.toLocal() ??
          DateTime.now();
      final stage = item['stage'] ??
          item['moltingStage'] ??
          item['result'] ??
          item['Result'];
      out.add(
        _TimelineItem(
          at: at,
          kind: 'molting',
          title: 'Lột xác',
          detail: stage?.toString(),
        ),
      );
    }
    return out;
  }

  String get _title {
    final tag = _profileCrab?['tag'] ??
        _profileCrab?['Tag'] ??
        _profileCrab?['code'] ??
        _profileCrab?['Code'];
    if (tag != null && tag.toString().trim().isNotEmpty) {
      return tag.toString();
    }
    if (widget.initial != null) return crabDisplayTag(widget.initial!);
    return 'Chi tiết cua';
  }

  @override
  Widget build(BuildContext context) {
    final crab = widget.initial;

    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        backgroundColor: kHomeSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kHomePrimaryDark,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            color: kHomePrimaryDark,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, color: kHomePrimaryDark),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kHomePrimary))
          : RefreshIndicator(
              color: kHomePrimary,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Một phần dữ liệu chưa tải: $_error',
                          style: const TextStyle(
                            color: kHomeWarning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_photos.isNotEmpty)
                      SizedBox(
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _photos[i],
                              width: 108,
                              height: 108,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 108,
                                height: 108,
                                color: kHomePrimaryBg,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: kHomeTextSub,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const Center(child: CrabAvatar(size: 88)),
                    const SizedBox(height: 16),
                    _infoCard(_buildInfoRows(crab)),
                    if (_lot != null) ...[
                      const SizedBox(height: 12),
                      _sectionTitle('Lô nhập'),
                      _simpleCard(
                        '${_lot!['lotCode'] ?? _lot!['LotCode'] ?? '—'}'
                        '${(_lot!['name'] ?? _lot!['Name']) != null ? ' · ${_lot!['name'] ?? _lot!['Name']}' : ''}',
                      ),
                    ],
                    if (_location != null) ...[
                      const SizedBox(height: 12),
                      _sectionTitle('Vị trí'),
                      _simpleCard(
                        [
                          _location!['areaName'] ?? _location!['AreaName'],
                          _location!['rowName'] ?? _location!['RowName'],
                          _location!['boxCode'] ??
                              _location!['BoxCode'] ??
                              widget.boxCode,
                        ].where((e) => e != null && e.toString().isNotEmpty).join(' › '),
                      ),
                    ],
                    if (_ai != null &&
                        [
                          _ai!['prediction'] ?? _ai!['Prediction'],
                          _ai!['recommendation'] ?? _ai!['Recommendation'],
                          _ai!['activityLevel'] ?? _ai!['ActivityLevel'],
                        ].any((e) => e != null && e.toString().isNotEmpty)) ...[
                      const SizedBox(height: 12),
                      _sectionTitle('AI'),
                      _simpleCard(
                        [
                          if ((_ai!['prediction'] ?? _ai!['Prediction']) != null)
                            'Dự đoán: ${_ai!['prediction'] ?? _ai!['Prediction']}',
                          if ((_ai!['recommendation'] ??
                                  _ai!['Recommendation']) !=
                              null)
                            '${_ai!['recommendation'] ?? _ai!['Recommendation']}',
                          if ((_ai!['activityLevel'] ??
                                  _ai!['ActivityLevel']) !=
                              null)
                            'Hoạt động: ${_ai!['activityLevel'] ?? _ai!['ActivityLevel']}',
                        ].join('\n'),
                      ),
                    ],
                    if (_weights.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionTitle('Cân nặng'),
                      const SizedBox(height: 8),
                      if (_weights.length >= 2)
                        Container(
                          height: 140,
                          padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
                          decoration: BoxDecoration(
                            color: kHomeSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kHomeBorder),
                          ),
                          child: _WeightChart(points: _weights),
                        )
                      else
                        _simpleCard(
                          '${_weights.first.grams.round()} g · ${DateFormat('dd/MM/yyyy HH:mm').format(_weights.first.at)}',
                        ),
                    ],
                    if (_feedings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionTitle('Lịch sử ăn'),
                      const SizedBox(height: 8),
                      _AppetiteChart(feedings: _feedings),
                      const SizedBox(height: 8),
                      ..._feedings.take(20).map(_feedingTile),
                    ],
                    if (_alerts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionTitle('Cảnh báo'),
                      ..._alerts.map(
                        (a) => _simpleCard(
                          a.detail == null || a.detail!.isEmpty
                              ? a.title
                              : '${a.title} — ${a.detail}',
                          danger: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _sectionTitle('Nhật ký vòng đời'),
                    const SizedBox(height: 8),
                    if (_timeline.isEmpty)
                      _simpleCard('Chưa có sự kiện lịch sử')
                    else
                      ..._timeline.map(_timelineTile),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildInfoRows(CrabModel? crab) {
    final p = _profileCrab;
    String pick(String a, String b, [String? fallback]) {
      final v = p?[a] ?? p?[b];
      if (v != null && v.toString().isNotEmpty) return v.toString();
      return fallback ?? '—';
    }

    if (p != null) {
      final w = p['weightGram'] ?? p['WeightGram'];
      return [
        _row('Mã / tag', pick('tag', 'Tag', pick('code', 'Code'))),
        _row('Cân nặng', w is num ? '${w.round()} g' : '—'),
        _row('Giới tính', pick('gender', 'Gender')),
        _row('Loại', pick('crabType', 'CrabType')),
        _row('Vỏ / lột', pick('moltingStage', 'MoltingStage')),
        _row('Tình trạng', pick('condition', 'Condition', pick('status', 'Status'))),
        _row('Sống', (p['isAlive'] ?? p['IsAlive']) == false ? 'Không' : 'Có'),
      ];
    }
    if (crab == null) {
      return [const Text('Không có dữ liệu', style: TextStyle(color: kHomeTextSub))];
    }
    return [
      _row('Mã cua', crabDisplayTag(crab)),
      _row('Cân nặng', '${crab.weight.round()} g'),
      _row('Loài', crabSpeciesVi(crab.species)),
      // Tình trạng lấy từ trường `Condition` của BE rồi quy về 5 nhãn của
      // [BoxStatus] — cùng bảng với thẻ hộp. Trước đây in `moltingStatus` /
      // `healthStatus`, mà BE không trả hai trường đó nên lúc nào cũng ra
      // "Vỏ cứng" / "Chưa rõ".
      _row(
        'Tình trạng',
        displayStatusOf(CrabCondition.tryParse(crab.condition)).label,
      ),
      _row(
        'Hộp nuôi',
        (widget.boxCode != null && widget.boxCode!.isNotEmpty)
            ? widget.boxCode!
            : 'Hộp',
      ),
    ];
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: kHomePrimaryDark,
        ),
      );

  Widget _simpleCard(String text, {bool danger = false}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: danger ? const Color(0x14E53935) : kHomeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: danger ? kHomeDanger : kHomeBorder),
        ),
        child: Text(
          text.isEmpty ? '—' : text,
          style: TextStyle(
            color: danger ? kHomeDanger : kHomeTextMain,
            fontSize: 13,
          ),
        ),
      );

  Widget _timelineTile(_TimelineItem item) {
    final time = DateFormat('dd/MM/yyyy HH:mm').format(item.at);
    final icon = switch (item.kind.toLowerCase()) {
      'allocation' || 'move' || 'transfer' => Icons.swap_horiz_rounded,
      'molting' || 'molt' => Icons.autorenew_rounded,
      'weight' => Icons.monitor_weight_outlined,
      'status' => Icons.flag_rounded,
      'harvest' => Icons.inventory_2_outlined,
      'feed' || 'feeding' || 'operation' => Icons.restaurant_rounded,
      _ => Icons.history_rounded,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kHomeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHomeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kHomePrimaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: kHomePrimaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kHomeTextMain,
                    fontSize: 13,
                  ),
                ),
                if (item.detail != null && item.detail!.isNotEmpty)
                  Text(
                    item.detail!,
                    style: const TextStyle(fontSize: 12, color: kHomeTextSub),
                  ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: kHomeTextHint),
          ),
        ],
      ),
    );
  }

  Widget _feedingTile(_FeedItem f) {
    final time = DateFormat('dd/MM HH:mm').format(f.at);
    final bits = [
      if (f.foodType != null && f.foodType!.trim().isNotEmpty) f.foodType!.trim(),
      if (f.quantity != null)
        '${f.quantity!.toStringAsFixed(f.quantity! % 1 == 0 ? 0 : 1)}'
            '${f.unit ?? 'g'}',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kHomeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHomeBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _appetiteColor(f.appetite),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _appetiteLabel(f.appetite),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: _appetiteColor(f.appetite),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _chip(
                      _conditionLabel(f.condition),
                      _conditionColor(f.condition),
                    ),
                  ],
                ),
                if (bits.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      bits.join(' · '),
                      style: const TextStyle(fontSize: 12, color: kHomeTextSub),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: kHomeTextHint),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );

  Widget _infoCard(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: kHomeSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kHomeBorder),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(children: rows),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(color: kHomeTextSub, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: kHomeTextMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
}

class _TimelineItem {
  const _TimelineItem({
    required this.at,
    required this.kind,
    required this.title,
    this.detail,
  });
  final DateTime at;
  final String kind;
  final String title;
  final String? detail;
}

class _WeightPt {
  const _WeightPt({required this.at, required this.grams});
  final DateTime at;
  final double grams;
}

/// Một phiếu chăm sóc/cho ăn của con cua.
class _FeedItem {
  const _FeedItem({
    required this.at,
    this.appetite,
    this.condition,
    this.foodType,
    this.quantity,
    this.unit,
  });
  final DateTime at;
  final String? appetite;
  final String? condition;
  final String? foodType;
  final double? quantity;
  final String? unit;
}

String _appetiteLabel(String? v) => switch ((v ?? '').toLowerCase()) {
      'many' => 'Ăn nhiều',
      'little' => 'Ăn ít',
      'none' => 'Không ăn',
      _ => 'Chưa ghi',
    };

Color _appetiteColor(String? v) => switch ((v ?? '').toLowerCase()) {
      'many' => const Color(0xFF2E7D32),
      'little' => const Color(0xFFF9A825),
      'none' => kHomeDanger,
      _ => kHomeTextSub,
    };

String _conditionLabel(String? v) {
  final condition = CrabCondition.tryParse(v);
  return condition == null ? '—' : condition.displayStatus.label;
}

/// Nhãn + màu lấy từ [BoxStatus] — cùng bảng với thẻ hộp và app desktop.
Color _conditionColor(String? v) {
  final condition = CrabCondition.tryParse(v);
  // Chưa ghi gì, hoặc cua đã kết thúc (chết / bán / thu hoạch) ⇒ xám.
  if (condition == null || condition == CrabCondition.empty) {
    return kHomeTextSub;
  }
  return condition.displayStatus.color;
}

/// Điểm mức ăn để vẽ trục tung: 0 = không ăn, 1 = ít, 2 = nhiều.
double _appetiteScore(String? v) => switch ((v ?? '').toLowerCase()) {
      'many' => 2,
      'little' => 1,
      _ => 0,
    };

Widget _appetiteAxisLabel(double value, TitleMeta meta) {
  final text = switch (value.round()) {
    0 => 'Không',
    1 => 'Ít',
    2 => 'Nhiều',
    _ => '',
  };
  if (text.isEmpty) return const SizedBox.shrink();
  return Text(
    text,
    style: const TextStyle(fontSize: 9, color: kHomeTextSub),
  );
}

/// Cột mức ăn theo ngày — nhìn nhanh con cua ăn tăng hay giảm dần.
class _AppetiteChart extends StatelessWidget {
  const _AppetiteChart({required this.feedings});
  final List<_FeedItem> feedings;

  static const int _maxBars = 14;

  @override
  Widget build(BuildContext context) {
    // feedings: mới nhất trước → đảo lại để trục thời gian tăng dần.
    final recent = feedings.take(_maxBars).toList().reversed.toList();
    return Container(
      height: 138,
      padding: const EdgeInsets.fromLTRB(6, 12, 12, 6),
      decoration: BoxDecoration(
        color: kHomeSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kHomeBorder),
      ),
      child: BarChart(
        BarChartData(
          maxY: 2.4,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: kHomeBorder.withValues(alpha: 0.6),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: _appetiteAxisLabel,
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < recent.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: _appetiteScore(recent[i].appetite),
                    width: 10,
                    borderRadius: BorderRadius.circular(3),
                    color: _appetiteColor(recent[i].appetite),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem {
  const _AlertItem({
    required this.title,
    this.detail,
    required this.severity,
  });
  final String title;
  final String? detail;
  final String severity;
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.points});
  final List<_WeightPt> points;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].grams),
    ];
    final minY = points.map((p) => p.grams).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.grams).reduce((a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: (minY * 0.9).clamp(0, double.infinity),
        maxY: maxY * 1.1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: kHomeBorder.withValues(alpha: 0.7),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: kHomePrimaryDark,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: kHomePrimary.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}
