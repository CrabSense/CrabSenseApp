import '../../../core/network/api_client.dart';
import 'models/report_models.dart';

abstract class ReportsRepository {
  Future<ReportDetailData> getReport(ReportKind kind);
}

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<ReportDetailData> getReport(ReportKind kind) async {
    final res = await _api.get(kind.apiPath);
    if (res.statusCode != 200 || res.data == null) {
      throw Exception('Không tải được ${kind.titleVi}');
    }
    final map = _asMap(res.data);
    return switch (kind) {
      ReportKind.harvest => _parseHarvest(map),
      ReportKind.inventory => _parseInventory(map),
      ReportKind.molting => _parseMolting(map),
      ReportKind.survival => _parseSurvival(map),
      ReportKind.efficiency => _parseEfficiency(map),
    };
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      if (m['data'] is Map) {
        return Map<String, dynamic>.from(m['data'] as Map);
      }
      return m;
    }
    return <String, dynamic>{};
  }

  String _n(dynamic v, [String suffix = '']) {
    if (v == null) return '—';
    if (v is num) {
      final s = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      return '$s$suffix';
    }
    return '$v$suffix';
  }

  ReportDetailData _parseHarvest(Map<String, dynamic> m) {
    final byGrade = <ReportMetric>[];
    final grades = m['byGrade'] ?? m['ByGrade'];
    if (grades is List) {
      for (final g in grades.whereType<Map>()) {
        final row = Map<String, dynamic>.from(g);
        byGrade.add(
          ReportMetric(
            label: '${row['grade'] ?? row['Grade'] ?? '?'}',
            value: _n(row['weightKg'] ?? row['WeightKg'], ' kg'),
          ),
        );
      }
    }
    final byDate = <ReportMetric>[];
    final dates = m['byDate'] ?? m['ByDate'];
    if (dates is List) {
      for (final d in dates.whereType<Map>().take(8)) {
        final row = Map<String, dynamic>.from(d);
        final date = row['date'] ?? row['Date'] ?? '';
        byDate.add(
          ReportMetric(
            label: '$date'.split('T').first,
            value:
                '${_n(row['quantity'] ?? row['Quantity'])} con · ${_n(row['weightKg'] ?? row['WeightKg'], ' kg')}',
          ),
        );
      }
    }
    final soft = m['softshell'] ?? m['Softshell'];
    final softKg = soft is Map
        ? (soft['weightKg'] ?? soft['WeightKg'])
        : null;

    return ReportDetailData(
      kind: ReportKind.harvest,
      metrics: [
        ReportMetric(
          label: 'Tổng phiếu',
          value: _n(m['totalVouchers'] ?? m['TotalVouchers']),
        ),
        ReportMetric(
          label: 'Tổng số lượng',
          value: _n(m['totalQuantity'] ?? m['TotalQuantity']),
        ),
        ReportMetric(
          label: 'Tổng khối lượng',
          value: _n(m['totalWeightKg'] ?? m['TotalWeightKg'], ' kg'),
        ),
        if (softKg != null)
          ReportMetric(label: 'Cua mềm', value: _n(softKg, ' kg')),
      ],
      sections: [
        if (byGrade.isNotEmpty)
          ReportSection(title: 'Theo grade', rows: byGrade),
        if (byDate.isNotEmpty) ReportSection(title: 'Theo ngày', rows: byDate),
      ],
      raw: m,
    );
  }

  ReportDetailData _parseInventory(Map<String, dynamic> m) {
    final byGrade = <ReportMetric>[];
    final grades = m['byGrade'] ?? m['ByGrade'];
    if (grades is List) {
      for (final g in grades.whereType<Map>()) {
        final row = Map<String, dynamic>.from(g);
        byGrade.add(
          ReportMetric(
            label: '${row['grade'] ?? row['Grade'] ?? '?'}',
            value:
                '${_n(row['quantity'] ?? row['Quantity'])} · ${_n(row['weightKg'] ?? row['WeightKg'], ' kg')} · ${_n(row['lotCount'] ?? row['LotCount'])} lô',
          ),
        );
      }
    }
    return ReportDetailData(
      kind: ReportKind.inventory,
      metrics: [
        ReportMetric(
          label: 'Tổng lô',
          value: _n(m['totalInventoryLots'] ?? m['TotalInventoryLots']),
        ),
        ReportMetric(
          label: 'Khối lượng',
          value: _n(
            m['totalInventoryWeightKg'] ?? m['TotalInventoryWeightKg'],
            ' kg',
          ),
        ),
        ReportMetric(
          label: 'Số lượng',
          value: _n(m['totalInventoryQuantity'] ?? m['TotalInventoryQuantity']),
        ),
        ReportMetric(
          label: 'Available',
          value: _n(m['availableLots'] ?? m['AvailableLots']),
        ),
        ReportMetric(
          label: 'Reserved',
          value: _n(m['reservedLots'] ?? m['ReservedLots']),
        ),
        ReportMetric(
          label: 'Shipped',
          value: _n(m['shippedLots'] ?? m['ShippedLots']),
        ),
      ],
      sections: [
        if (byGrade.isNotEmpty)
          ReportSection(title: 'Theo grade', rows: byGrade),
      ],
      raw: m,
    );
  }

  ReportDetailData _parseMolting(Map<String, dynamic> m) {
    final areas = <ReportMetric>[];
    final list = m['byAreas'] ?? m['ByAreas'];
    if (list is List) {
      for (final a in list.whereType<Map>()) {
        final row = Map<String, dynamic>.from(a);
        areas.add(
          ReportMetric(
            label: '${row['areaName'] ?? row['AreaName'] ?? 'Khu'}',
            value:
                '${_n(row['moltingRate'] ?? row['MoltingRate'], '%')} · lột ${_n(row['moltedCrabs'] ?? row['MoltedCrabs'])}/${_n(row['totalCrabs'] ?? row['TotalCrabs'])}',
          ),
        );
      }
    }
    return ReportDetailData(
      kind: ReportKind.molting,
      metrics: [
        ReportMetric(
          label: 'Tổng cua',
          value: _n(m['totalCrabs'] ?? m['TotalCrabs']),
        ),
        ReportMetric(
          label: 'Đang lột',
          value: _n(m['moltingCrabs'] ?? m['MoltingCrabs']),
        ),
        ReportMetric(
          label: 'Đã lột',
          value: _n(m['moltedCrabs'] ?? m['MoltedCrabs']),
        ),
        ReportMetric(
          label: 'Tỷ lệ lột',
          value: _n(m['moltingRate'] ?? m['MoltingRate'], '%'),
        ),
      ],
      sections: [
        if (areas.isNotEmpty) ReportSection(title: 'Theo khu vực', rows: areas),
      ],
      raw: m,
    );
  }

  ReportDetailData _parseSurvival(Map<String, dynamic> m) {
    final areas = <ReportMetric>[];
    final list = m['byAreas'] ?? m['ByAreas'];
    if (list is List) {
      for (final a in list.whereType<Map>()) {
        final row = Map<String, dynamic>.from(a);
        areas.add(
          ReportMetric(
            label: '${row['areaName'] ?? row['AreaName'] ?? 'Khu'}',
            value:
                'Sống ${_n(row['survivalRate'] ?? row['SurvivalRate'], '%')} · Chết ${_n(row['mortalityRate'] ?? row['MortalityRate'], '%')}',
            hint:
                'Sống ${_n(row['aliveCrabs'] ?? row['AliveCrabs'])} / ${_n(row['totalCrabs'] ?? row['TotalCrabs'])}',
          ),
        );
      }
    }
    return ReportDetailData(
      kind: ReportKind.survival,
      metrics: [
        ReportMetric(
          label: 'Tổng cua',
          value: _n(m['totalCrabs'] ?? m['TotalCrabs']),
        ),
        ReportMetric(
          label: 'Còn sống',
          value: _n(m['aliveCrabs'] ?? m['AliveCrabs']),
        ),
        ReportMetric(
          label: 'Đã chết',
          value: _n(m['deadCrabs'] ?? m['DeadCrabs']),
        ),
        ReportMetric(
          label: 'Đã thu hoạch',
          value: _n(m['harvestedCrabs'] ?? m['HarvestedCrabs']),
        ),
        ReportMetric(
          label: 'Tỷ lệ sống',
          value: _n(m['survivalRate'] ?? m['SurvivalRate'], '%'),
        ),
        ReportMetric(
          label: 'Tỷ lệ hao hụt',
          value: _n(m['mortalityRate'] ?? m['MortalityRate'], '%'),
        ),
      ],
      sections: [
        if (areas.isNotEmpty) ReportSection(title: 'Theo khu vực', rows: areas),
      ],
      raw: m,
    );
  }

  ReportDetailData _parseEfficiency(Map<String, dynamic> m) {
    return ReportDetailData(
      kind: ReportKind.efficiency,
      metrics: [
        ReportMetric(
          label: 'Tổng thả',
          value: _n(m['totalCrabs'] ?? m['TotalCrabs']),
        ),
        ReportMetric(
          label: 'Đã lột',
          value: _n(m['moltedCrabs'] ?? m['MoltedCrabs']),
        ),
        ReportMetric(
          label: 'Thu hoạch',
          value: _n(m['harvestedCrabs'] ?? m['HarvestedCrabs']),
        ),
        ReportMetric(
          label: 'Còn nuôi',
          value: _n(m['aliveCrabs'] ?? m['AliveCrabs']),
        ),
        ReportMetric(
          label: 'Chết',
          value: _n(m['deadCrabs'] ?? m['DeadCrabs']),
        ),
        ReportMetric(
          label: 'Molting rate',
          value: _n(m['moltingRate'] ?? m['MoltingRate'], '%'),
        ),
        ReportMetric(
          label: 'Harvest rate',
          value: _n(m['harvestRate'] ?? m['HarvestRate'], '%'),
        ),
        ReportMetric(
          label: 'Mortality',
          value: _n(m['mortalityRate'] ?? m['MortalityRate'], '%'),
        ),
      ],
      raw: m,
    );
  }
}
