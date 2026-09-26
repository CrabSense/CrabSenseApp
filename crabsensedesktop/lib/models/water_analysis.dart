String _s(Map<String, dynamic> json, List<String> keys, [String fallback = '']) {
  for (final k in keys) {
    final v = json[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return fallback;
}

double? _d(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is num) return v.toDouble();
  }
  return null;
}

int _i(Map<String, dynamic> json, List<String> keys, [int fallback = 0]) {
  for (final k in keys) {
    final v = json[k];
    if (v is num) return v.toInt();
  }
  return fallback;
}

bool _b(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v == true) return true;
  }
  return false;
}

DateTime? _dt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = DateTime.tryParse((json[k] ?? '').toString());
    if (v != null) return v;
  }
  return null;
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<Map<String, dynamic>> _list(dynamic v) {
  if (v is! List) return const [];
  return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

class WaterAnalysisMetric {
  const WaterAnalysisMetric({
    required this.code,
    required this.label,
    this.value,
    required this.unit,
    required this.status,
    required this.statusLabel,
    this.thresholdLabel,
  });

  final String code;
  final String label;
  final double? value;
  final String unit;
  final String status;
  final String statusLabel;
  final String? thresholdLabel;

  factory WaterAnalysisMetric.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisMetric(
      code: _s(json, ['code', 'Code']),
      label: _s(json, ['label', 'Label']),
      value: _d(json, ['value', 'Value']),
      unit: _s(json, ['unit', 'Unit']),
      status: _s(json, ['status', 'Status'], 'pending'),
      statusLabel: _s(json, ['statusLabel', 'StatusLabel']),
      thresholdLabel: _s(json, ['thresholdLabel', 'ThresholdLabel']).isEmpty
          ? null
          : _s(json, ['thresholdLabel', 'ThresholdLabel']),
    );
  }

  String get displayValue {
    if (value == null) return '—';
    if (code == 'ph') return value!.toStringAsFixed(2);
    if (code == 'no3') return value!.toStringAsFixed(0);
    return value!.toStringAsFixed(2);
  }

  String get displayUnit => unit;
}

class WaterAnalysisStationPart {
  const WaterAnalysisStationPart({
    required this.code,
    required this.label,
    required this.ready,
    required this.state,
    required this.stateLabel,
    this.detail,
    this.levelLabel,
  });

  final String code;
  final String label;
  final bool ready;
  final String state;
  final String stateLabel;
  final String? detail;
  final String? levelLabel;

  factory WaterAnalysisStationPart.fromJson(Map<String, dynamic> json) {
    final label = _s(json, ['stateLabel', 'StateLabel']);
    return WaterAnalysisStationPart(
      code: _s(json, ['code', 'Code']),
      label: _s(json, ['label', 'Label']),
      ready: _b(json, ['ready', 'Ready']),
      state: _s(json, ['state', 'State'], label.isEmpty ? 'UNKNOWN' : label),
      stateLabel: label,
      detail: _s(json, ['detail', 'Detail']).isEmpty
          ? null
          : _s(json, ['detail', 'Detail']),
      levelLabel: _s(json, ['levelLabel', 'LevelLabel']).isEmpty
          ? null
          : _s(json, ['levelLabel', 'LevelLabel']),
    );
  }
}

class WaterAnalysisStepLog {
  const WaterAnalysisStepLog({
    required this.at,
    required this.step,
    required this.event,
    required this.label,
  });

  final DateTime at;
  final int step;
  final String event;
  final String label;

  factory WaterAnalysisStepLog.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisStepLog(
      at: _dt(json, ['at', 'At']) ?? DateTime.now(),
      step: _i(json, ['step', 'Step']),
      event: _s(json, ['event', 'Event']),
      label: _s(json, ['label', 'Label']),
    );
  }
}

