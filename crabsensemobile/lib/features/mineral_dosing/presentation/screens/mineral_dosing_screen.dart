// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../../profile/presentation/widgets/profile_hub_scaffold.dart';
import '../../data/models/mineral_dose_models.dart';
import '../../data/models/salinity_mix_models.dart';
import '../providers/mineral_dosing_provider.dart';

/// Màn xử lý nước RAS — hai tab theo đúng thứ tự việc phải làm ở trại:
///
///   ① PHA ĐỘ MẶN   — thêm muối để tăng ‰, hoặc thêm nước ngọt để giảm ‰.
///   ② LIỀU Ca/Mg   — đo lại Ca/Mg sau khi pha rồi mới châm khoáng.
///
/// Hai tab là hai bài toán KHÁC NHAU nên không trộn làm một form: Ca/Mg không tham
/// gia phép tính pha độ mặn (không biết thành phần ion của lô muối), và độ mặn cũng
/// không tham gia phép tính gram CaCl₂/MgCl₂.
class MineralDosingScreen extends ConsumerStatefulWidget {
  const MineralDosingScreen({super.key});

  @override
  ConsumerState<MineralDosingScreen> createState() =>
      _MineralDosingScreenState();
}

class _MineralDosingScreenState extends ConsumerState<MineralDosingScreen> {
  final _volume = TextEditingController(text: '1000');
  final _salinity = TextEditingController();
  final _salinityTarget = TextEditingController();
  final _caCurrent = TextEditingController();
  final _caTarget = TextEditingController();
  final _mgCurrent = TextEditingController();
  final _mgTarget = TextEditingController();

  // Tab ① pha độ mặn dùng chung ô thể tích, độ mặn hiện tại và độ mặn mong muốn với
  // tab ②: nông dân đo một lần rồi làm hai việc, bắt nhập lại ở tab kia là vô nghĩa.
  final _saltPurity = TextEditingController();
  String _saltType = 'raw';

  MineralTargetMode _mode = MineralTargetMode.auto;
  bool _caMeasured = true;
  bool _mgMeasured = true;

