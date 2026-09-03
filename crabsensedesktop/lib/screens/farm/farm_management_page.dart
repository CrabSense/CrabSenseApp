import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_record.dart';
import '../../services/farm_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/farm/farm_dialogs.dart';

class FarmManagementPage extends StatefulWidget {
  const FarmManagementPage({
    super.key,
    required this.service,
    this.onFarmsChanged,
  });

  final FarmManagementService service;
  final VoidCallback? onFarmsChanged;

  @override
  State<FarmManagementPage> createState() => _FarmManagementPageState();
}

class _FarmManagementPageState extends State<FarmManagementPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    if (widget.service.farms.isEmpty && !widget.service.loading) {
      widget.service.load();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final items = svc.filteredFarms;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý trại',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      svc.canManageFarms
                          ? 'Khu nuôi (FarmingArea) trên CrabSenseBE — chủ trại được thêm, sửa, xóa.'
                          : 'Xem các khu nuôi được gán cho tài khoản.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (svc.canManageFarms)
                FilledButton.icon(
                  onPressed: svc.loading
                      ? null
                      : () async {
                          await showCreateFarmDialog(context, svc);
                          widget.onFarmsChanged?.call();
                        },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm trại'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              IconButton(
                onPressed: svc.loading
                    ? null
                    : () async {
                        await svc.load();
                        widget.onFarmsChanged?.call();
                      },
                tooltip: 'Tải lại',
                icon: Icon(Icons.refresh, color: DashboardColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                svc.error!,
                style: GoogleFonts.notoSans(color: DashboardColors.risk),
              ),
            ),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Danh sách trại (${items.length})',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (svc.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Chưa có trại nào.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                    ),
                  )
                else
                  _FarmTable(
                    farms: items,
                    isOrgAdmin: svc.canManageFarms,
                    onEdit: (farm) async {
                      await showEditFarmDialog(context, svc, farm);
                      widget.onFarmsChanged?.call();
                    },
                    onDelete: svc.canManageFarms
                        ? (farm) async {
                            await showDeleteFarmDialog(context, svc, farm);
                            widget.onFarmsChanged?.call();
                          }
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmTable extends StatelessWidget {
  const _FarmTable({
    required this.farms,
    required this.isOrgAdmin,
    required this.onEdit,
    this.onDelete,
  });

  final List<FarmRecord> farms;
  final bool isOrgAdmin;
  final void Function(FarmRecord farm) onEdit;
  final void Function(FarmRecord farm)? onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: GoogleFonts.notoSans(
          color: DashboardColors.textPrimary,
          fontSize: 13,
        ),
        columns: const [
          DataColumn(label: Text('Mã')),
          DataColumn(label: Text('Tên trại')),
          DataColumn(label: Text('Địa chỉ')),
          DataColumn(label: Text('Mô tả')),
          DataColumn(label: Text('')),
        ],
        rows: farms.map((f) {
          return DataRow(cells: [
            DataCell(Text(f.code)),
            DataCell(Text(f.name)),
            DataCell(Text(f.address ?? '—')),
            DataCell(
              SizedBox(
                width: 200,
                child: Text(
                  f.description ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Sửa',
                  onPressed: () => onEdit(f),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => onDelete!(f),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: DashboardColors.risk.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