class WaterAnalysisRun {
  const WaterAnalysisRun({
    required this.id,
    required this.status,
    required this.currentStep,
    required this.stepLabel,
    required this.startedAt,
    this.completedAt,
    required this.metrics,
    this.error,
    this.testCode,
    this.sessionState,
    this.totalSteps = 8,
    this.progressPct = 0,
    this.remainingSeconds,
    this.analyte,
    this.analyteLabel,
    this.sampleSource,
    this.sampleSourceLabel,
    this.sampleLocation,
    this.notes,
    this.confidence,
    this.imageUrl,
    this.performedBy,
    this.controllerId,
    this.cameraId,
    this.stepLogs = const [],
  });

  final String id;
  final String status;
  final int currentStep;
  final String stepLabel;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<WaterAnalysisMetric> metrics;
  final String? error;
  final String? testCode;
  final String? sessionState;
  final int totalSteps;
  final int progressPct;
  final int? remainingSeconds;
  final String? analyte;
  final String? analyteLabel;
  final String? sampleSource;
  final String? sampleSourceLabel;
  final String? sampleLocation;
  final String? notes;
  final double? confidence;
  final String? imageUrl;
  final String? performedBy;
  final String? controllerId;
  final String? cameraId;
  final List<WaterAnalysisStepLog> stepLogs;

  bool get isRunning => status.toLowerCase() == 'running';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get displayCode =>
      (testCode != null && testCode!.isNotEmpty) ? testCode! : id;

  String get displayAnalyte =>
      (analyteLabel != null && analyteLabel!.isNotEmpty)
          ? analyteLabel!
          : (analyte ?? '—');

  Duration? get duration {
    final end = completedAt ?? (isRunning ? DateTime.now() : null);
    if (end == null) return null;
    return end.difference(startedAt);
  }

  WaterAnalysisMetric? metricOf(String code) {
    for (final m in metrics) {
      if (m.code.toLowerCase() == code.toLowerCase()) return m;
    }
    return null;
  }

  factory WaterAnalysisRun.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisRun(
      id: _s(json, ['id', 'Id']),
      status: _s(json, ['status', 'Status']),
      currentStep: _i(json, ['currentStep', 'CurrentStep'], 1),
      stepLabel: _s(json, ['stepLabel', 'StepLabel']),
      startedAt: _dt(json, ['startedAt', 'StartedAt']) ?? DateTime.now(),
      completedAt: _dt(json, ['completedAt', 'CompletedAt']),
      metrics: _list(json['metrics'] ?? json['Metrics'])
          .map(WaterAnalysisMetric.fromJson)
          .toList(),
      error: _s(json, ['error', 'Error']).isEmpty
          ? null
          : _s(json, ['error', 'Error']),
      testCode: _s(json, ['testCode', 'TestCode']).isEmpty
          ? null
          : _s(json, ['testCode', 'TestCode']),
      sessionState: _s(json, ['sessionState', 'SessionState']).isEmpty
          ? null
          : _s(json, ['sessionState', 'SessionState']),
      totalSteps: _i(json, ['totalSteps', 'TotalSteps'], 8),
      progressPct: _i(json, ['progressPct', 'ProgressPct']),
      remainingSeconds: () {
        final v = _i(json, ['remainingSeconds', 'RemainingSeconds'], -1);
        return v < 0 ? null : v;
      }(),
      analyte: _s(json, ['analyte', 'Analyte']).isEmpty
          ? null
          : _s(json, ['analyte', 'Analyte']),
      analyteLabel: _s(json, ['analyteLabel', 'AnalyteLabel']).isEmpty
          ? null
          : _s(json, ['analyteLabel', 'AnalyteLabel']),
      sampleSource: _s(json, ['sampleSource', 'SampleSource']).isEmpty
          ? null
          : _s(json, ['sampleSource', 'SampleSource']),
      sampleSourceLabel: _s(json, ['sampleSourceLabel', 'SampleSourceLabel']).isEmpty
          ? null
          : _s(json, ['sampleSourceLabel', 'SampleSourceLabel']),
      sampleLocation: _s(json, ['sampleLocation', 'SampleLocation']).isEmpty
          ? null
          : _s(json, ['sampleLocation', 'SampleLocation']),
      notes: _s(json, ['notes', 'Notes']).isEmpty
          ? null
          : _s(json, ['notes', 'Notes']),
      confidence: _d(json, ['confidence', 'Confidence']),
      imageUrl: _s(json, ['imageUrl', 'ImageUrl']).isEmpty
          ? null
          : _s(json, ['imageUrl', 'ImageUrl']),
      performedBy: _s(json, ['performedBy', 'PerformedBy']).isEmpty
          ? null
          : _s(json, ['performedBy', 'PerformedBy']),
      controllerId: _s(json, ['controllerId', 'ControllerId']).isEmpty
          ? null
          : _s(json, ['controllerId', 'ControllerId']),
      cameraId: _s(json, ['cameraId', 'CameraId']).isEmpty
          ? null
          : _s(json, ['cameraId', 'CameraId']),
      stepLogs: _list(json['stepLogs'] ?? json['StepLogs'])
          .map(WaterAnalysisStepLog.fromJson)
          .toList(),
    );
  }
}

