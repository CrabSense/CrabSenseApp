class AreaSummaryStats {
  const AreaSummaryStats({
    required this.total,
    required this.active,
    required this.maintenance,
    required this.disabled,
    required this.totalBoxes,
  });

  final int total;
  final int active;
  final int maintenance;
  final int disabled;
  final int totalBoxes;

  factory AreaSummaryStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AreaSummaryStats(
        total: 0,
        active: 0,
        maintenance: 0,
        disabled: 0,
        totalBoxes: 0,
      );
    }
    return AreaSummaryStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      maintenance: (json['maintenance'] as num?)?.toInt() ?? 0,
      disabled: (json['disabled'] as num?)?.toInt() ?? 0,
      totalBoxes: (json['totalBoxes'] as num?)?.toInt() ?? 0,
    );
  }
}

class AreaRecord {
  const AreaRecord({
    required this.id,
    required this.farmId,
    required this.areaCode,
    required this.areaName,
    this.description,
    this.status = 'active',
    this.createdAt,
    this.rowCount = 0,
    this.boxCount = 0,
    this.esp32Count = 0,
    this.cameraCount = 0,
  });

  final String id;
  final String farmId;
  final String areaCode;
  final String areaName;
  final String? description;
  final String status;
  final DateTime? createdAt;
  final int rowCount;
  final int boxCount;
  final int esp32Count;
  final int cameraCount;

  String get subtitle =>
      description?.trim().isNotEmpty == true ? description!.trim() : areaCode;

  factory AreaRecord.fromJson(Map<String, dynamic> json) {
    final name =
        (json['areaName'] ?? json['AreaName'] ?? json['name'] ?? json['Name'] ?? '')
            .toString();
    final inactive = json['isActive'] == false || json['IsActive'] == false;
    return AreaRecord(
        id: (json['id'] ?? json['Id']).toString(),
        farmId: (json['farmId'] ??
                json['FarmId'] ??
                json['ownerId'] ??
                json['OwnerId'] ??
                json['farmingAreaId'] ??
                json['FarmingAreaId'] ??
                '')
            .toString(),
        areaCode: (json['areaCode'] ?? json['AreaCode'] ?? name).toString(),
        areaName: name,
        description: (json['description'] ?? json['Description'])?.toString(),
        status: inactive
            ? 'disabled'
            : (json['status'] ?? json['Status'] ?? 'active').toString(),
        createdAt: _parseAreaDate(json['createdAt'] ?? json['CreatedAt']),
        rowCount:
            ((json['rowCount'] ?? json['RowCount']) as num?)?.toInt() ?? 0,
        boxCount:
            ((json['boxCount'] ?? json['BoxCount']) as num?)?.toInt() ?? 0,
        esp32Count:
            ((json['esp32Count'] ?? json['Esp32Count']) as num?)?.toInt() ?? 0,
        cameraCount:
            ((json['cameraCount'] ?? json['CameraCount']) as num?)?.toInt() ??
                0,
      );
  }

  static DateTime? _parseAreaDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  AreaRecord copyWith({
    int? rowCount,
    int? boxCount,
    int? esp32Count,
    int? cameraCount,
  }) =>
      AreaRecord(
        id: id,
        farmId: farmId,
        areaCode: areaCode,
        areaName: areaName,
        description: description,
        status: status,
        createdAt: createdAt,
        rowCount: rowCount ?? this.rowCount,
        boxCount: boxCount ?? this.boxCount,
        esp32Count: esp32Count ?? this.esp32Count,
        cameraCount: cameraCount ?? this.cameraCount,
      );
}

class RowRecord {
  const RowRecord({
    required this.id,
    required this.areaId,
    required this.rowCode,
    required this.rowName,
  });

  final String id;
  final String areaId;
  final String rowCode;
  final String rowName;

  factory RowRecord.fromJson(Map<String, dynamic> json) {
    final name =
        (json['rowName'] ?? json['RowName'] ?? json['name'] ?? json['Name'] ?? '')
            .toString();
    return RowRecord(
      id: (json['id'] ?? json['Id']).toString(),
      areaId: (json['areaId'] ??
              json['AreaId'] ??
              json['farmingAreaId'] ??
              json['FarmingAreaId'] ??
              '')
          .toString(),
      rowCode: (json['rowCode'] ?? json['RowCode'] ?? name).toString(),
      rowName: name,
    );
  }
}

class BoxRecord {
  const BoxRecord({
    required this.id,
    required this.rowId,
    required this.boxCode,
    this.position,
    this.volume,
    required this.status,
  });

  final String id;
  final String rowId;
  final String boxCode;
  final String? position;
  final double? volume;
  final String status;

