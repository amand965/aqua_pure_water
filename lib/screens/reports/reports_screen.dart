import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/service_record.dart';
import '../../models/customer.dart';
import '../customer/customer_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'All'; // 'All', 'Free Service', 'Paid', 'Pending'
  String _timeRange = 'This Month'; // 'This Month', 'All Time'
  String _sortOrder = 'date_desc'; // 'date_desc', 'date_asc', 'amount_desc', 'amount_asc'

  String get _sortLabel {
    switch (_sortOrder) {
      case 'date_asc':
        return 'Date: Oldest First';
      case 'amount_desc':
        return 'Amount: Highest First';
      case 'amount_asc':
        return 'Amount: Lowest First';
      case 'date_desc':
      default:
        return 'Date: Newest First';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    // Calculations
    final today = DateTime.now();
    
    // 1. Completed services this month and all time
    final completedMonth = provider.completedServicesThisMonth;
    final allCompleted = provider.allServices.isNotEmpty ? provider.allServices : completedMonth;
    
    // 2. Completed services today
    final completedToday = completedMonth.where((s) => _isSameDay(s.serviceDate, today)).toList();

    // Summing collections
    final double totalMonthCollection = completedMonth.fold(0.0, (sum, item) => sum + item.charges);
    final double totalTodayCollection = completedToday.fold(0.0, (sum, item) => sum + item.charges);

    // Lists for customer reports
    final totalCustomersCount = provider.customers.length;
    final pendingCustomers = provider.overdueCustomers;
    final upcomingCustomers = provider.upcomingCustomers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Pending (Due)'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Completed Services Tab
          _buildCompletedServicesTab(completedToday, completedMonth, allCompleted, totalTodayCollection, totalMonthCollection, dateFormat),

          // Pending Services Tab
          _buildCustomerReportsTab(context, pendingCustomers, 'Pending Services (Overdue)', 'No pending services overdue. All caught up!', AppTheme.statusCompleted),

          // Upcoming Services Tab
          _buildCustomerReportsTab(context, upcomingCustomers, 'Upcoming Services (Next 30 Days)', 'No upcoming services in the next 30 days.', AppTheme.statusUpcoming),
        ],
      ),
    );
  }

  // Beautiful completed services report tab
  Widget _buildCompletedServicesTab(
    List<ServiceRecord> completedToday,
    List<ServiceRecord> completedMonth,
    List<ServiceRecord> allCompleted,
    double todayColl,
    double monthColl,
    DateFormat dateFormat,
  ) {
    final scopedServices = _timeRange == 'This Month' ? completedMonth : allCompleted;

    // Scoped counts for filter chips
    final allScopedCount = scopedServices.length;
    final freeScopedCount = scopedServices.where((s) => s.paymentStatus == 'Free Service' || (s.charges == 0.0 && s.paymentStatus.toLowerCase().contains('free'))).length;
    final paidScopedCount = scopedServices.where((s) => s.paymentStatus == 'Paid').length;
    final pendingScopedCount = scopedServices.where((s) => s.paymentStatus == 'Pending').length;

    // Free services summary numbers
    final freeThisMonth = completedMonth.where((s) => s.paymentStatus == 'Free Service' || (s.charges == 0.0 && s.paymentStatus.toLowerCase().contains('free'))).length;
    final freeAllTime = allCompleted.where((s) => s.paymentStatus == 'Free Service' || (s.charges == 0.0 && s.paymentStatus.toLowerCase().contains('free'))).length;

    // Filtered list to display
    final filteredServices = scopedServices.where((s) {
      if (_statusFilter == 'All') return true;
      if (_statusFilter == 'Free Service') {
        return s.paymentStatus == 'Free Service' || (s.charges == 0.0 && s.paymentStatus.toLowerCase().contains('free'));
      }
      return s.paymentStatus == _statusFilter;
    }).toList();

    // Apply Sorting
    if (_sortOrder == 'date_desc') {
      filteredServices.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    } else if (_sortOrder == 'date_asc') {
      filteredServices.sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
    } else if (_sortOrder == 'amount_desc') {
      filteredServices.sort((a, b) => b.charges.compareTo(a.charges));
    } else if (_sortOrder == 'amount_asc') {
      filteredServices.sort((a, b) => a.charges.compareTo(b.charges));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collection Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _buildCollectionCard(
                  title: "Completed Today",
                  count: completedToday.length,
                  collection: todayColl,
                  color: AppTheme.statusCompleted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCollectionCard(
                  title: "Revenue (Month)",
                  count: completedMonth.length,
                  collection: monthColl,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Dedicated Free Services Summary Card (Graphically Rich)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.statusFree.withOpacity(0.15),
                  AppTheme.statusFree.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.statusFree.withOpacity(0.28), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.statusFree.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppTheme.statusFree.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.statusFree.withOpacity(0.3), width: 1.2),
                    ),
                    child: const Icon(Icons.handshake_rounded, color: AppTheme.statusFree, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free Services Done',
                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: AppTheme.statusFree),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$freeAllTime All-Time',
                              style: const TextStyle(fontSize: 19.0, fontWeight: FontWeight.w800, color: AppTheme.statusFree),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($freeThisMonth this month)',
                              style: const TextStyle(fontSize: 12.0, color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.statusFree,
                      backgroundColor: AppTheme.statusFree.withOpacity(0.10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        _statusFilter = 'Free Service';
                        _timeRange = 'All Time';
                      });
                    },
                    icon: const Icon(Icons.filter_list_rounded, size: 16),
                    label: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Header Row with Time Range selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _timeRange == 'This Month' ? 'Completed (This Month)' : 'Completed (All Time)',
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeRangeToggle('This Month'),
                    _buildTimeRangeToggle('All Time'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', allScopedCount),
                const SizedBox(width: 8),
                _buildFilterChip('Free Service', freeScopedCount, color: AppTheme.statusFree),
                const SizedBox(width: 8),
                _buildFilterChip('Paid', paidScopedCount, color: AppTheme.statusCompleted),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', pendingScopedCount, color: AppTheme.statusOverdue),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Sort By Bar & Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filteredServices.length} service(s)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              PopupMenuButton<String>(
                initialValue: _sortOrder,
                tooltip: 'Sort Options',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  setState(() {
                    _sortOrder = val;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'date_desc',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward_rounded, size: 18, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text('Date: Newest First', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'date_asc',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 18, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text('Date: Oldest First', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'amount_desc',
                    child: Row(
                      children: [
                        Icon(Icons.trending_down_rounded, size: 18, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text('Amount: Highest First', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'amount_asc',
                    child: Row(
                      children: [
                        Icon(Icons.trending_up_rounded, size: 18, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text('Amount: Lowest First', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.35), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort_rounded, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        _sortLabel,
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Monthly / All-Time list
          filteredServices.isEmpty
              ? _buildEmptyState(
                  Icons.history_toggle_off_rounded,
                  _statusFilter == 'Free Service'
                      ? 'No free services recorded for $_timeRange.'
                      : 'No services found for $_statusFilter ($_timeRange).',
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    // Retrieve customer name from ID
                    final provider = Provider.of<CustomerProvider>(context, listen: false);
                    final customerMatch = provider.customers.where((c) => c.id == service.customerId);
                    final customerName = customerMatch.isNotEmpty ? customerMatch.first.name : 'Unknown Customer';

                    return _buildCompletedServiceCard(context, service, customerName, dateFormat);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeToggle(String label) {
    final isSelected = _timeRange == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _timeRange = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {Color? color}) {
    final isSelected = _statusFilter == label;
    final chipColor = color ?? AppTheme.primaryBlue;

    return FilterChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      selectedColor: chipColor,
      backgroundColor: chipColor.withOpacity(0.08),
      side: BorderSide(
        color: isSelected ? chipColor : chipColor.withOpacity(0.3),
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      checkmarkColor: Colors.white,
      onSelected: (val) {
        setState(() {
          _statusFilter = label;
        });
      },
    );
  }

  Widget _buildCollectionCard({
    required String title,
    required int count,
    required double collection,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.14),
            color.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.24), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: color.withOpacity(0.9))),
            const SizedBox(height: 8.0),
            Text(
              '₹ ${collection.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 21.0, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.4),
            ),
            const SizedBox(height: 4.0),
            Text(
              '$count job(s) completed',
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteService(BuildContext context, ServiceRecord service, String customerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Service Entry?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to delete the completed service record of ₹${service.charges.toStringAsFixed(0)} for $customerName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusOverdue),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<CustomerProvider>(context, listen: false);
              await provider.deleteServiceRecord(service.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service record deleted'),
                    backgroundColor: AppTheme.statusCompleted,
                  ),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedServiceCard(
    BuildContext context, 
    ServiceRecord service, 
    String customerName, 
    DateFormat dateFormat,
  ) {
    final isFree = service.paymentStatus == 'Free Service' || (service.charges == 0.0 && service.paymentStatus.toLowerCase().contains('free'));
    final isPaid = service.paymentStatus == 'Paid';
    final Color badgeColor = isPaid
        ? AppTheme.statusCompleted
        : (isFree ? AppTheme.statusFree : AppTheme.statusOverdue);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withOpacity(0.18), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          isFree ? 'FREE SERVICE' : service.paymentStatus.toUpperCase(),
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      isFree ? '₹ 0 (Free)' : '₹ ${service.charges.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: isFree ? AppTheme.statusFree : AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete Record',
                      onPressed: () => _confirmDeleteService(context, service, customerName),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: ${dateFormat.format(service.serviceDate)}', style: const TextStyle(fontSize: 12.0, color: Colors.black54)),
                Text('By: ${service.technicianName}', style: const TextStyle(fontSize: 12.0, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Work: ${service.workDone}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.0, color: Colors.black87),
            ),
            if (service.partsReplaced.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Parts changed: ${service.partsReplaced}',
                style: const TextStyle(fontSize: 11.0, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Pending and Upcoming lists helper tab builder
  Widget _buildCustomerReportsTab(
    BuildContext context,
    List<Customer> customers,
    String heading,
    String emptyMsg,
    Color color,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                heading,
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${customers.length}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )
            ],
          ),
          const SizedBox(height: 16.0),

          customers.isEmpty
              ? _buildEmptyState(Icons.people_outline_rounded, emptyMsg)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.lightBlueBackground,
                          child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
                        ),
                        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${customer.productBrand} (${customer.productModel})\n${customer.address}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailsScreen(customerId: customer.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
