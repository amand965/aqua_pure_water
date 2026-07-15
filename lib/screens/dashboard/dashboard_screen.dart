import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/summary_card.dart';
import '../../models/customer.dart';
import '../customer/add_edit_customer_screen.dart';
import '../customer/customer_details_screen.dart';
import '../customer/search_customer_screen.dart';
import '../due_services/due_services_screen.dart';
import '../reports/reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final formattedDate = DateFormat('EEEE, d MMMM y').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet Electronics'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutDialog(context, authProvider);
            },
          ),
        ],
      ),
      body: customerProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: () async {
                // Providers update automatically from stream, but this is a nice UX element
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome & Date Header
                      Text(
                        'Welcome, Owner',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24.0),

                      // Metrics Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          SummaryCard(
                            title: 'Total Customers',
                            value: '${customerProvider.customers.length}',
                            icon: Icons.people_rounded,
                            color: AppTheme.primaryBlue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchCustomerScreen()),
                            ),
                          ),
                          SummaryCard(
                            title: "Today's Due",
                            value: '${customerProvider.todayDueCustomers.length}',
                            icon: Icons.calendar_today_rounded,
                            color: AppTheme.statusDueToday,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DueServicesScreen(initialIndex: 0),
                              ),
                            ),
                          ),
                          SummaryCard(
                            title: 'Overdue Services',
                            value: '${customerProvider.overdueCustomers.length}',
                            icon: Icons.warning_amber_rounded,
                            color: AppTheme.statusOverdue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DueServicesScreen(initialIndex: 2),
                              ),
                            ),
                          ),
                          SummaryCard(
                            title: 'Completed (Month)',
                            value: '${customerProvider.completedServicesThisMonthCount}',
                            icon: Icons.assignment_turned_in_rounded,
                            color: AppTheme.statusCompleted,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReportsScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28.0),

                      // Quick Action Title
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      // Quick Action Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickActionButton(
                            context,
                            label: 'Add Customer',
                            icon: Icons.person_add_rounded,
                            color: AppTheme.primaryBlue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
                            ),
                          ),
                          _buildQuickActionButton(
                            context,
                            label: 'Search',
                            icon: Icons.search_rounded,
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchCustomerScreen()),
                            ),
                          ),
                          _buildQuickActionButton(
                            context,
                            label: 'Due Services',
                            icon: Icons.alarm_rounded,
                            color: AppTheme.statusDueToday,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DueServicesScreen()),
                            ),
                          ),
                          _buildQuickActionButton(
                            context,
                            label: 'Reports',
                            icon: Icons.analytics_rounded,
                            color: Colors.indigo,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReportsScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28.0),

                      // Today's Service Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Service List",
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (customerProvider.todayDueCustomers.isNotEmpty)
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DueServicesScreen(initialIndex: 0),
                                ),
                              ),
                              child: const Text('View All'),
                            )
                        ],
                      ),
                      const SizedBox(height: 8.0),

                      // Today's Services List View
                      customerProvider.todayDueCustomers.isEmpty
                          ? _buildEmptyState(
                              context,
                              icon: Icons.check_circle_outline_rounded,
                              message: 'All services completed for today!',
                              color: AppTheme.statusCompleted,
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: customerProvider.todayDueCustomers.length > 3
                                  ? 3
                                  : customerProvider.todayDueCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = customerProvider.todayDueCustomers[index];
                                return _buildCustomerListItem(context, customer);
                              },
                            ),
                      const SizedBox(height: 24.0),

                      // Recently Added Customers Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recently Added Customers',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (customerProvider.customers.isNotEmpty)
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SearchCustomerScreen()),
                              ),
                              child: const Text('View All'),
                            )
                        ],
                      ),
                      const SizedBox(height: 8.0),

                      // Recently Added Customers List View
                      customerProvider.recentCustomers.isEmpty
                          ? _buildEmptyState(
                              context,
                              icon: Icons.people_outline_rounded,
                              message: 'No customers registered yet.',
                              color: Colors.grey,
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: customerProvider.recentCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = customerProvider.recentCustomers[index];
                                return _buildCustomerListItem(context, customer);
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Quick Action Button Factory
  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // Customer List Tile Widget
  Widget _buildCustomerListItem(BuildContext context, Customer customer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightBlueBackground,
          backgroundImage: customer.photoUrl != null && customer.photoUrl!.isNotEmpty
              ? NetworkImage(customer.photoUrl!)
              : null,
          child: customer.photoUrl == null || customer.photoUrl!.isEmpty
              ? const Icon(Icons.person_rounded, color: AppTheme.primaryBlue)
              : null,
        ),
        title: Text(
          customer.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2.0),
            Text(
              '${customer.productBrand} - ${customer.productModel} ${customer.serialNumber.isNotEmpty ? "(S/N: ${customer.serialNumber})" : ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1.0),
            Text(
              customer.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
  }

  // Helper empty state view
  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color.withOpacity(0.5)),
          const SizedBox(height: 8.0),
          Text(
            message,
            style: TextStyle(
              fontSize: 13.0,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Logout confirmation dialog
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout from the app?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusOverdue,
              ),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                authProvider.logout();
              },
            ),
          ],
        );
      },
    );
  }
}