  factory BoxRecord.fromJson(Map<String, dynamic> json) {
    final occupied = json['isOccupied'] == true || json['IsOccupied'] == true;
    final code =
        (json['boxCode'] ?? json['BoxCode'] ?? json['code'] ?? json['Code'] ?? '')
            .toString();
    return BoxRecord(
      id: (json['id'] ?? json['Id']).toString(),
      rowId: (json['rowId'] ??
              json['RowId'] ??
              json['farmingRowId'] ??
              json['FarmingRowId'] ??
              '')
          .toString(),
      boxCode: code,
      position: (json['position'] ?? json['Position'])?.toString(),
      volume: (json['volume'] ?? json['Volume']) is num
          ? (json['volume'] ?? json['Volume']).toDouble()
          : null,
      status: (json['status'] ?? json['Status'] ?? (occupied ? 'occupied' : 'empty'))
          .toString(),
    );
  }
}

class FarmingBatchRecord {
  const FarmingBatchRecord({
    required this.id,
    required this.boxId,
    required this.batchCode,
    required this.startDate,
    this.expectedHarvestDate,
    this.actualHarvestDate,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.status,
    this.boxCode,
  });

  final String id;
  final String boxId;
  final String batchCode;
  final String? boxCode;
  final DateTime startDate;
  final DateTime? expectedHarvestDate;
  final DateTime? actualHarvestDate;
  final int initialQuantity;
  final int currentQuantity;
  final String status;

  /// Nhãn dropdown: BT-3 — H-5 (mã đợt có thể trùng giữa các hộp).
  String get displayLabel {
    final box = boxCode?.trim();
    if (box != null && box.isNotEmpty) return '$batchCode — $box';
    return batchCode;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.length >= 10) return DateTime.tryParse(s.substring(0, 10));
    return DateTime.tryParse(s);
  }

  factory FarmingBatchRecord.fromJson(Map<String, dynamic> json) {
    final qty = ((json['quantity'] ??
                json['Quantity'] ??
                json['initialQuantity'] ??
                json['InitialQuantity']) as num?)
            ?.toInt() ??
        0;
    return FarmingBatchRecord(
      id: (json['id'] ?? json['Id']).toString(),
      boxId: (json['boxId'] ?? json['BoxId'] ?? '').toString(),
      boxCode: (json['boxCode'] ?? json['BoxCode'])?.toString(),
      batchCode: (json['lotCode'] ??
              json['LotCode'] ??
              json['batchCode'] ??
              json['BatchCode'] ??
              '')
          .toString(),
      startDate: _parseDate(
            json['importDate'] ??
                json['ImportDate'] ??
                json['startDate'] ??
                json['StartDate'],
          ) ??
          DateTime.now(),
      expectedHarvestDate:
          _parseDate(json['expectedHarvestDate'] ?? json['ExpectedHarvestDate']),
      actualHarvestDate:
          _parseDate(json['actualHarvestDate'] ?? json['ActualHarvestDate']),
      initialQuantity: qty,
      currentQuantity: ((json['currentQuantity'] ??
                  json['CurrentQuantity'] ??
                  json['quantity'] ??
                  json['Quantity']) as num?)
              ?.toInt() ??
          qty,
      status: (json['status'] ?? json['Status'] ?? 'active').toString(),
    );
  }
}

class BatchCrabRecord {
  const BatchCrabRecord({
    required this.id,
    required this.batchId,
    required this.crabCode,
    required this.gender,
    this.weight,
    this.shellWidth,
    required this.status,
  });

  final String id;
  final String batchId;
  final String crabCode;
  final String gender;
  final double? weight;
  final double? shellWidth;
  final String status;

  factory BatchCrabRecord.fromJson(Map<String, dynamic> json) {
    final alive = json['isAlive'] ?? json['IsAlive'];
    final status = alive is bool
        ? (alive ? 'alive' : 'dead')
        : (json['status'] ?? json['Status'] ?? 'alive').toString();
    final weightRaw = json['weightGram'] ?? json['WeightGram'] ?? json['weight'] ?? json['Weight'];
    return BatchCrabRecord(
      id: (json['id'] ?? json['Id']).toString(),
      batchId: (json['crabLotId'] ??
              json['CrabLotId'] ??
              json['batchId'] ??
              json['BatchId'] ??
              '')
          .toString(),
      crabCode: (json['tag'] ?? json['Tag'] ?? json['crabCode'] ?? json['CrabCode'] ?? '')
          .toString(),
      gender: (json['gender'] ?? json['Gender'] ?? 'unknown').toString(),
      weight: weightRaw is num ? weightRaw.toDouble() : null,
      shellWidth: (json['shellWidth'] ?? json['ShellWidth']) is num
          ? (json['shellWidth'] ?? json['ShellWidth']).toDouble()
          : null,
      status: status,
    );
  }
}

class CrabManagementSummaryDto {
  const CrabManagementSummaryDto({
    required this.total,
    required this.alive,
    required this.dead,
    required this.molting,
    required this.readyHarvest,
  });

  final int total;
  final int alive;
  final int dead;
  final int molting;
  final int readyHarvest;