class WaterAnalysisThreshold {
  const WaterAnalysisThreshold({
    required this.code,
    required this.label,
    required this.unit,
    this.min,
    this.max,
    this.warningMin,
    this.warningMax,
    required this.display,
  });

  final String code;
  final String label;
  final String unit;
  final double? min;
  final double? max;
  final double? warningMin;
  final double? warningMax;
  final String display;

  factory WaterAnalysisThreshold.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisThreshold(
      code: _s(json, ['code', 'Code']),
      label: _s(json, ['label', 'Label']),
      unit: _s(json, ['unit', 'Unit']),
      min: _d(json, ['min', 'Min']),
      max: _d(json, ['max', 'Max']),
      warningMin: _d(json, ['warningMin', 'WarningMin']),
      warningMax: _d(json, ['warningMax', 'WarningMax']),
      display: _s(json, ['display', 'Display']),
    );
  }
}

class WaterAnalysisSample {
  const WaterAnalysisSample({
    required this.areaName,
    required this.areaCode,
    required this.sampleSource,
    required this.sampleSourceLabel,
    this.sampleLocation,
    this.notes,
  });

  final String areaName;
  final String areaCode;
  final String sampleSource;
  final String sampleSourceLabel;
  final String? sampleLocation;
  final String? notes;

  factory WaterAnalysisSample.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisSample(
      areaName: _s(json, ['areaName', 'AreaName']),
      areaCode: _s(json, ['areaCode', 'AreaCode']),
      sampleSource: _s(json, ['sampleSource', 'SampleSource'], 'RAS_RETURN'),
      sampleSourceLabel: _s(json, ['sampleSourceLabel', 'SampleSourceLabel']),
      sampleLocation: _s(json, ['sampleLocation', 'SampleLocation']).isEmpty
          ? null
          : _s(json, ['sampleLocation', 'SampleLocation']),
      notes: _s(json, ['notes', 'Notes']).isEmpty
          ? null
          : _s(json, ['notes', 'Notes']),
    );
  }
}

class WaterAnalysisAssay {
  const WaterAnalysisAssay({
    required this.analyte,
    required this.label,
    required this.configured,
    this.sampleVolumeMl,
    this.reactionTimeSeconds,
    this.reagent1Dose,
    this.reagent2Dose,
    this.aiModelId,
    this.aiConfidenceMin,
  });

  final String analyte;
  final String label;
  final bool configured;
  final double? sampleVolumeMl;
  final int? reactionTimeSeconds;
  final String? reagent1Dose;
  final String? reagent2Dose;
  final String? aiModelId;
  final double? aiConfidenceMin;

