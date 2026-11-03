import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';

/// What the calendar sheet returns: a chosen range, or "clear the dates".
class RangeCalendarResult {
  const RangeCalendarResult.apply(this.range) : cleared = false;
  const RangeCalendarResult.clear()
      : range = null,
        cleared = true;

  final DateTimeRange? range;
  final bool cleared;
}

/// Opens a small calendar in a bottom sheet to pick a date range.
/// Returns null when the sheet is closed without choosing.
Future<RangeCalendarResult?> showRangeCalendarSheet(
  BuildContext context, {
  DateTimeRange? initial,
}) {
  return showModalBottomSheet<RangeCalendarResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SellerFormTheme(child: _RangeCalendarSheet(initial: initial)),
  );
}

class _RangeCalendarSheet extends StatefulWidget {
  const _RangeCalendarSheet({this.initial});

  final DateTimeRange? initial;

  @override
  State<_RangeCalendarSheet> createState() => _RangeCalendarSheetState();
}

class _RangeCalendarSheetState extends State<_RangeCalendarSheet> {
  static final _fmt = DateFormat('dd MMM yyyy');

  final DateTime _first = DateTime.utc(2020, 1, 1);
  late final DateTime _last;
  DateTime _focused = DateTime.now();
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _last = DateTime.utc(now.year, now.month, now.day);

    final r = widget.initial;
    if (r != null) {
      _start = DateTime.utc(r.start.year, r.start.month, r.start.day);
      _end = DateTime.utc(r.end.year, r.end.month, r.end.day);
      _focused = _end!;
    }
    // The focused day must stay inside the allowed days.
    if (_focused.isAfter(_last)) _focused = _last;
  }

  void _preset(int days) {
    setState(() {
      _end = _last;
      _start = _last.subtract(Duration(days: days - 1));
      _focused = _last;
    });
  }

  String get _summary {
    final s = _start;
    if (s == null) return 'Select a start date and an end date';
    final e = _end;
    if (e == null || e == s) return _fmt.format(s);
    return '${_fmt.format(s)} - ${_fmt.format(e)}';
  }

  void _apply() {
    final s = _start;
    if (s == null) return;
    final e = _end ?? s;
    Navigator.of(context).pop(
      RangeCalendarResult.apply(
        DateTimeRange(
          start: DateTime(s.year, s.month, s.day),
          // The whole last day is included.
          end: DateTime(e.year, e.month, e.day, 23, 59, 59),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final dayText = TextStyle(fontSize: 13, color: colors.onSurface);
    final rangeEdgeText = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: colors.onPrimary,
    );
    final weekdayText = TextStyle(
      fontSize: 11.5,
      color: colors.onSurfaceVariant,
    );

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTheme.r2xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Select dates', style: context.text.headlineSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Today'),
                    onPressed: () => _preset(1),
                  ),
                  ActionChip(
                    label: const Text('Last 7 days'),
                    onPressed: () => _preset(7),
                  ),
                  ActionChip(
                    label: const Text('Last 30 days'),
                    onPressed: () => _preset(30),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppTheme.r2xl),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: TableCalendar<void>(
                  firstDay: _first,
                  lastDay: _last,
                  focusedDay: _focused,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  rangeSelectionMode: RangeSelectionMode.toggledOn,
                  rangeStartDay: _start,
                  rangeEndDay: _end,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  rowHeight: 38,
                  daysOfWeekHeight: 28,
                  onRangeSelected: (start, end, focused) {
                    setState(() {
                      _start = start;
                      _end = end;
                      _focused = focused;
                    });
                  },
                  onPageChanged: (focused) => _focused = focused,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                    headerPadding: const EdgeInsets.symmetric(vertical: 4),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: colors.onSurface,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: colors.onSurface,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: weekdayText,
                    weekendStyle: weekdayText,
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(3),
                    defaultTextStyle: dayText,
                    weekendTextStyle: dayText,
                    withinRangeTextStyle: dayText,
                    disabledTextStyle: dayText.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    todayDecoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: dayText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    rangeStartDecoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeEndDecoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeStartTextStyle: rangeEdgeText,
                    rangeEndTextStyle: rangeEdgeText,
                    rangeHighlightColor: colors.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _summary,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context)
                          .pop(const RangeCalendarResult.clear()),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _start == null ? null : _apply,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}