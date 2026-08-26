import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

const _dayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class DateTimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onConfirmed;

  const DateTimePickerSheet({
    super.key,
    required this.initialDateTime,
    required this.onConfirmed,
  });

  @override
  State<DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<DateTimePickerSheet> {
  late DateTime _selected;
  late DateTime _viewMonth;
  late ScrollController _hourScroll;
  late ScrollController _minuteScroll;

  static const double _cellSize = 42;
  static const double _timeItemHeight = 44;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDateTime;
    _viewMonth = DateTime(_selected.year, _selected.month);
    _hourScroll = FixedExtentScrollController(initialItem: _selected.hour);
    _minuteScroll = FixedExtentScrollController(initialItem: _selected.minute);
  }

  @override
  void dispose() {
    _hourScroll.dispose();
    _minuteScroll.dispose();
    super.dispose();
  }

  int get _daysInMonth => DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
  int get _firstWeekday => DateTime(_viewMonth.year, _viewMonth.month, 1).weekday;

  void _prevMonth() => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
  void _nextMonth() => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));

  void _pickDay(int day) {
    final now = DateTime.now();
    final picked = DateTime(_viewMonth.year, _viewMonth.month, day, _selected.hour, _selected.minute);
    if (picked.isAfter(now)) return;
    setState(() => _selected = picked);
  }

  void _pickNow() {
    final now = DateTime.now();
    setState(() {
      _selected = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      _viewMonth = DateTime(now.year, now.month);
    });
    (_hourScroll as FixedExtentScrollController).jumpToItem(_selected.hour);
    (_minuteScroll as FixedExtentScrollController).jumpToItem(_selected.minute);
  }

  void _confirm() {
    final hour = (_hourScroll as FixedExtentScrollController).selectedItem;
    final minute = (_minuteScroll as FixedExtentScrollController).selectedItem;
    final result = DateTime(_selected.year, _selected.month, _selected.day, hour, minute);
    widget.onConfirmed(result);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final now = DateTime.now();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          SizedBox(height: 8 + topPad * 0.15),
          _buildHandle(),
          const SizedBox(height: 12),
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildSelectedPreview(theme),
          const SizedBox(height: 16),
          _buildMonthNav(theme),
          const SizedBox(height: 8),
          _buildDayLabels(theme),
          const SizedBox(height: 4),
          _buildCalendarGrid(theme, now),
          const SizedBox(height: 16),
          _buildTimeSection(theme),
          const Spacer(),
          _buildConfirmButton(theme),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.secondaryText.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Fecha y Hora',
            style: theme.titleMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildPillButton(theme, 'Ahora', Icons.access_time, _pickNow),
        ],
      ),
    );
  }

  Widget _buildPillButton(AppThemeData theme, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.secondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.labelSmall.copyWith(
                color: theme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPreview(AppThemeData theme) {
    final day = _selected.day.toString().padLeft(2, '0');
    final month = _monthNames[_selected.month - 1];
    final year = _selected.year;
    final hour = _selected.hour.toString().padLeft(2, '0');
    final minute = _selected.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.secondary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 10),
          Text(
            '$day $month $year',
            style: theme.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          Icon(Icons.access_time, color: Colors.white.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 8),
          Text(
            '$hour:$minute',
            style: theme.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavArrow(theme, Icons.chevron_left, _prevMonth),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
              key: ValueKey('$_viewMonth'),
              style: theme.titleSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildNavArrow(theme, Icons.chevron_right, _nextMonth),
        ],
      ),
    );
  }

  Widget _buildNavArrow(AppThemeData theme, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.alternate,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.secondary, size: 22),
      ),
    );
  }

  Widget _buildDayLabels(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _dayLabels.map((d) {
          return Expanded(
            child: Center(
              child: Text(
                d,
                style: theme.labelSmall.copyWith(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(AppThemeData theme, DateTime now) {
    final totalCells = (_firstWeekday - 1) + _daysInMonth;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(totalCells, (i) {
          if (i < _firstWeekday - 1) {
            return SizedBox(width: _cellSize, height: _cellSize);
          }
          final day = i - (_firstWeekday - 1) + 1;
          final date = DateTime(_viewMonth.year, _viewMonth.month, day);
          final isToday = _isSameDay(date, now);
          final isSelected = _isSameDay(date, _selected);
          final isFuture = date.isAfter(now);

          return GestureDetector(
            onTap: isFuture ? null : () => _pickDay(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _cellSize,
              height: _cellSize,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.secondary
                    : isToday
                        ? theme.primary
                        : null,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: theme.secondary, width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: theme.secondary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isFuture
                            ? theme.secondaryText.withValues(alpha: 0.35)
                            : theme.primaryText,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeSection(AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: theme.secondary, size: 22),
          const SizedBox(width: 12),
          Text(
            'Hora',
            style: theme.bodyMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildTimeWheel(theme, _hourScroll, 24, true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: theme.titleLarge.copyWith(color: theme.secondary, fontWeight: FontWeight.bold)),
          ),
          _buildTimeWheel(theme, _minuteScroll, 60, false),
        ],
      ),
    );
  }

  Widget _buildTimeWheel(AppThemeData theme, ScrollController controller, int count, bool isHour) {
    return SizedBox(
      width: 52,
      height: _timeItemHeight * 3,
      child: ListWheelScrollView.useDelegate(
        controller: controller as FixedExtentScrollController,
        itemExtent: _timeItemHeight,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.5,
        perspective: 0.003,
        overAndUnderCenterOpacity: 0.4,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (ctx, i) {
            final isSelected = controller.selectedItem == i;
            return Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 22 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? theme.secondary : theme.secondaryText,
                ),
                child: Text(i.toString().padLeft(2, '0')),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConfirmButton(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.secondary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 2,
            shadowColor: theme.secondary.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 20),
              const SizedBox(width: 8),
              Text(
                'Confirmar',
                style: theme.labelLarge.copyWith(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

Future<void> showDateTimePickerSheet({
  required BuildContext context,
  required DateTime initialDateTime,
  required ValueChanged<DateTime> onConfirmed,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DateTimePickerSheet(
      initialDateTime: initialDateTime,
      onConfirmed: onConfirmed,
    ),
  );
}