  factory WaterAnalysisAssay.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisAssay(
      analyte: _s(json, ['analyte', 'Analyte']),
      label: _s(json, ['label', 'Label']),
      configured: _b(json, ['configured', 'Configured']),
      sampleVolumeMl: _d(json, ['sampleVolumeMl', 'SampleVolumeMl']),
      reactionTimeSeconds: () {
        final v = _i(json, ['reactionTimeSeconds', 'ReactionTimeSeconds'], -1);
        return v < 0 ? null : v;
      }(),
      reagent1Dose: _s(json, ['reagent1Dose', 'Reagent1Dose']).isEmpty
          ? null
          : _s(json, ['reagent1Dose', 'Reagent1Dose']),
      reagent2Dose: _s(json, ['reagent2Dose', 'Reagent2Dose']).isEmpty
          ? null
          : _s(json, ['reagent2Dose', 'Reagent2Dose']),
      aiModelId: _s(json, ['aiModelId', 'AiModelId']).isEmpty
          ? null
          : _s(json, ['aiModelId', 'AiModelId']),
      aiConfidenceMin: _d(json, ['aiConfidenceMin', 'AiConfidenceMin']),
    );
  }
}

class WaterAnalysisSourceOption {
  const WaterAnalysisSourceOption({required this.code, required this.label});
  final String code;
  final String label;

  factory WaterAnalysisSourceOption.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisSourceOption(
      code: _s(json, ['code', 'Code']),
      label: _s(json, ['label', 'Label']),
    );
  }
}

class WaterAnalysisBlocker {
  const WaterAnalysisBlocker({
    required this.code,
    required this.label,
    required this.reason,
  });

  final String code;
  final String label;
  final String reason;

  factory WaterAnalysisBlocker.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisBlocker(
      code: _s(json, ['code', 'Code']),
      label: _s(json, ['label', 'Label']),
      reason: _s(json, ['reason', 'Reason']),
    );
  }
}

class WaterAnalysisTrendPoint {
  const WaterAnalysisTrendPoint({
    required this.date,
    required this.value,
    required this.status,
    required this.statusLabel,
    this.testCode,
    this.runId,
  });

  final DateTime date;
  final double value;
  final String status;
  final String statusLabel;
  final String? testCode;
  final String? runId;

  factory WaterAnalysisTrendPoint.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisTrendPoint(
      date: _dt(json, ['date', 'Date']) ?? DateTime.now(),
      value: _d(json, ['value', 'Value']) ?? 0,
      status: _s(json, ['status', 'Status']),
      statusLabel: _s(json, ['statusLabel', 'StatusLabel']),
      testCode: _s(json, ['testCode', 'TestCode']).isEmpty
          ? null
          : _s(json, ['testCode', 'TestCode']),
      runId: _s(json, ['runId', 'RunId']).isEmpty
          ? null
          : _s(json, ['runId', 'RunId']),
    );
  }
}

class WaterAnalysisStepDef {
  const WaterAnalysisStepDef({
    required this.index,
    required this.label,
    required this.command,
  });

  final int index;
  final String label;
  final String command;

  factory WaterAnalysisStepDef.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisStepDef(
      index: _i(json, ['index', 'Index']),
      label: _s(json, ['label', 'Label']),
      command: _s(json, ['command', 'Command']),
    );
  }
}

class WaterAnalysisSnapshot {
  const WaterAnalysisSnapshot({
    this.latest,
    this.active,
    required this.station,
    this.history = const [],
    this.thresholds = const [],
    this.sample,
    this.assays = const [],
    this.sampleSources = const [],
    this.blockers = const [],
    this.canStart = false,
    this.trend = const [],
    this.trendAnalyte,
    this.steps = const [],
    this.systemError,
  });

