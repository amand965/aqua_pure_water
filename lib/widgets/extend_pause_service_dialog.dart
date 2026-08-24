import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../theme/app_theme.dart';
import 'safe_tap.dart';

class ExtendPauseServiceDialog extends StatefulWidget {
  final Customer customer;

  const ExtendPauseServiceDialog({super.key, required this.customer});

  static Future<void> show(BuildContext context, Customer customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExtendPauseServiceDialog(customer: customer),
    );
  }

  @override
  State<ExtendPauseServiceDialog> createState() => _ExtendPauseServiceDialogState();
}

class _ExtendPauseServiceDialogState extends State<ExtendPauseServiceDialog> {
  // 'extend', 'pause', 'stop', 'resume'
  String _selectedAction = 'extend'; 
  int _selectedMonths = 1;
  
  final List<String> _reasonPresets = [
    'Customer call not answered',
    'Customer out of station',
    'Customer requested delay',
    'Payment / Renewal pending',
  ];
  
  late String _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isCustomReason = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasonPresets.first;
    if (widget.customer.amcStatus == 'Paused' || widget.customer.amcStatus == 'Stopped') {
      _selectedAction = 'resume';
    }
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSubmitting) return; // Prevent double-submit
    if (!SafeTap.canTap(1000)) return; // Debounce rapid multi-clicks

    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final reason = _isCustomReason 
        ? _customReasonController.text.trim() 
        : _selectedReason;

    if (_isCustomReason && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason for this action.'),
          backgroundColor: AppTheme.statusOverdue,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_selectedAction == 'extend') {
        await provider.extendCustomerService(widget.customer, _selectedMonths, reason);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service extended by $_selectedMonths month(s).'),
              backgroundColor: AppTheme.statusCompleted,
            ),
          );
        }
      } else if (_selectedAction == 'pause') {
        await provider.updateCustomerServiceStatus(widget.customer, 'Paused', reason: reason);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service schedule paused.'),
              backgroundColor: AppTheme.statusDueToday,
            ),
          );
        }
      } else if (_selectedAction == 'stop') {
        await provider.updateCustomerServiceStatus(widget.customer, 'Stopped', reason: reason);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service schedule stopped.'),
              backgroundColor: AppTheme.statusOverdue,
            ),
          );
        }
      } else if (_selectedAction == 'resume') {
        await provider.updateCustomerServiceStatus(widget.customer, 'Active', reason: 'Resumed service schedule');
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service schedule resumed to Active.'),
              backgroundColor: AppTheme.statusCompleted,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: AppTheme.statusOverdue,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currentNextStr = dateFormat.format(widget.customer.nextServiceDate);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 24.0,
        bottom: 24.0 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage Service Schedule',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${widget.customer.name} • Current Next: $currentNextStr',
                        style: const TextStyle(fontSize: 13.0, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Action Selection Tabs
            const Text(
              'Select Action:',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ChoiceChip(
                  label: const Text('Extend Service'),
                  avatar: const Icon(Icons.update_rounded, size: 18),
                  selected: _selectedAction == 'extend',
                  selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedAction = 'extend');
                  },
                ),
                ChoiceChip(
                  label: const Text('Pause Service'),
                  avatar: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                  selected: _selectedAction == 'pause',
                  selectedColor: AppTheme.statusDueToday.withOpacity(0.2),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedAction = 'pause');
                  },
                ),
                ChoiceChip(
                  label: const Text('Stop Service'),
                  avatar: const Icon(Icons.cancel_outlined, size: 18),
                  selected: _selectedAction == 'stop',
                  selectedColor: AppTheme.statusOverdue.withOpacity(0.2),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedAction = 'stop');
                  },
                ),
                if (widget.customer.amcStatus == 'Paused' || widget.customer.amcStatus == 'Stopped')
                  ChoiceChip(
                    label: const Text('Resume Active'),
                    avatar: const Icon(Icons.play_circle_outline_rounded, size: 18),
                    selected: _selectedAction == 'resume',
                    selectedColor: AppTheme.statusCompleted.withOpacity(0.2),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedAction = 'resume');
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Details for Extended Action
            if (_selectedAction == 'extend') ...[
              const Text(
                'Extend Period (Months):',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10.0),
              Row(
                children: [1, 2, 3, 4].map((m) {
                  final isSelected = _selectedMonths == m;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedMonths = m),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$m',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                m == 1 ? 'Month' : 'Months',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20.0),
            ],

            // Reason Section for Extend, Pause, or Stop
            if (_selectedAction != 'resume') ...[
              const Text(
                'Reason / Notes:',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: [
                  ..._reasonPresets.map((r) => FilterChip(
                        label: Text(r, style: const TextStyle(fontSize: 12)),
                        selected: !_isCustomReason && _selectedReason == r,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedReason = r;
                              _isCustomReason = false;
                            });
                          }
                        },
                      )),
                  FilterChip(
                    label: const Text('Other / Custom', style: TextStyle(fontSize: 12)),
                    selected: _isCustomReason,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _isCustomReason = true);
                      }
                    },
                  ),
                ],
              ),
              if (_isCustomReason) ...[
                const SizedBox(height: 12.0),
                TextField(
                  controller: _customReasonController,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason (e.g. Out of town till next month)...',
                  ),
                ),
              ],
              const SizedBox(height: 24.0),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSave,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _selectedAction == 'extend'
                                ? 'EXTEND SERVICE'
                                : _selectedAction == 'pause'
                                    ? 'PAUSE SERVICE'
                                    : _selectedAction == 'stop'
                                        ? 'STOP SERVICE'
                                        : 'RESUME SERVICE',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
