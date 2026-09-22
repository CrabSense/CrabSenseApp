import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/scheduled_task_repository.dart';
import '../domain/models/scheduled_task.dart';

class _TaskInput {
  const _TaskInput({
    required this.title,
    required this.date,
    required this.recurrence,
    required this.reminderMinuteOfDay,
  });

  final String title;
  final DateTime date;
  final String recurrence;
  final int reminderMinuteOfDay;
}

class _TaskInputDialog extends StatefulWidget {
  const _TaskInputDialog();

  @override
  State<_TaskInputDialog> createState() => _TaskInputDialogState();
}

class _TaskInputDialogState extends State<_TaskInputDialog> {
  final _title = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  String _recurrence = 'daily';

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .82,
      maxWidth: 380,
    ),
    backgroundColor: CrabSenseColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
    contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/background_chao_user.png',
            height: 82,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(height: 82),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Thêm việc cần làm',
          style: TextStyle(
            color: CrabSenseColors.primaryDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tạo công việc mới cho lịch trình trại nuôi của bạn',
          style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconField(
            Icons.assignment_outlined,
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tên việc *',
                hintText: 'Nhập tên việc cần làm...',
                filled: true,
                fillColor: CrabSenseColors.primaryMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CrabSenseColors.border),
                ),
              ),
            ),
          ),
          _iconField(
            Icons.layers_outlined,
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: InputDecoration(
                labelText: 'Loại việc',
                filled: true,
                fillColor: CrabSenseColors.primaryMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CrabSenseColors.border),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'once', child: Text('Một lần')),
                DropdownMenuItem(value: 'daily', child: Text('Mỗi ngày')),
                DropdownMenuItem(value: 'weekly', child: Text('Theo tuần')),
              ],
              onChanged: (value) =>
                  setState(() => _recurrence = value ?? 'daily'),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _iconField(
                  Icons.calendar_month_outlined,
                  _datePicker(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _iconField(
                  Icons.access_time_outlined,
                  _timePicker(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor: CrabSenseColors.teal,
          backgroundColor: CrabSenseColors.secondaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _TaskInput(
            title: _title.text.trim(),
            date: _date,
            recurrence: _recurrence,
            reminderMinuteOfDay: _time.hour * 60 + _time.minute,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: CrabSenseColors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text('Lưu'),
      ),
    ],
  );

  Widget _iconField(IconData icon, Widget child) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 14, right: 8),
        child: Icon(icon, color: CrabSenseColors.teal, size: 22),
      ),
      Expanded(child: child),
    ],
  );

  Widget _datePicker(BuildContext context) => InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDate: _date,
      );
      if (picked != null) setState(() => _date = picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Ngày bắt đầu',
        filled: true,
        fillColor: CrabSenseColors.primaryMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CrabSenseColors.border),
        ),
      ),
      child: Text('${_date.day}/${_date.month}/${_date.year}'),
    ),
  );

  Widget _timePicker(BuildContext context) => InkWell(
    onTap: () async {
      final picked = await showTimePicker(context: context, initialTime: _time);
      if (picked != null) setState(() => _time = picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Giờ nhắc',
        filled: true,
        fillColor: CrabSenseColors.primaryMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CrabSenseColors.border),
        ),
      ),
      child: Text(_time.format(context)),
    ),
  );

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }
}

class _StableTaskDialog extends StatefulWidget {
  const _StableTaskDialog();

  @override
  State<_StableTaskDialog> createState() => _StableTaskDialogState();
}

class _StableTaskDialogState extends State<_StableTaskDialog> {
  final _title = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  String _recurrence = 'daily';

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: SizedBox(
      width: 340,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/background_chao_user.png',
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 84),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Thêm việc cần làm',
              style: TextStyle(
                color: CrabSenseColors.primaryDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tạo công việc mới cho lịch trình trại nuôi của bạn',
              style: TextStyle(color: CrabSenseColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tên việc *',
                hintText: 'Nhập tên việc cần làm...',
                filled: true,
                fillColor: CrabSenseColors.primaryMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CrabSenseColors.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: InputDecoration(
                labelText: 'Loại việc',
                filled: true,
                fillColor: CrabSenseColors.primaryMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CrabSenseColors.border),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'once', child: Text('Một lần')),
                DropdownMenuItem(value: 'daily', child: Text('Mỗi ngày')),
                DropdownMenuItem(value: 'weekly', child: Text('Theo tuần')),
              ],
              onChanged: (value) =>
                  setState(() => _recurrence = value ?? 'daily'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _picker(
                    label: 'Ngày bắt đầu',
                    value: '${_date.day}/${_date.month}/${_date.year}',
                    icon: Icons.calendar_month_outlined,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _picker(
                    label: 'Giờ nhắc',
                    value: _time.format(context),
                    icon: Icons.access_time_outlined,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Hủy'),
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Lưu'),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _picker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: CrabSenseColors.teal),
        filled: true,
        fillColor: CrabSenseColors.primaryMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CrabSenseColors.border),
        ),
      ),
      child: Text(value),
    ),
  );

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time != null) setState(() => _time = time);
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      _TaskInput(
        title: _title.text.trim(),
        date: _date,
        recurrence: _recurrence,
        reminderMinuteOfDay: _time.hour * 60 + _time.minute,
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }
}

class ScheduledTasksScreen extends StatefulWidget {
  const ScheduledTasksScreen({super.key});

