import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../customer/customer_details_screen.dart';
import '../service/add_service_screen.dart';

class DueServicesScreen extends StatefulWidget {
  final int initialIndex; // 0: Today, 1: Upcoming, 2: Overdue

  const DueServicesScreen({super.key, this.initialIndex = 0});

  @override
  State<DueServicesScreen> createState() => _DueServicesScreenState();
}

class _DueServicesScreenState extends State<DueServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchCall(BuildContext context, String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse("tel:$cleanMobile");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Cannot make phone call.';
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Could not launch dialer.');
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String mobile, String customerName) async {
    String cleanNumber = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    final message = "Hello $customerName,\n\n"
        "This is Meet Electronics.\n"
        "Your RO water purifier service is due.\n"
        "Please reply to this message or call us to schedule your service.\n\n"
        "Thank you.";

    final url = Uri.parse("https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar(context, 'Could not launch WhatsApp.');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.statusOverdue),
    );
  }

  int _calculateDaysDiff(DateTime date) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfTarget = DateTime(date.year, date.month, date.day);
    return startOfTarget.difference(startOfToday).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);

    final todayList = provider.todayDueCustomers;
    final upcomingList = provider.upcomingCustomers;
    final overdueList = provider.overdueCustomers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Due Services'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: "Today (${todayList.length})"),
            Tab(text: "Upcoming (${upcomingList.length})"),
            Tab(text: "Overdue (${overdueList.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDueList(context, todayList, 'today'),
          _buildDueList(context, upcomingList, 'upcoming'),
          _buildDueList(context, overdueList, 'overdue'),
        ],
      ),
    );
  }

  Widget _buildDueList(BuildContext context, List<Customer> list, String type) {
    if (list.isEmpty) {
      IconData emptyIcon;
      String emptyMessage;
      Color iconColor;

      if (type == 'today') {
        emptyIcon = Icons.check_circle_outline_rounded;
        emptyMessage = 'No services scheduled for today!';
        iconColor = AppTheme.statusCompleted;
      } else if (type == 'upcoming') {
        emptyIcon = Icons.schedule_rounded;
        emptyMessage = 'No upcoming services due this month.';
        iconColor = AppTheme.statusUpcoming;
      } else {
        emptyIcon = Icons.thumb_up_alt_outlined;
        emptyMessage = 'All caught up! No overdue services.';
        iconColor = AppTheme.statusCompleted;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: iconColor.withOpacity(0.3)),
            const SizedBox(height: 16.0),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final customer = list[index];
        final daysDiff = _calculateDaysDiff(customer.nextServiceDate);
        
        return _buildDueCustomerCard(context, customer, daysDiff, type);
      },
    );
  }

  Widget _buildDueCustomerCard(BuildContext context, Customer customer, int daysDiff, String type) {
    String diffText = '';
    Color badgeColor = Colors.grey;

    if (type == 'today') {
      diffText = 'Due Today';
      badgeColor = AppTheme.statusDueToday;
    } else if (type == 'upcoming') {
      diffText = '$daysDiff days remaining';
      badgeColor = AppTheme.statusUpcoming;
    } else if (type == 'overdue') {
      diffText = '${daysDiff.abs()} days overdue';
      badgeColor = AppTheme.statusOverdue;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Days Tag Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailsScreen(customerId: customer.id),
                        ),
                      );
                    },
                    child: Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    diffText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Product brand / model
            Text(
              '${customer.productBrand} - ${customer.productModel} ${customer.serialNumber.isNotEmpty ? "(S/N: ${customer.serialNumber})" : ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4.0),

            // Site Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customer.address,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0),

            // Call, WhatsApp, Complete Actions Row
            Row(
              children: [
                // Quick Call
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: AppTheme.primaryBlue),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () => _launchCall(context, customer.mobile),
                ),
                const SizedBox(width: 8),

                // Quick WhatsApp
                IconButton(
                  icon: const Icon(Icons.message_rounded, color: AppTheme.statusCompleted),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.statusCompleted.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () => _launchWhatsApp(context, customer.mobile, customer.name),
                ),
                const SizedBox(width: 12),

                // Mark Done Shortcut
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('LOG SERVICE', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddServiceScreen(customer: customer),
                        ),
                      );
                    },
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