  final WaterAnalysisRun? latest;
  final WaterAnalysisRun? active;
  final List<WaterAnalysisStationPart> station;
  final List<WaterAnalysisRun> history;
  final List<WaterAnalysisThreshold> thresholds;
  final WaterAnalysisSample? sample;
  final List<WaterAnalysisAssay> assays;
  final List<WaterAnalysisSourceOption> sampleSources;
  final List<WaterAnalysisBlocker> blockers;
  final bool canStart;
  final List<WaterAnalysisTrendPoint> trend;
  final String? trendAnalyte;
  final List<WaterAnalysisStepDef> steps;
  final String? systemError;

  factory WaterAnalysisSnapshot.fromJson(Map<String, dynamic> json) {
    final latest = _map(json['latest'] ?? json['Latest']);
    final active = _map(json['active'] ?? json['Active']);
    final sample = _map(json['sample'] ?? json['Sample']);
    return WaterAnalysisSnapshot(
      latest: latest == null ? null : WaterAnalysisRun.fromJson(latest),
      active: active == null ? null : WaterAnalysisRun.fromJson(active),
      station: _list(json['station'] ?? json['Station'])
          .map(WaterAnalysisStationPart.fromJson)
          .toList(),
      history: _list(json['history'] ?? json['History'])
          .map(WaterAnalysisRun.fromJson)
          .toList(),
      thresholds: _list(json['thresholds'] ?? json['Thresholds'])
          .map(WaterAnalysisThreshold.fromJson)
          .toList(),
      sample: sample == null ? null : WaterAnalysisSample.fromJson(sample),
      assays: _list(json['assays'] ?? json['Assays'])
          .map(WaterAnalysisAssay.fromJson)
          .toList(),
      sampleSources: _list(json['sampleSources'] ?? json['SampleSources'])
          .map(WaterAnalysisSourceOption.fromJson)
          .toList(),
      blockers: _list(json['blockers'] ?? json['Blockers'])
          .map(WaterAnalysisBlocker.fromJson)
          .toList(),
      canStart: _b(json, ['canStart', 'CanStart']),
      trend: _list(json['trend'] ?? json['Trend'])
          .map(WaterAnalysisTrendPoint.fromJson)
          .toList(),
      trendAnalyte: _s(json, ['trendAnalyte', 'TrendAnalyte']).isEmpty
          ? null
          : _s(json, ['trendAnalyte', 'TrendAnalyte']),
      steps: _list(json['steps'] ?? json['Steps'])
          .map(WaterAnalysisStepDef.fromJson)
          .toList(),
      systemError: _s(json, ['systemError', 'SystemError']).isEmpty
          ? null
          : _s(json, ['systemError', 'SystemError']),
    );
  }
}

class WaterAnalysisHardwareItem {
  const WaterAnalysisHardwareItem({
    required this.code,
    required this.label,
    this.deviceId,
    required this.state,
    required this.stateLabel,
    required this.ready,
    this.clickable = false,
  });

  final String code;
  final String label;
  final String? deviceId;
  final String state;
  final String stateLabel;
  final bool ready;
  final bool clickable;

  factory WaterAnalysisHardwareItem.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisHardwareItem(
      code: _s(json, ['code', 'Code']),
      label: _s(json, ['label', 'Label']),
      deviceId: _s(json, ['deviceId', 'DeviceId']).isEmpty
          ? null
          : _s(json, ['deviceId', 'DeviceId']),
      state: _s(json, ['state', 'State']),
      stateLabel: _s(json, ['stateLabel', 'StateLabel']),
      ready: _b(json, ['ready', 'Ready']),
      clickable: _b(json, ['clickable', 'Clickable']),
    );
  }
}

class WaterAnalysisColorSwatch {
  const WaterAnalysisColorSwatch({
    required this.index,
    required this.hex,
    this.value,
    required this.selected,
  });

  final int index;
  final String hex;
  final double? value;
  final bool selected;

