import 'dart:io';

import 'package:crabsensemobile/core/constants/api_constants.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/core/network/api_client.dart';
import 'package:crabsensemobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:crabsensemobile/features/harvest/data/datasources/harvest_remote_data_source.dart';
import 'package:crabsensemobile/features/harvest/data/models/harvest_model.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// Chỉ cần thoả interface — test override `safePost` nên không có call nào lọt xuống.
class _StubAuthLocal implements AuthLocalDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.failUpload = false})
      : super(
          logger: Logger(level: Level.off),
          authLocalDataSource: _StubAuthLocal(),
        );

  final bool failUpload;
  final List<({String path, Object? data})> requests = [];

  @override
  Future<({Response<T> data, Failure? failure})> safePost<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requests.add((path: path, data: data));

    // Phiếu tạo trước để BE sinh mã HAR-xxx.
    if (path == ApiConstants.recordHarvest) {
      return (
        data: Response<T>(
          requestOptions: RequestOptions(path: path),
          data: <String, dynamic>{
            'success': true,
            'data': {'id': 'voucher-1', 'voucherCode': 'HAR-012'},
          } as T,
        ),
        failure: null,
      );
    }

    if (failUpload) {
      return (
        data: Response<T>(requestOptions: RequestOptions(path: path)),
        failure: const ServerFailure('drive down'),
      );
    }

    return (
      data: Response<T>(
        requestOptions: RequestOptions(path: path),
        data: <String, dynamic>{
          'success': true,
          'data': [
            {'url': 'https://drive.example/uploaded.jpg'},
          ],
        } as T,
      ),
      failure: null,
    );
  }
}

HarvestModel _model(List<String> photoUrls) => HarvestModel(
      id: 'harvest-1',
      boxId: 'BOX-0049',
      farmId: '',
      totalWeight: 0.24,
      crabCount: 1,
      qualityGrade: QualityGrade.gradeA,
      harvestDate: DateTime.utc(2026, 10, 26, 4, 45),
      operatorId: 'op-1',
      operatorName: 'Chu trai',
      photoUrls: photoUrls,
      crabId: '41f22184-b496-4cfa-8c7a-062be7e2b269',
    );

void main() {
  group('recordHarvest — ảnh thu hoạch', () {
    test('ảnh đã là URL công khai thì gửi thẳng, không upload lại', () async {
      final api = _FakeApiClient();
      final dataSource = HarvestRemoteDataSourceImpl(
        apiClient: api,
        logger: Logger(level: Level.off),
      );
      const url = 'https://drive.google.com/uc?export=view&id=ABC';

      await dataSource.recordHarvest(_model([url]));

      expect(api.requests.map((r) => r.path), [ApiConstants.recordHarvest]);
      final body = api.requests.single.data as Map<String, dynamic>;
      expect(body['photoUrls'], [url]);
      expect((body['lines'] as List).single['photoUrls'], [url]);
    });

    test('ảnh local được upload SAU khi phiếu có id, vào thư mục phiếu',
        () async {
      final dir = Directory.systemTemp.createTempSync('harvest_photo_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/IMG_001.jpg')..writeAsBytesSync([1, 2, 3]);

      final api = _FakeApiClient();
      final dataSource = HarvestRemoteDataSourceImpl(
        apiClient: api,
        logger: Logger(level: Level.off),
      );

      final saved = await dataSource.recordHarvest(_model([file.path]));

      expect(api.requests.first.path, ApiConstants.recordHarvest);
      expect(
        api.requests.last.path,
        ApiConstants.harvestVoucherImages('voucher-1'),
      );

      // Path local không được gửi lên BE (sẽ bị lưu thành photoUrls rác).
      final body = api.requests.first.data as Map<String, dynamic>;
      expect(body['photoUrls'], isNull);

      expect(saved.photoUrls, ['https://drive.example/uploaded.jpg']);
      expect(saved.isSynced, isTrue);
    });

    test('upload ảnh lỗi vẫn giữ phiếu và ảnh local, không ném lỗi', () async {
      final dir = Directory.systemTemp.createTempSync('harvest_photo_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/IMG_002.jpg')..writeAsBytesSync([1, 2, 3]);

      final api = _FakeApiClient(failUpload: true);
      final dataSource = HarvestRemoteDataSourceImpl(
        apiClient: api,
        logger: Logger(level: Level.off),
      );

      final saved = await dataSource.recordHarvest(_model([file.path]));

      expect(api.requests.first.path, ApiConstants.recordHarvest);
      expect(saved.photoUrls, [file.path]);
      expect(saved.isSynced, isTrue);
    });
  });
}
