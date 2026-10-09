import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/scheduled_task_repository.dart';
import '../domain/models/scheduled_task.dart';
import 'widgets/task_plan_widgets.dart';

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
  final Map<String, DateTime> _completedAt = {};
  DateTime _selectedDate = taskDay(DateTime.now());
  TaskPlanFilter _filter = TaskPlanFilter.all;
  bool _loading = true;
  bool _error = false;

  String _key(DateTime day, String id) =>
      '${taskDay(day).toIso8601String().substring(0, 10)}|$id';

  List<ScheduledTask> _forDay(DateTime day) =>
      _tasks.where((t) => taskOccursOn(t, day)).toList();

  int _doneCount(DateTime day) =>
      _forDay(day).where((t) => _completedAt.containsKey(_key(day, t.id))).length;

  @override
  void initState() {
    super.initState();
    _repository = ScheduledTaskRepository(sl<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final tasks = await _repository.list();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = taskDay(picked));
  }

  void _toggleDone(ScheduledTask task) {
    final k = _key(_selectedDate, task.id);
    setState(() {
      if (_completedAt.containsKey(k)) {
        _completedAt.remove(k);
      } else {
        _completedAt[k] = DateTime.now();
      }
    });
  }

  Future<void> _delete(ScheduledTask task) async {
    await _repository.delete(task.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final dayTasks = _forDay(_selectedDate);
    final done = _doneCount(_selectedDate);
    final total = dayTasks.length;
    final pending = total - done;
    final visible = switch (_filter) {
      TaskPlanFilter.all => dayTasks,
      TaskPlanFilter.pending =>
        dayTasks.where((t) => !_completedAt.containsKey(_key(_selectedDate, t.id))).toList(),
      TaskPlanFilter.doing => const <ScheduledTask>[],
      TaskPlanFilter.done =>
        dayTasks.where((t) => _completedAt.containsKey(_key(_selectedDate, t.id))).toList(),
    };
    final weekStart = weekMonday(_selectedDate);
    final bottom = MediaQuery.paddingOf(context).bottom + 88;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF1),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TaskHeroHeader(onPickDate: _pickDate),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 0,
                    child: WeeklyTaskCalendar(
                      weekStart: weekStart,
                      selected: _selectedDate,
                      doneForDay: _doneCount,
                      totalForDay: (d) => _forDay(d).length,
                      onSelect: (d) => setState(() => _selectedDate = taskDay(d)),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, bottom),
              sliver: SliverToBoxAdapter(
                child: _loading
                    ? const TaskPlanSkeleton()
                    : _error
                        ? TaskPlanErrorCard(onRetry: _load)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TodayProgressHeader(
                                date: _selectedDate,
                                done: done,
                                total: total,
                              ),
                              const SizedBox(height: 14),
                              TaskSummarySection(
                                total: total,
                                pending: pending,
                                doing: 0,
                                done: done,
                                selected: _filter,
                                onSelect: (f) => setState(() => _filter = f),
                              ),
                              const SizedBox(height: 16),
                              if (visible.isEmpty)
                                TaskEmptyState(onAdd: _add)
                              else
                                ...visible.map(
                                  (task) => TaskPlanCard(
                                    task: task,
                                    completed: _completedAt.containsKey(
                                      _key(_selectedDate, task.id),
                                    ),
                                    completedAt: _completedAt[_key(
                                      _selectedDate,
                                      task.id,
                                    )],
                                    onToggleDone: () => _toggleDone(task),
                                    onDelete: () => _delete(task),
                                  ),
                                ),
                              if (total > 0 && done == total) ...[
                                const SizedBox(height: 8),
                                const DailyCompletionCard(),
                              ],
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: CrabSenseColors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