  factory WaterAnalysisColorSwatch.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisColorSwatch(
      index: _i(json, ['index', 'Index']),
      hex: _s(json, ['hex', 'Hex'], '#E8F5F0'),
      value: _d(json, ['value', 'Value']),
      selected: _b(json, ['selected', 'Selected']),
    );
  }
}

class WaterAnalysisProcessStep {
  const WaterAnalysisProcessStep({
    required this.index,
    required this.key,
    required this.label,
    required this.status,
    required this.statusLabel,
    this.at,
    this.detail,
    this.errorCode,
    this.errorMessage,
  });

  final int index;
  final String key;
  final String label;
  final String status;
  final String statusLabel;
  final DateTime? at;
  final String? detail;
  final String? errorCode;
  final String? errorMessage;

  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isDone => status.toUpperCase() == 'COMPLETED';

  factory WaterAnalysisProcessStep.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisProcessStep(
      index: _i(json, ['index', 'Index']),
      key: _s(json, ['key', 'Key']),
      label: _s(json, ['label', 'Label']),
      status: _s(json, ['status', 'Status']),
      statusLabel: _s(json, ['statusLabel', 'StatusLabel']),
      at: _dt(json, ['at', 'At']),
      detail: _s(json, ['detail', 'Detail']).isEmpty
          ? null
          : _s(json, ['detail', 'Detail']),
      errorCode: _s(json, ['errorCode', 'ErrorCode']).isEmpty
          ? null
          : _s(json, ['errorCode', 'ErrorCode']),
      errorMessage: _s(json, ['errorMessage', 'ErrorMessage']).isEmpty
          ? null
          : _s(json, ['errorMessage', 'ErrorMessage']),
    );
  }
}

class WaterAnalysisPrevious {
  const WaterAnalysisPrevious({
    this.testCode,
    this.value,
    required this.unit,
    this.at,
    this.delta,
  });

  final String? testCode;
  final double? value;
  final String unit;
  final DateTime? at;
  final double? delta;

  factory WaterAnalysisPrevious.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisPrevious(
      testCode: _s(json, ['testCode', 'TestCode']).isEmpty
          ? null
          : _s(json, ['testCode', 'TestCode']),
      value: _d(json, ['value', 'Value']),
      unit: _s(json, ['unit', 'Unit']),
      at: _dt(json, ['at', 'At']),
      delta: _d(json, ['delta', 'Delta']),
    );
  }
}

class WaterAnalysisRelatedAlert {
  const WaterAnalysisRelatedAlert({required this.code, required this.title});
  final String code;
  final String title;

  factory WaterAnalysisRelatedAlert.fromJson(Map<String, dynamic> json) {
    return WaterAnalysisRelatedAlert(
      code: _s(json, ['code', 'Code']),
      title: _s(json, ['title', 'Title']),
    );
  }
}

class WaterAnalysisDetail {
  const WaterAnalysisDetail({
    required this.id,
    this.testCode,
    required this.status,
    required this.statusLabel,
    required this.analyte,
    required this.analyteLabel,
    this.result,
    required this.unit,
    required this.evaluation,
    required this.evaluationLabel,
    this.thresholdDisplay,
    this.overThreshold,
    this.confidence,
    this.confidenceLevel,
    this.confidenceLabel,
    required this.usedAi,
    this.imageUrl,
    this.areaName,
    this.areaCode,
    this.sampleSource,
    this.sampleSourceLabel,
    this.sampleLocation,
    this.notes,
    required this.method,
    this.performedBy,
    required this.startedAt,
    this.completedAt,
    this.hardware = const [],
    this.colorReference = const [],
    this.colorReferenceNote,
    this.steps = const [],
    this.legacySteps = false,
    this.internalId,
    this.aiModelId,
    this.aiModelVersion,
    this.firmwareVersion,
    this.imagePath,
    this.previous,
    this.alert,
    this.error,
    this.failedStep,
    this.canRerun = false,
  });