  @override
  void initState() {
    super.initState();
    // Danh mục loại muối do BE trả để mobile và desktop dùng chung nhãn + ghi chú.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mineralDosingProvider.notifier).loadSaltTypes();
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _volume,
      _salinity,
      _salinityTarget,
      _caCurrent,
      _caTarget,
      _mgCurrent,
      _mgTarget,
      _saltPurity,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static double? _parse(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _onSalinityChanged(String _) {
    ref.read(mineralDosingProvider.notifier).scheduleRecommendation(
          _parse(_salinity.text),
        );
  }

  void _calculate() {
    final volume = _parse(_volume.text);
    if (volume == null || volume <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập thể tích nước lớn hơn 0 (L)')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    // Chế độ AUTO: cố ý KHÔNG gửi mục tiêu để BE tự chọn theo độ mặn —
    // tránh hai nguồn sự thật cho cùng một công thức.
    final auto = _mode == MineralTargetMode.auto;

    ref.read(mineralDosingProvider.notifier).calculate(
          MineralDoseRequest(
            waterVolumeL: volume,
            salinityCurrentPpt: _parse(_salinity.text),
            salinityTargetPpt: _parse(_salinityTarget.text),
            calciumCurrentMgL: _parse(_caCurrent.text),
            calciumTargetMgL: auto ? null : _parse(_caTarget.text),
            magnesiumCurrentMgL: _parse(_mgCurrent.text),
            magnesiumTargetMgL: auto ? null : _parse(_mgTarget.text),
            calciumMeasured: _caMeasured,
            magnesiumMeasured: _mgMeasured,
            targetMode: _mode,
          ),
        );
  }

  /// Tab ① — pha độ mặn. Tăng thì tính muối, giảm thì tính nước ngọt.
  void _calcSalinity() {
    final volume = _parse(_volume.text);
    if (volume == null || volume <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập thể tích nước lớn hơn 0 (L)')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    ref.read(mineralDosingProvider.notifier).mixSalinity(
          SalinityMixRequest(
            waterVolumeL: volume,
            currentSalinityPpt: _parse(_salinity.text),
            targetSalinityPpt: _parse(_salinityTarget.text),
            saltType: _saltType,
            // Để trống = chưa biết độ tinh khiết ⇒ BE tính theo 100% + cảnh báo.
            saltPurityPercent: _parse(_saltPurity.text),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mineralDosingProvider);

    return DefaultTabController(
      length: 2,
      child: ProfileHubScaffold(
        title: 'PHA NƯỚC & LIỀU KHOÁNG',
        body: Column(
          children: [
            TabBar(
              labelColor: kHomePrimaryDark,
              unselectedLabelColor: kHomeTextSub,
              indicatorColor: kHomePrimaryDark,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              // Hai tab dùng chung một ô `error`; đổi tab thì dọn lỗi của tab cũ.
              onTap: (_) =>
                  ref.read(mineralDosingProvider.notifier).clearError(),
              tabs: const [
                Tab(text: '① Pha độ mặn', icon: Icon(Icons.grain_rounded, size: 18)),
                Tab(text: '② Liều Ca/Mg', icon: Icon(Icons.science_rounded, size: 18)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_salinityTab(state), _mineralTab(state)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab ①: PHA ĐỘ MẶN ───────────────────────────────────────────────────

  Widget _salinityTab(MineralDosingState state) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _salinityIntroCard(),
        const SizedBox(height: 14),
        _salinityWaterCard(),
        const SizedBox(height: 14),
        _saltCard(state.saltTypes),
        const SizedBox(height: 18),
        _mixButton(state.isMixing),
        if (state.error != null) ...[
          const SizedBox(height: 14),
          _errorCard(state.error!),
        ],
        if (state.salinityResult != null) ...[
          const SizedBox(height: 18),
          _salinityResultSection(state.salinityResult!),
        ],
      ],
    );
  }

  Widget _salinityIntroCard() => HubCard(
        child: Text(
          'Tính lượng muối cần thêm khi CẦN TĂNG độ mặn, hoặc lượng nước ngọt cần '
          'thêm khi CẦN GIẢM độ mặn.\n'
          'Đây là ước lượng: muối thô lẫn tạp và độ ẩm nên phải đo lại độ mặn sau khi '
          'hoà tan rồi hiệu chỉnh.',
          style: const TextStyle(
            color: Color(0xFF5A7184),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );

  Widget _salinityWaterCard() => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('NƯỚC HIỆN TẠI', Icons.water_rounded),
            const SizedBox(height: 12),
            _field(
              controller: _volume,
              label: 'Lượng nước',
              suffix: 'L',
              icon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _salinity,
              label: 'Độ mặn hiện tại (số đo thực)',
              suffix: '‰',
              icon: Icons.speed_rounded,
              // Nước đã trộn 50% nước biển + 50% nước ngọt thì nhập số ĐO ĐƯỢC,
              // không nhập tỷ lệ pha — tránh hai nguồn sự thật cho cùng một số.
              onChanged: _onSalinityChanged,
            ),
            const SizedBox(height: 14),
            _sectionTitle('ĐỘ MẶN MONG MUỐN', Icons.flag_outlined),
            const SizedBox(height: 12),
            _field(
              controller: _salinityTarget,
              label: 'Độ mặn mong muốn',
              suffix: '‰',
              icon: Icons.flag_outlined,
            ),
          ],
        ),
      );

  Widget _saltCard(List<SaltType> types) {
    final selected = _selectedSalt(types);

    return HubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('MUỐI SỬ DỤNG (chỉ khi cần TĂNG)', Icons.grain_rounded),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _saltKey(types),
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Loại muối',
              isDense: true,
              filled: true,
              fillColor: kHomeBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kHomeBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kHomeBorder),
              ),
            ),
            // Danh mục đến từ BE; chưa nạp xong thì vẫn phải chọn được nên có
            // sẵn một mục "muối thô" làm mặc định.
            items: _saltItems(types)
                .map((t) => DropdownMenuItem(value: t.key, child: Text(t.label)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _saltType = v);
            },
          ),
          if (selected != null && selected.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            _hintRow(Icons.info_outline_rounded, selected.note),
          ],
          const SizedBox(height: 10),
          _field(
            controller: _saltPurity,
            label: 'Độ tinh khiết (không biết thì ĐỂ TRỐNG)',
            suffix: '%',
            icon: Icons.percent_rounded,
            // Đổi số tinh khiết phải vẽ lại gợi ý bên dưới.
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            _parse(_saltPurity.text) == null
                ? 'Để trống: hệ thống tính theo 100% và coi đó là mức TỐI THIỂU. '
                    'Không tự đoán 90% cho muối thô — mỗi lô một khác.'
                : 'Dùng đúng số của lô muối đang có, không dùng số của lô khác.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: _parse(_saltPurity.text) == null
                  ? kHomeWarning
                  : kHomeTextSub,
            ),
          ),
        ],
      ),
    );
  }

