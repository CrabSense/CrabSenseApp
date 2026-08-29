import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/crab_model.dart';
import '../../../home/presentation/widgets/home_palette.dart';

const _primary  = Color(0xFF27AE60);
const _primaryDk= Color(0xFF1E8449);
const _primaryBg= Color(0xFFD5F5E3);
const _bg       = Color(0xFFF0F3F7);
const _surface  = Color(0xFFFFFFFF);
const _textMain = Color(0xFF1A2E3B);
const _textSub  = Color(0xFF5A7184);
const _border   = Color(0xFFDDE4EB);

/// Chi tiết một con cua.
class CrabDetailScreen extends StatelessWidget {
  const CrabDetailScreen({
    super.key,
    required this.crabId,
    this.boxId,
    this.initial,
  });

  final String crabId;
  final String? boxId;
  final CrabModel? initial;

  @override
  Widget build(BuildContext context) {
    final crab = initial;

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E8449), Color(0xFF27AE60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Text(
              crab != null && crab.addedBy.isNotEmpty ? 'Cua: ${crab.addedBy}' : 'Chi tiết cua',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: crab == null
          ? const Center(child: Text('Không có dữ liệu', style: TextStyle(color: _textSub)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(color: _primaryBg, shape: BoxShape.circle),
                    child: const Icon(Icons.pest_control_rounded, color: _primaryDk, size: 40),
                  ),
                  const SizedBox(height: 20),

                  // Info card
                  _infoCard([
                    _row('Mã cua', crab.addedBy.isNotEmpty ? crab.addedBy : crabId.substring(0, 8)),
                    _row('Cân nặng', '${crab.weight.round()} gram'),
                    _row('Loài', crab.species.name),
                    _row('Trạng thái lột', crab.moltingStatus.name),
                    _row('Sức khoẻ', crab.healthStatus.name),
                    _row('Nguồn gốc', crab.source.name),
                    _row('Hộp nuôi', boxId ?? '-'),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(children: rows),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _textSub)),
        Text(value, style: const TextStyle(color: _textMain, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
