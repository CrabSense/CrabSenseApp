import 'package:flutter/foundation.dart';

import '../models/crab_growth_molt.dart';
import '../models/crab_individual.dart';
import 'cloud_api_client.dart';

/// State tab "Sinh trưởng & Lột xác". Dữ liệu 100% từ API.
class CrabGrowthMoltController extends ChangeNotifier {
  CrabGrowthMoltController({
    required this.crabId,
    required this.api,
    required this.tokenProvider,
  });

  final String crabId;
  final CloudApiClient api;
  final String Function() tokenProvider;

  GrowthPeriod _period = GrowthPeriod.d30;
  CrabGrowthMoltData? _data;
  bool _loading = false;
  String? _error;
  String? _moltError;
  int _gen = 0;

  GrowthPeriod get period => _period;
  CrabGrowthMoltData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  String? get moltError => _moltError;

  DateTime? get from {
    final d = _period.duration;
    if (d == null) return null;
    return DateTime.now().subtract(d);
  }

  DateTime? get to => _period.duration == null ? null : DateTime.now();

  Future<void> load() async {
    final gen = ++_gen;
    _loading = true;
    _error = null;
    _moltError = null;
    notifyListeners();
    try {
      final next = await api.fetchCrabGrowthMolt(
        tokenProvider(),
        crabId,
        from: from,
        to: to,
      );
      if (gen != _gen) return;
      _data = next;
    } on CloudApiException catch (e) {
      if (gen != _gen) return;
      _error = e.message;
    } catch (e) {
      if (gen != _gen) return;
      _error = '$e';
    } finally {
      if (gen == _gen) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void setPeriod(GrowthPeriod p) {
    if (_period == p) return;
    _period = p;
    load();
  }

  Future<String?> record(NewGrowthInput input, {required CrabIndividual crab, String? operatorName}) async {
    try {
      if (input.isMolt) {
        final prev = _data?.latest;
        final moltId = await api.recordCrabMolt(
          tokenProvider(),
          crabId,
          moltDate: (input.moltCompletedAt ?? input.measuredAt).toIso8601String(),
          moltNumber: (_data?.molts.length ?? crab.moltCount) + 1,
          condition: input.moltStatus.api,
          note: input.moltNote ?? input.note,
          boxId: crab.boxId,
          startedAt: input.moltStartedAt,
          completedAt: input.moltCompletedAt ?? input.measuredAt,
          weightBeforeGram: prev?.weightGram,
          weightAfterGram: input.weightGram,
          shellWidthBeforeMm: prev?.shellWidthMm,
          shellLengthBeforeMm: prev?.shellLengthMm,
          shellWidthAfterMm: input.shellWidthMm,
          shellLengthAfterMm: input.shellLengthMm,
          cameraId: input.cameraId,
        );
        if (input.moltPhotoUrls.isNotEmpty && moltId != null && moltId.isNotEmpty) {
          await api.uploadMoltImages(tokenProvider(), moltId, input.moltPhotoUrls);
        }
      } else {
        await api.recordCrabWeight(
          tokenProvider(),
          crabId,
          measuredAt: input.measuredAt,
          weightGram: input.weightGram,
          shellWidthMm: input.shellWidthMm,
          shellLengthMm: input.shellLengthMm,
          notes: input.note,
          recordedByName: operatorName,
          photoUrls: input.photoUrls,
        );
      }
      await load();
      return null;
    } on CloudApiException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> updateNote(GrowthMeasurement m, String note) async {
    try {
      await api.updateCrabWeightNote(tokenProvider(), crabId, m.id, note);
      await load();
      return null;
    } on CloudApiException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }
}