  /// Danh mục chưa nạp xong thì chỉ có "muối thô" — vẫn phải bấm tính được ngay.
  List<SaltType> _saltItems(List<SaltType> types) => types.isEmpty
      ? const [
          SaltType(
            key: 'raw',
            label: 'Muối thô (muối biển phơi)',
            note: '',
          ),
        ]
      : types;

  SaltType? _selectedSalt(List<SaltType> types) {
    final items = _saltItems(types);
    for (final t in items) {
      if (t.key == _saltType) return t;
    }
    return items.first;
  }

  String _saltKey(List<SaltType> types) => _selectedSalt(types)?.key ?? 'raw';

  Widget _mixButton(bool loading) => SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: loading ? null : _calcSalinity,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.calculate_rounded),
          label: Text(loading ? 'Đang tính…' : 'TÍNH LƯỢNG MUỐI / NƯỚC NGỌT'),
          style: FilledButton.styleFrom(
            backgroundColor: kHomePrimaryDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );

  Widget _salinityResultSection(SalinityMixResult r) {
    if (r.direction == SalinityDirection.unknown) {
      return HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('CHƯA TÍNH ĐƯỢC', Icons.help_outline_rounded),
            const SizedBox(height: 10),
            for (final w in r.warnings) _hintRow(Icons.info_outline_rounded, w),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _directionCard(r),
        if (r.direction.needsSalt) ...[
          const SizedBox(height: 14),
          _saltResultCard(r),
        ],
        if (r.direction.needsFreshwater) ...[
          const SizedBox(height: 14),
          _freshwaterResultCard(r),
        ],
        const SizedBox(height: 14),
        _batchCard(r),
        if (r.instructions.isNotEmpty) ...[
          const SizedBox(height: 14),
          _instructionsCard(
            'CÁCH PHA ĐỀ XUẤT',
            r.instructions,
            Icons.format_list_numbered_rounded,
          ),
        ],
        if (r.nextSteps.isNotEmpty) ...[
          const SizedBox(height: 14),
          _instructionsCard(
            'LÀM GÌ TIẾP',
            r.nextSteps,
            Icons.arrow_forward_rounded,
          ),
        ],
        if (r.warnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          _warningsCard(r.warnings),
        ],
      ],
    );
  }

  Widget _directionCard(SalinityMixResult r) {
    final color = switch (r.direction) {
      SalinityDirection.increase => kHomeInfo,
      SalinityDirection.decrease => kHomeWarning,
      _ => kHomeTextSub,
    };
    return HubCard(
      child: Row(
        children: [
          Icon(Icons.compare_arrows_rounded, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KẾT QUẢ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: kHomePrimaryDark,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  r.directionLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt(r.currentSalinityPpt)}‰ → ${_fmt(r.targetSalinityPpt)}‰ '
                  '· ${_fmt(r.waterVolumeL)} L',
                  style: const TextStyle(fontSize: 12, color: kHomeTextSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tăng độ mặn: muối lý thuyết và muối thực tế theo độ tinh khiết.
  Widget _saltResultCard(SalinityMixResult r) => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('LƯỢNG MUỐI CẦN BỔ SUNG', Icons.grain_rounded),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: homeTileDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.actualSaltKg == null ? '—' : '≈ ${_fmt(r.actualSaltKg)} kg',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kHomePrimaryDark,
                    ),
                  ),
                  Text(
                    r.saltTypeLabel,
                    style: const TextStyle(fontSize: 12, color: kHomeTextSub),
                  ),
                  const Divider(height: 18, color: kHomeBorder),
                  _kvRow(
                    'Lý thuyết (100%)',
                    '${_fmt(r.theoreticalSaltKg)} kg',
                    badge: 'MỨC TỐI THIỂU',
                    badgeColor: kHomeTextSub,
                  ),
                  const SizedBox(height: 6),
                  _kvRow(
                    'Theo độ tinh khiết',
                    r.saltPurityPercent == null
                        ? 'Chưa biết — để trống'
                        : '${_fmt(r.saltPurityPercent)}%',
                    badge: r.purityAssumed ? 'TẠM TÍNH 100%' : 'BẠN NHẬP',
                    badgeColor: r.purityAssumed ? kHomeWarning : kHomeInfo,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// Giảm độ mặn: hai cách, nêu rõ cách nào làm tăng thể tích.
  Widget _freshwaterResultCard(SalinityMixResult r) => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('LƯỢNG NƯỚC NGỌT CẦN THÊM', Icons.water_drop_rounded),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: homeTileDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.freshwaterToAddL == null
                        ? '—'
                        : '${_fmt(r.freshwaterToAddL)} L',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kHomePrimaryDark,
                    ),
                  ),
                  Text(
                    'nước ngọt ĐÃ KHỬ CLO · tổng thể tích thành '
                    '${_fmt(r.finalVolumeL)} L',
                    style: const TextStyle(fontSize: 12, color: kHomeTextSub),
                  ),
                  const Divider(height: 18, color: kHomeBorder),
                  _kvRow(
                    'Hoặc thay nước',
                    '${_fmt(r.waterToReplaceL)} L',
                    badge: 'GIỮ NGUYÊN THỂ TÍCH',
                    badgeColor: kHomeInfo,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _batchCard(SalinityMixResult r) {
    if (r.batchCount <= 0) {
      return HubCard(
        child: _hintRow(
          Icons.check_circle_outline_rounded,
          r.direction == SalinityDirection.hold
              ? 'Độ mặn đã đạt mục tiêu — không cần thêm muối hay nước ngọt.'
              : 'Không cần chia lần.',
        ),
      );
    }

    final perBatch = r.direction.needsSalt
        ? '${_fmt(r.saltKgPerBatch)} kg muối'
        : '${_fmt(r.freshwaterLPerBatch)} L nước ngọt';

    return HubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CHIA NHỎ ĐỂ KHÔNG SỐC CUA', Icons.schedule_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${r.batchCount}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: kHomePrimaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'lần, mỗi lần $perBatch, cách nhau ≥ ${r.batchIntervalHours} giờ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kHomeTextMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mỗi lần đổi độ mặn không quá ${_fmt(r.maxChangePerBatchPpt)}‰. '
            'Đổi độ mặn là đổi áp suất thẩm thấu của cả bể — cua đang lột rất nhạy.',
            style: const TextStyle(fontSize: 11.5, color: kHomeTextSub),
          ),
        ],
      ),
    );
  }

  Widget _instructionsCard(String title, List<String> steps, IconData icon) =>
      HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(title, icon),
            const SizedBox(height: 10),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kHomePrimaryBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: kHomePrimaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: kHomeTextMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  // ── Tab ②: LIỀU KHOÁNG Ca/Mg ────────────────────────────────────────────

  Widget _mineralTab(MineralDosingState state) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _introCard(),
        const SizedBox(height: 14),
        _waterCard(),
        const SizedBox(height: 14),
        _targetCard(state.recommendation),
        const SizedBox(height: 14),
        _currentCard(),
        const SizedBox(height: 18),
        _calculateButton(state.isCalculating),
        if (state.error != null) ...[
          const SizedBox(height: 14),
          _errorCard(state.error!),
        ],
        if (state.result != null) ...[
          const SizedBox(height: 18),
          _resultSection(state.result!),
        ],
      ],
    );
  }

  // ── Nhập liệu ──────────────────────────────────────────────────────────

  Widget _introCard() => HubCard(
        child: Text(
          'Công cụ tính lượng CaCl₂·2H₂O 96% và MgCl₂·6H₂O 98,5% cần châm.\n'
          'Độ mặn chỉ dùng để CHỌN mục tiêu Ca/Mg — không dùng để tính gram.',
          style: const TextStyle(
            color: Color(0xFF5A7184),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );

  Widget _waterCard() => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('NƯỚC & ĐỘ MẶN', Icons.water_rounded),
            const SizedBox(height: 12),
            _field(
              controller: _volume,
              label: 'Thể tích nước',
              suffix: 'L',
              icon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _salinity,
              label: 'Độ mặn hiện tại',
              suffix: '‰',
              icon: Icons.grain_rounded,
              onChanged: _onSalinityChanged,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _salinityTarget,
              label: 'Độ mặn mong muốn',
              suffix: '‰',
              icon: Icons.flag_outlined,
            ),
          ],
        ),
      );

  Widget _targetCard(MineralTargetRecommendation? rec) {
    final auto = _mode == MineralTargetMode.auto;

    return HubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CA / MG MỤC TIÊU', Icons.flag_rounded),
          const SizedBox(height: 12),
          SegmentedButton<MineralTargetMode>(
            segments: const [
              ButtonSegment(
                value: MineralTargetMode.auto,
                label: Text('AUTO'),
                icon: Icon(Icons.auto_awesome_rounded, size: 16),
              ),
              ButtonSegment(
                value: MineralTargetMode.manual,
                label: Text('MANUAL'),
                icon: Icon(Icons.edit_rounded, size: 16),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            onSelectionChanged: (s) {
              // Đổi cách chọn mục tiêu ⇒ kết quả cũ không còn đúng nữa.
              ref.read(mineralDosingProvider.notifier).clearResult();
              setState(() => _mode = s.first);
            },
          ),
          const SizedBox(height: 12),
          _recommendationBox(rec, auto),

          if (!auto) ...[
            const SizedBox(height: 12),
            _field(
              controller: _caTarget,
              label: 'Ca mục tiêu',
              suffix: 'mg/L',
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _mgTarget,
              label: 'Mg mục tiêu',
              suffix: 'mg/L',
              icon: Icons.science_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _recommendationBox(MineralTargetRecommendation? rec, bool auto) {
    if (auto) {
      if (rec == null) {
        return _hintRow(
          Icons.info_outline_rounded,
          'Nhập độ mặn để xem mục tiêu đề xuất.',
        );
      }
      if (!rec.hasTargets) {
        return _hintRow(
          Icons.help_outline_rounded,
          rec.note.isEmpty ? 'Chưa đủ dữ liệu để đề xuất.' : rec.note,
        );
      }
    } else if (rec == null || !rec.hasTargets) {
      return _hintRow(
        Icons.edit_rounded,
        'Chế độ MANUAL: nhập Ca/Mg mục tiêu của bạn. Hệ thống không tự sửa.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: homeTileDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 15, color: kHomePrimaryDark),
              const SizedBox(width: 6),
              Text(
                auto ? 'MỤC TIÊU ĐỀ XUẤT THEO ĐỘ MẶN' : 'ĐỀ XUẤT ĐỂ THAM KHẢO',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: kHomePrimaryDark,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _kv('Ca', '${_fmt(rec.calciumMgL)} mg/L'),
              _kv('Mg', '${_fmt(rec.magnesiumMgL)} mg/L'),
              _kv('Tỷ lệ', rec.ratio ?? '—'),
              _kv('Tổng', '${_fmt(rec.totalMgL)} mg/L'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Đây là mục tiêu ĐỀ XUẤT, KHÔNG phải giá trị bắt buộc.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: kHomeTextSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentCard() => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('CA / MG HIỆN TẠI (TỪ TEST)', Icons.biotech_rounded),
            const SizedBox(height: 4),
            const Text(
              'Mg phải lấy từ test Mg. Hệ thống KHÔNG suy Mg từ Ca.',
              style: TextStyle(fontSize: 11, color: kHomeTextSub),
            ),
            const SizedBox(height: 12),
            _fieldWithFlag(
              controller: _caCurrent,
              label: 'Ca hiện tại',
              suffix: 'mg/L',
              isMeasured: _caMeasured,
              onFlag: (v) => setState(() => _caMeasured = v),
            ),
            const SizedBox(height: 12),
            _fieldWithFlag(
              controller: _mgCurrent,
              label: 'Mg hiện tại',
              suffix: 'mg/L',
              isMeasured: _mgMeasured,
              onFlag: (v) => setState(() => _mgMeasured = v),
            ),
          ],
        ),
      );

  Widget _calculateButton(bool loading) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: loading ? null : _calculate,
          style: FilledButton.styleFrom(
            backgroundColor: kHomePrimaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.calculate_rounded),
          label: Text(
            loading ? 'ĐANG TÍNH…' : 'TÍNH LIỀU',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      );

  // ── Kết quả ────────────────────────────────────────────────────────────

  Widget _resultSection(MineralDoseResult r) => Column(
        children: [
          _currentResultCard(r),
          const SizedBox(height: 14),
          _targetResultCard(r),
          const SizedBox(height: 14),
          _deficitCard(r),
          const SizedBox(height: 14),
          _doseCard(r),
          const SizedBox(height: 14),
          _splitPlanCard(r),
          const SizedBox(height: 14),
          _salinityCard(r),
          if (r.warnings.isNotEmpty) ...[
            const SizedBox(height: 14),
            _warningsCard(r.warnings),
          ],
        ],
      );

  Widget _currentResultCard(MineralDoseResult r) => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('1 · SỐ ĐÃ ĐO', Icons.fact_check_outlined),
            const SizedBox(height: 10),
            _sourceRow('Ca', r.calciumCurrentMgL, r.calciumCurrentSource),
            const SizedBox(height: 8),
            _sourceRow('Mg', r.magnesiumCurrentMgL, r.magnesiumCurrentSource),
            const SizedBox(height: 8),
            _kvRow(
              'Tổng Ca+Mg',
              r.calciumMagnesiumTotalCurrentMgL == null
                  ? 'Chưa tính được (thiếu số đo)'
                  : '${_fmt(r.calciumMagnesiumTotalCurrentMgL)} mg/L',
            ),
          ],
        ),
      );

  Widget _targetResultCard(MineralDoseResult r) => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('2 · MỤC TIÊU ÁP DỤNG', Icons.flag_rounded),
            const SizedBox(height: 10),
            _kvRow(
              'Ca mục tiêu',
              r.calciumTargetMgL == null
                  ? 'Chưa có'
                  : '${_fmt(r.calciumTargetMgL)} mg/L',
              badge: r.usedRecommendedTargets ? 'ĐỀ XUẤT' : 'BẠN NHẬP',
            ),
            const SizedBox(height: 8),
            _kvRow(
              'Mg mục tiêu',
              r.magnesiumTargetMgL == null
                  ? 'Chưa có'
                  : '${_fmt(r.magnesiumTargetMgL)} mg/L',
              badge: r.usedRecommendedTargets ? 'ĐỀ XUẤT' : 'BẠN NHẬP',
            ),
            const SizedBox(height: 8),
            _kvRow('Tỷ lệ Ca:Mg', r.recommendedCaMgRatio ?? '—'),
            const SizedBox(height: 8),
            _kvRow(
              'Tổng Ca+Mg',
              r.calciumMagnesiumTotalTargetMgL == null
                  ? '—'
                  : '${_fmt(r.calciumMagnesiumTotalTargetMgL)} mg/L',
            ),
          ],
        ),
      );

  Widget _deficitCard(MineralDoseResult r) => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('3 · CÒN THIẾU', Icons.trending_down_rounded),
            const SizedBox(height: 10),
            _deficitRow('Ca', r.calciumDeficitMgL, r.calciumMissing),
            const SizedBox(height: 8),
            _deficitRow('Mg', r.magnesiumDeficitMgL, r.magnesiumMissing),
          ],
        ),
      );

  Widget _deficitRow(String label, double? deficit, bool missing) {
    if (missing) {
      return _kvRow(
        label,
        label == 'Mg'
            ? 'Chưa đo Mg — cần test Mg'
            : 'Chưa đo $label — cần test',
        badge: 'THIẾU DỮ LIỆU',
        badgeColor: kHomeWarning,
      );
    }
    if (deficit == null) return _kvRow(label, '—');
    if (deficit < 0) {
      return _kvRow(
        label,
        'Vượt mục tiêu ${_fmt(deficit.abs())} mg/L',
        badge: 'KHÔNG CHÂM',
        badgeColor: kHomeWarning,
      );
    }
    if (deficit == 0) {
      return _kvRow(label, 'Đã đủ mục tiêu', badge: 'ĐỦ', badgeColor: kHomeInfo);
    }
    return _kvRow(label, '${_fmt(deficit)} mg/L');
  }

  Widget _doseCard(MineralDoseResult r) => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('4 · LIỀU HOÁ CHẤT', Icons.scale_rounded),
            const SizedBox(height: 10),
            _doseRow(
              product: r.caCl2Product.isEmpty ? 'CaCl₂·2H₂O 96%' : r.caCl2Product,
              grams: r.caCl2DoseGrams,
              missingNote: 'Chưa đo Ca — cần test Ca',
            ),
            const Divider(height: 22, color: kHomeBorder),
            _doseRow(
              product: r.mgCl2Product.isEmpty ? 'MgCl₂·6H₂O 98,5%' : r.mgCl2Product,
              grams: r.mgCl2DoseGrams,
              missingNote: 'Chưa thể tính chính xác — cần test Mg',
            ),
          ],
        ),
      );

  Widget _doseRow({
    required String product,
    required double? grams,
    required String missingNote,
  }) {
    final known = grams != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kHomeTextSub,
          ),
        ),
        const SizedBox(height: 4),
        if (!known)
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 18, color: kHomeWarning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  missingNote,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kHomeWarning,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _fmt(grams),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: grams > 0 ? kHomePrimaryDark : kHomeInfo,
                ),
              ),
              const SizedBox(width: 4),
              const Text('gram', style: TextStyle(fontSize: 13, color: kHomeTextSub)),
              if (grams == 0) ...[
                const SizedBox(width: 8),
                const Text(
                  '(đã đủ, không châm)',
                  style: TextStyle(fontSize: 12, color: kHomeInfo),
                ),
              ],
            ],
          ),
      ],
    );
  }

  /// Chia nhỏ liều + cách pha — để không sốc cua đang nuôi.
  Widget _splitPlanCard(MineralDoseResult r) {
    if (!r.needsDosing) {
      return HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('5 · CHIA LIỀU & CÁCH PHA', Icons.schedule_rounded),
            const SizedBox(height: 10),
            _hintRow(
              Icons.check_circle_outline_rounded,
              r.dosingInstructions.isNotEmpty
                  ? r.dosingInstructions.first
                  : 'Không cần châm: Ca/Mg đã đạt mục tiêu.',
            ),
          ],
        ),
      );
    }

    return HubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('5 · CHIA LIỀU & CÁCH PHA', Icons.schedule_rounded),
          const SizedBox(height: 12),

          // Con số chính: châm mấy lần, mỗi lần bao nhiêu.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: homeTileDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${r.doseCount}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: kHomePrimaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'lần châm, cách nhau ≥ 1 ngày',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kHomeTextMain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Mỗi lần tăng không quá ${_fmt(r.maxIncreasePerDoseMgL)} mg/L '
                  'để cua không bị sốc thẩm thấu.',
                  style: const TextStyle(fontSize: 11.5, color: kHomeTextSub),
                ),
                const Divider(height: 18, color: kHomeBorder),
                Row(
                  children: [
                    Expanded(
                      child: _kv(
                        'CaCl₂·2H₂O mỗi lần',
                        '${_fmt(r.caCl2GramsPerDose)} g',
                      ),
                    ),
                    Expanded(
                      child: _kv(
                        'MgCl₂·6H₂O mỗi lần',
                        '${_fmt(r.mgCl2GramsPerDose)} g',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'CÁC BƯỚC PHA & CHÂM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: kHomePrimaryDark,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < r.dosingInstructions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kHomePrimaryBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: kHomePrimaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.dosingInstructions[i],
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: kHomeTextMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _salinityCard(MineralDoseResult r) {
                final color = switch (r.salinityStatus) {
                  'SALINITY_OK' => kHomeInfo,
                  'SALINITY_LOW' || 'SALINITY_HIGH' => kHomeWarning,
                  // Có số nhưng thiếu mục tiêu — không phải lỗi, chỉ là chưa so sánh được.
                  'SALINITY_NO_TARGET' => kHomeTextMain,
                  _ => kHomeTextSub,
                };
    return HubCard(
      child: Row(
        children: [
          Icon(Icons.water_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐỘ MẶN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: kHomePrimaryDark,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                              r.salinityStatusLabel.isEmpty
                                  ? 'Chưa nhập độ mặn'
                                  : r.salinityStatusLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningsCard(List<String> warnings) => HubCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('CẢNH BÁO', Icons.warning_amber_rounded),
            const SizedBox(height: 10),
            for (final w in warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.circle,
                          size: 6, color: kHomeWarning),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: kHomeTextMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _errorCard(String message) => HubCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: kHomeDanger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.replaceFirst('Exception: ', ''),
                style: const TextStyle(fontSize: 13, color: kHomeDanger),
              ),
            ),
          ],
        ),
      );

  // ── Khối nhỏ dùng lại ──────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 17, color: kHomePrimaryDark),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: kHomePrimaryDark,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, size: 19),
          isDense: true,
          filled: true,
          fillColor: kHomeBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kHomeBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kHomeBorder),
          ),
        ),
      );

  Widget _fieldWithFlag({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required bool isMeasured,
    required ValueChanged<bool> onFlag,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(
            controller: controller,
            label: label,
            suffix: suffix,
            icon: Icons.science_outlined,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Switch(
                value: isMeasured,
                onChanged: onFlag,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isMeasured
                      ? 'Đây là kết quả TEST'
                      : 'Đây là số ƯỚC LƯỢNG — liều chỉ tham khảo',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isMeasured ? kHomeTextSub : kHomeWarning,
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _sourceRow(String label, double? value, ValueSource source) {
    final color = switch (source) {
      ValueSource.measured => kHomeInfo,
      ValueSource.estimated => kHomeWarning,
      ValueSource.missing => kHomeTextHint,
    };
    return _kvRow(
      label,
      value == null ? 'Chưa đo' : '${_fmt(value)} mg/L',
      badge: source.labelVi.toUpperCase(),
      badgeColor: color,
    );
  }

  Widget _kvRow(
    String label,
    String value, {
    String? badge,
    Color? badgeColor,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: kHomeTextSub),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: kHomeTextMain,
              ),
            ),
          ),
          if (badge != null) _badge(badge, badgeColor ?? kHomeInfo),
        ],
      );

  Widget _kv(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: kHomeTextSub),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: kHomeTextMain,
            ),
          ),
        ],
      );

  Widget _badge(String text, Color color) => Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _hintRow(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kHomeTextSub),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: kHomeTextSub),
            ),
          ),
        ],
      );

  /// `null` → "—" (chưa tính được), không hiển thị 0 gây hiểu nhầm.
  static String _fmt(double? v) {
    if (v == null) return '—';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.abs() < 10 ? v.toStringAsFixed(2) : v.toStringAsFixed(1);
  }
}