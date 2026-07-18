import 'package:flutter/material.dart';
import '../models/water_quality_data.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/data_card.dart';
import '../widgets/app_logo.dart';

class DataMonitoringScreen extends StatefulWidget {
  const DataMonitoringScreen({super.key});

  @override
  State<DataMonitoringScreen> createState() => _DataMonitoringScreenState();
}

class _DataMonitoringScreenState extends State<DataMonitoringScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConstants.apiBaseUrl);
  List<WaterQualityData>? _data;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getLatestData();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarLogo(),
        title: const Text('Giám sát dữ liệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi khi tải dữ liệu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_data == null || _data!.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _data!.length,
        itemBuilder: (context, index) {
          return DataCard(data: _data![index]);
        },
      ),
    );
  }
}
