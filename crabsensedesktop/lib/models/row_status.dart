import 'farm_record.dart';

enum RowStatusFilter { all, active, suspended, closed }

extension RowStatusFilterX on RowStatusFilter {
  FarmStatus? get farmStatus => switch (this) {
        RowStatusFilter.all => null,
        RowStatusFilter.active => FarmStatus.active,
        RowStatusFilter.suspended => FarmStatus.suspended,
        RowStatusFilter.closed => FarmStatus.closed,
      };

  String get label => switch (this) {
        RowStatusFilter.all => 'Tất cả trạng thái',
        RowStatusFilter.active => '🟢 Hoạt động',
        RowStatusFilter.suspended => '🟡 Tạm ngưng',
        RowStatusFilter.closed => '🔴 Ngừng hoạt động',
      };
}
