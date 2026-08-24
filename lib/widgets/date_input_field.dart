import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Interactive Date Input Field that supports both manual text typing (e.g., DD/MM/YYYY)
/// and graphical date picker selection via calendar button.
class DateInputField extends StatefulWidget {
  final String label;
  final DateTime? dateValue;
  final ValueChanged<DateTime?> onDateChanged;
  final String hint;
  final bool isRequired;
  final bool isHighlighted;
  final bool allowClear;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateInputField({
    super.key,
    required this.label,
    required this.dateValue,
    required this.onDateChanged,
    this.hint = 'DD/MM/YYYY',
    this.isRequired = false,
    this.isHighlighted = false,
    this.allowClear = false,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late TextEditingController _controller;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  bool _isInternalChange = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.dateValue != null ? _dateFormat.format(widget.dateValue!) : '',
    );
  }

  @override
  void didUpdateWidget(covariant DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInternalChange && widget.dateValue != oldWidget.dateValue) {
      final newText = widget.dateValue != null ? _dateFormat.format(widget.dateValue!) : '';
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
    _isInternalChange = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String text) {
    text = text.trim();
    if (text.isEmpty) return null;

    // Standard Date Formats
    final formats = [
      DateFormat('dd/MM/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('d/M/yyyy'),
      DateFormat('d-M-yyyy'),
      DateFormat('dd.MM.yyyy'),
    ];

    for (final fmt in formats) {
      try {
        return fmt.parseStrict(text);
      } catch (_) {}
    }

    // 8-digit unbroken string DDMMYYYY
    if (RegExp(r'^\d{8}$').hasMatch(text)) {
      final day = int.tryParse(text.substring(0, 2));
      final month = int.tryParse(text.substring(2, 4));
      final year = int.tryParse(text.substring(4, 8));
      if (day != null && month != null && year != null) {
        try {
          final dt = DateTime(year, month, day);
          if (dt.day == day && dt.month == month && dt.year == year) {
            return dt;
          }
        } catch (_) {}
      }
    }

    // Custom Delimiter Split (DD/MM/YYYY or YYYY/MM/DD)
    final parts = text.split(RegExp(r'[/\.\-\s]+'));
    if (parts.length == 3) {
      int? p1 = int.tryParse(parts[0]);
      int? p2 = int.tryParse(parts[1]);
      int? p3 = int.tryParse(parts[2]);
      if (p1 != null && p2 != null && p3 != null) {
        int day, month, year;
        if (p1 > 1000) {
          year = p1; month = p2; day = p3;
        } else {
          day = p1; month = p2; year = p3;
        }
        try {
          final dt = DateTime(year, month, day);
          if (dt.day == day && dt.month == month && dt.year == year) {
            return dt;
          }
        } catch (_) {}
      }
    }

    return null;
  }

  void _onTextChanged(String text) {
    final parsed = _parseDate(text);
    if (parsed != null || text.trim().isEmpty) {
      _isInternalChange = true;
      widget.onDateChanged(parsed);
    }
  }

  Future<void> _selectDateFromPicker() async {
    final now = DateTime.now();
    final initial = widget.dateValue ?? now;
    final first = widget.firstDate ?? DateTime(2000);
    final last = widget.lastDate ?? DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      initialEntryMode: DatePickerEntryMode.calendar,
    );

    if (picked != null) {
      final formatted = _dateFormat.format(picked);
      _controller.text = formatted;
      _isInternalChange = true;
      widget.onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isHighlighted ? AppTheme.lightBlueBackground : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: 'Type date (DD/MM/YYYY) or tap calendar icon',
          prefixIcon: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.allowClear && _controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                  tooltip: 'Clear Date',
                  onPressed: () {
                    _controller.clear();
                    _isInternalChange = true;
                    widget.onDateChanged(null);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryBlue),
                tooltip: 'Select from Calendar',
                onPressed: _selectDateFromPicker,
              ),
            ],
          ),
        ),
        onChanged: _onTextChanged,
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (widget.isRequired && trimmed.isEmpty) {
            return 'Date is required (${widget.hint})';
          }
          if (trimmed.isNotEmpty && _parseDate(trimmed) == null) {
            return 'Invalid date format (Use DD/MM/YYYY)';
          }
          return null;
        },
      ),
    );
  }
}