  factory CrabManagementSummaryDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CrabManagementSummaryDto(
        total: 0,
        alive: 0,
        dead: 0,
        molting: 0,
        readyHarvest: 0,
      );
    }
    return CrabManagementSummaryDto(
      total: (json['total'] as num? ?? json['Total'] as num?)?.toInt() ?? 0,
      alive: (json['alive'] as num? ?? json['Alive'] as num?)?.toInt() ?? 0,
      dead: (json['dead'] as num? ?? json['Dead'] as num?)?.toInt() ?? 0,
      molting: (json['molting'] as num? ?? json['Molting'] as num?)?.toInt() ?? 0,
      readyHarvest:
          (json['readyHarvest'] as num? ?? json['ReadyHarvest'] as num?)?.toInt() ?? 0,
    );
  }
}

class CrabManagementListItem {
  const CrabManagementListItem({
    required this.id,
    required this.batchId,
    required this.batchCode,
    required this.boxId,
    required this.boxCode,
    required this.rowId,
    required this.rowCode,
    required this.rowName,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.crabCode,
    required this.gender,
    this.weight,
    this.shellWidth,
    required this.status,
    required this.moltCount,
    this.lastMoltDate,
    this.healthStatus,
    this.growthStage,
    this.profileNote,
    required this.batchStartDate,
  });

  final String id;
  final String batchId;
  final String batchCode;
  final String boxId;
  final String boxCode;
  final String rowId;
  final String rowCode;
  final String rowName;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String crabCode;
  final String gender;
  final double? weight;
  final double? shellWidth;
  final String status;
  final int moltCount;
  final String? lastMoltDate;
  final String? healthStatus;
  final String? growthStage;
  final String? profileNote;
  final String batchStartDate;

  factory CrabManagementListItem.fromJson(Map<String, dynamic> json) {
    final alive = json['isAlive'] ?? json['IsAlive'];
    final molting = (json['moltingStage'] ?? json['MoltingStage'] ?? '').toString();
    final status = alive is bool
        ? (alive ? (molting.toLowerCase().contains('molt') ? 'molting' : 'alive') : 'dead')
        : (json['status'] ?? json['Status'] ?? 'alive').toString();
    final weightRaw =
        json['weightGram'] ?? json['WeightGram'] ?? json['weight'] ?? json['Weight'];
    final lotId = (json['crabLotId'] ??
            json['CrabLotId'] ??
            json['batchId'] ??
            json['BatchId'] ??
            '')
        .toString();
    return CrabManagementListItem(
      id: (json['id'] ?? json['Id']).toString(),
      batchId: lotId,
      batchCode: (json['lotCode'] ??
              json['LotCode'] ??
              json['batchCode'] ??
              json['BatchCode'] ??
              lotId)
          .toString(),
      boxId: (json['boxId'] ?? json['BoxId'] ?? '').toString(),
      boxCode: (json['boxCode'] ?? json['BoxCode'] ?? '').toString(),
      rowId: (json['farmingRowId'] ??
              json['FarmingRowId'] ??
              json['rowId'] ??
              json['RowId'] ??
              '')
          .toString(),
      rowCode: (json['rowCode'] ?? json['RowCode'] ?? '').toString(),
      rowName: (json['rowName'] ?? json['RowName'] ?? '').toString(),
      areaId: (json['farmingAreaId'] ??
              json['FarmingAreaId'] ??
              json['areaId'] ??
              json['AreaId'] ??
              '')
          .toString(),
      areaCode: (json['areaCode'] ?? json['AreaCode'] ?? '').toString(),
      areaName: (json['areaName'] ?? json['AreaName'] ?? '').toString(),
      crabCode: (json['tag'] ??
              json['Tag'] ??
              json['crabCode'] ??
              json['CrabCode'] ??
              '')
          .toString(),
      gender: (json['gender'] ?? json['Gender'] ?? 'unknown').toString(),
      weight: weightRaw is num ? weightRaw.toDouble() : null,
      shellWidth: (json['shellWidth'] ?? json['ShellWidth']) is num
          ? (json['shellWidth'] ?? json['ShellWidth']).toDouble()
          : null,
      status: status,
      moltCount: (json['moltCount'] ?? json['MoltCount'] as num?)?.toInt() ?? 0,
      lastMoltDate: (json['moltedAt'] ??
              json['MoltedAt'] ??
              json['lastMoltDate'] ??
              json['LastMoltDate'])
          ?.toString(),
      healthStatus: (json['healthStatus'] ?? json['HealthStatus'] ?? molting)
          ?.toString(),
      growthStage: (json['growthStage'] ?? json['GrowthStage'])?.toString(),
      profileNote: (json['profileNote'] ?? json['ProfileNote'])?.toString(),
      batchStartDate: (json['stockedAt'] ??
              json['StockedAt'] ??
              json['batchStartDate'] ??
              json['BatchStartDate'] ??
              '')
          .toString(),
    );
  }
}