  final String id;
  final String? testCode;
  final String status;
  final String statusLabel;
  final String analyte;
  final String analyteLabel;
  final double? result;
  final String unit;
  final String evaluation;
  final String evaluationLabel;
  final String? thresholdDisplay;
  final double? overThreshold;
  final double? confidence;
  final String? confidenceLevel;
  final String? confidenceLabel;
  final bool usedAi;
  final String? imageUrl;
  final String? areaName;
  final String? areaCode;
  final String? sampleSource;
  final String? sampleSourceLabel;
  final String? sampleLocation;
  final String? notes;
  final String method;
  final String? performedBy;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<WaterAnalysisHardwareItem> hardware;
  final List<WaterAnalysisColorSwatch> colorReference;
  final String? colorReferenceNote;
  final List<WaterAnalysisProcessStep> steps;
  final bool legacySteps;
  final String? internalId;
  final String? aiModelId;
  final String? aiModelVersion;
  final String? firmwareVersion;
  final String? imagePath;
  final WaterAnalysisPrevious? previous;
  final WaterAnalysisRelatedAlert? alert;
  final String? error;
  final String? failedStep;
  final bool canRerun;

  String get displayCode =>
      (testCode != null && testCode!.isNotEmpty) ? testCode! : 'TEST';

  String get resultText {
    if (result == null) return 'Không có kết quả';
    if (unit.isEmpty) return result!.toStringAsFixed(2);
    return '${result!.toStringAsFixed(2)} $unit';
  }

  String get areaLabel {
    final code = areaCode ?? '';
    final name = areaName ?? '';
    if (code.isEmpty) return name.isEmpty ? 'Không xác định' : name;
    if (name.isEmpty) return code;
    return '$code — $name';
  }

  Duration? get duration {
    final end = completedAt ??
        (status.toLowerCase() == 'running' ? DateTime.now() : null);
    if (end == null) return null;
    return end.difference(startedAt);
  }