  @override
  State<ScheduledTasksScreen> createState() => _ScheduledTasksScreenState();
}

class _ScheduledTasksScreenState extends State<ScheduledTasksScreen> {
  late final ScheduledTaskRepository _repository;
  List<ScheduledTask> _tasks = const [];
  final Map<String, Set<String>> _completedByDay = <String, Set<String>>{};
  int _selectedDay = 0;
  bool _loading = true;

  DateTime get _selectedDate => DateTime.now()
      .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)
      .add(Duration(days: _selectedDay));

  Set<String> get _completedIds => _completedByDay.putIfAbsent(
        _selectedDate.toIso8601String().substring(0, 10),
        () => <String>{},
      );

  @override
  void initState() {
    super.initState();
    _repository = ScheduledTaskRepository(sl<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    try {
      final tasks = await _repository.list();
      if (mounted) {
        setState(() => _tasks = tasks.isEmpty ? _sampleTasks : tasks);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final input = await showDialog<_TaskInput>(
      context: context,
      builder: (_) => const _StableTaskDialog(),
    );
    if (input == null || input.title.isEmpty) return;
    await _repository.create(
      ScheduledTask(
        id: '',
        title: input.title,
        recurrenceType: input.recurrence,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
        startDate: input.date,
        reminderMinuteOfDay: input.reminderMinuteOfDay,
        isEnabled: true,
      ),
    );
    await _load();
  }

  void _openAddDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _add();
    });
  }

  List<ScheduledTask> get _sampleTasks => [
    ScheduledTask(
      id: 'sample-feeding',
      title: 'Kiểm tra và cho ăn định kỳ',
      description: 'Theo dõi lượng ăn của từng hộp',
      recurrenceType: 'daily',
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      startDate: DateTime.now(),
      reminderMinuteOfDay: 420,
      isEnabled: true,
    ),
    ScheduledTask(
      id: 'sample-water',
      title: 'Kiểm tra chất lượng nước',
      description: 'Đo pH, độ mặn và NO2/NO3',
      recurrenceType: 'weekly',
      daysOfWeek: const [1, 4, 7],
      startDate: DateTime.now(),
      reminderMinuteOfDay: 900,
      isEnabled: true,
    ),
    ScheduledTask(
      id: 'sample-box',
      title: 'Chăm sóc và kiểm tra hộp',
      description: 'Kiểm tra cua yếu, lột xác và hộp trống',
      recurrenceType: 'daily',
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      startDate: DateTime.now(),
      reminderMinuteOfDay: 1080,
      isEnabled: false,
    ),
  ];

  Widget _taskCard(ScheduledTask task) {
    final hour = task.reminderMinuteOfDay ~/ 60;
    final minute = (task.reminderMinuteOfDay % 60).toString().padLeft(2, '0');
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withValues(alpha: .88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: CrabSenseColors.primaryMuted,
          child: Icon(_taskIcon(task), color: CrabSenseColors.teal),
        ),
        title: Text(
          task.title,
          style: const TextStyle(
            color: CrabSenseColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${task.recurrenceType == 'daily' ? 'Mỗi ngày' : 'Theo tuần'} • $hour:$minute',
          style: const TextStyle(color: CrabSenseColors.textSecondary),
        ),
        trailing: Checkbox(
          value: _completedIds.contains(task.id),
          activeColor: CrabSenseColors.teal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _completedIds.add(task.id);
              } else {
                _completedIds.remove(task.id);
              }
            });
          },
        ),
      ),
    );
  }

  IconData _taskIcon(ScheduledTask task) {
    if (task.title.toLowerCase().contains('nước')) {
      return Icons.water_drop_outlined;
    }
    if (task.title.toLowerCase().contains('hộp')) {
      return Icons.grid_view_rounded;
    }
    return Icons.restaurant_outlined;
  }

  Widget _dateStrip() => SizedBox(
    height: 62,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (var i = 0; i < 7; i++)
          Container(
            width: 55,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: i == _selectedDay ? CrabSenseColors.teal : Colors.white70,
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedDay = i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][i],
                    style: TextStyle(
                      color: i == _selectedDay
                          ? Colors.white
                          : CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${DateTime.now().day + i}/${DateTime.now().month}',
                    style: TextStyle(
                      color: i == _selectedDay
                          ? Colors.white
                          : CrabSenseColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CrabSenseColors.background,
    appBar: AppBar(
      backgroundColor: CrabSenseColors.headerBg,
      foregroundColor: Colors.white,
      title: const Text('Kế hoạch việc cần làm'),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/background_chao_user.png',
                          fit: BoxFit.cover,
                        ),
                        const Positioned(
                          left: 18,
                          top: 28,
                          child: Text(
                            'Làm việc đúng kế hoạch\nTrại cua hiệu quả hơn',
                            style: TextStyle(
                              color: CrabSenseColors.primaryDark,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _dateStrip(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Hôm nay',
                      style: TextStyle(
                        color: CrabSenseColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Thứ 2, 21/9/2026',
                      style: TextStyle(
                        color: CrabSenseColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_completedIds.length}/${_tasks.length} đã hoàn thành',
                      style: const TextStyle(
                        color: CrabSenseColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_tasks.isEmpty)
                  const Center(child: Text('Chưa có việc cần làm'))
                else
                  ..._tasks.map(_taskCard),
              ],
            ),
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: _openAddDialog,
      backgroundColor: CrabSenseColors.teal,
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );

}
