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
    
    // 1. Completed services this month
    final completedMonth = provider.completedServicesThisMonth;
    
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
          _buildCompletedServicesTab(completedToday, completedMonth, totalTodayCollection, totalMonthCollection, dateFormat),

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
    double todayColl,
    double monthColl,
    DateFormat dateFormat,
  ) {
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
                  title: "Completed (Month)",
                  count: completedMonth.length,
                  collection: monthColl,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // Monthly list title
          const Text(
            'Completed Services This Month',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12.0),

          completedMonth.isEmpty
              ? _buildEmptyState(Icons.history_toggle_off_rounded, 'No services logged completed this month.')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedMonth.length,
                  itemBuilder: (context, index) {
                    final service = completedMonth[index];
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

  Widget _buildCollectionCard({
    required String title,
    required int count,
    required double collection,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
            const SizedBox(height: 8.0),
            Text(
              '₹ ${collection.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4.0),
            Text(
              '$count job(s) completed',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedServiceCard(
    BuildContext context, 
    ServiceRecord service, 
    String customerName, 
    DateFormat dateFormat,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                ),
                Text(
                  '₹ ${service.charges.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
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