  factory WaterAnalysisDetail.fromJson(Map<String, dynamic> json) {
    final prev = _map(json['previous'] ?? json['Previous']);
    final alert = _map(json['alert'] ?? json['Alert']);
    return WaterAnalysisDetail(
      id: _s(json, ['id', 'Id']),
      testCode: _s(json, ['testCode', 'TestCode']).isEmpty
          ? null
          : _s(json, ['testCode', 'TestCode']),
      status: _s(json, ['status', 'Status']),
      statusLabel: _s(json, ['statusLabel', 'StatusLabel']),
      analyte: _s(json, ['analyte', 'Analyte']),
      analyteLabel: _s(json, ['analyteLabel', 'AnalyteLabel']),
      result: _d(json, ['result', 'Result']),
      unit: _s(json, ['unit', 'Unit']),
      evaluation: _s(json, ['evaluation', 'Evaluation']),
      evaluationLabel: _s(json, ['evaluationLabel', 'EvaluationLabel']),
      thresholdDisplay: _s(json, ['thresholdDisplay', 'ThresholdDisplay']).isEmpty
          ? null
          : _s(json, ['thresholdDisplay', 'ThresholdDisplay']),
      overThreshold: _d(json, ['overThreshold', 'OverThreshold']),
      confidence: _d(json, ['confidence', 'Confidence']),
      confidenceLevel: _s(json, ['confidenceLevel', 'ConfidenceLevel']).isEmpty
          ? null
          : _s(json, ['confidenceLevel', 'ConfidenceLevel']),
      confidenceLabel: _s(json, ['confidenceLabel', 'ConfidenceLabel']).isEmpty
          ? null
          : _s(json, ['confidenceLabel', 'ConfidenceLabel']),
      usedAi: _b(json, ['usedAi', 'UsedAi']),
      imageUrl: _s(json, ['imageUrl', 'ImageUrl']).isEmpty
          ? null
          : _s(json, ['imageUrl', 'ImageUrl']),
      areaName: _s(json, ['areaName', 'AreaName']).isEmpty
          ? null
          : _s(json, ['areaName', 'AreaName']),
      areaCode: _s(json, ['areaCode', 'AreaCode']).isEmpty
          ? null
          : _s(json, ['areaCode', 'AreaCode']),
      sampleSource: _s(json, ['sampleSource', 'SampleSource']).isEmpty
          ? null
          : _s(json, ['sampleSource', 'SampleSource']),
      sampleSourceLabel:
          _s(json, ['sampleSourceLabel', 'SampleSourceLabel']).isEmpty
              ? null
              : _s(json, ['sampleSourceLabel', 'SampleSourceLabel']),
      sampleLocation: _s(json, ['sampleLocation', 'SampleLocation']).isEmpty
          ? null
          : _s(json, ['sampleLocation', 'SampleLocation']),
      notes: _s(json, ['notes', 'Notes']).isEmpty
          ? null
          : _s(json, ['notes', 'Notes']),
      method: _s(json, ['method', 'Method'], 'Thuốc thử + Camera + AI'),
      performedBy: _s(json, ['performedBy', 'PerformedBy']).isEmpty
          ? null
          : _s(json, ['performedBy', 'PerformedBy']),
      startedAt: _dt(json, ['startedAt', 'StartedAt']) ?? DateTime.now(),
      completedAt: _dt(json, ['completedAt', 'CompletedAt']),
      hardware: _list(json['hardware'] ?? json['Hardware'])
          .map(WaterAnalysisHardwareItem.fromJson)
          .toList(),
      colorReference: _list(json['colorReference'] ?? json['ColorReference'])
          .map(WaterAnalysisColorSwatch.fromJson)
          .toList(),
      colorReferenceNote:
          _s(json, ['colorReferenceNote', 'ColorReferenceNote']).isEmpty
              ? null
              : _s(json, ['colorReferenceNote', 'ColorReferenceNote']),
      steps: _list(json['steps'] ?? json['Steps'])
          .map(WaterAnalysisProcessStep.fromJson)
          .toList(),
      legacySteps: _b(json, ['legacySteps', 'LegacySteps']),
      internalId: _s(json, ['internalId', 'InternalId']).isEmpty
          ? null
          : _s(json, ['internalId', 'InternalId']),
      aiModelId: _s(json, ['aiModelId', 'AiModelId']).isEmpty
          ? null
          : _s(json, ['aiModelId', 'AiModelId']),
      aiModelVersion: _s(json, ['aiModelVersion', 'AiModelVersion']).isEmpty
          ? null
          : _s(json, ['aiModelVersion', 'AiModelVersion']),
      firmwareVersion: _s(json, ['firmwareVersion', 'FirmwareVersion']).isEmpty
          ? null
          : _s(json, ['firmwareVersion', 'FirmwareVersion']),
      imagePath: _s(json, ['imagePath', 'ImagePath']).isEmpty
          ? null
          : _s(json, ['imagePath', 'ImagePath']),
      previous: prev == null ? null : WaterAnalysisPrevious.fromJson(prev),
      alert: alert == null ? null : WaterAnalysisRelatedAlert.fromJson(alert),
      error: _s(json, ['error', 'Error']).isEmpty
          ? null
          : _s(json, ['error', 'Error']),
      failedStep: _s(json, ['failedStep', 'FailedStep']).isEmpty
          ? null
          : _s(json, ['failedStep', 'FailedStep']),
      canRerun: _b(json, ['canRerun', 'CanRerun']),
    );
  }
}

abstract final class WaterAnalysisSteps {
  static const labels = [
    'Lấy mẫu nước',
    'Thêm thuốc thử #1',
    'Chờ phản ứng',
    'Thêm thuốc thử #2',
    'Camera chụp mẫu',
    'AI phân tích',
    'Lưu kết quả',
    'Xả & làm sạch',
  ];
}
