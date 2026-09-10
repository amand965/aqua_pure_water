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
import '../../services/app_update_service.dart';
import '../../widgets/update_dialog.dart';
import '../../widgets/safe_tap.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await AppUpdateService().checkAppUpdate();
    if (updateInfo != null && updateInfo.hasUpdate && mounted) {
      UpdateDialog.show(context, updateInfo);
    }
  }

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
                      // Hero Gradient Header Card with Water Ripple & Decorative Accents
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24.0),
                        decoration: BoxDecoration(
                          gradient: AppTheme.oceanGradient,
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D47A1).withOpacity(0.32),
                              blurRadius: 20.0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: Stack(
                            children: [
                              // Decorative background water ripples / circles
                              Positioned(
                                right: -30,
                                top: -30,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 30,
                                bottom: -40,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.06),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 18,
                                top: 22,
                                child: Icon(
                                  Icons.water_drop_rounded,
                                  size: 58,
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              // Content inside banner
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF00E676),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'MEET ELECTRONICS • ACTIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12.0),
                                    const Text(
                                      'Welcome back, Owner 👋',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_month_rounded, size: 14, color: Colors.white.withOpacity(0.85)),
                                        const SizedBox(width: 5),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

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
                            onTap: SafeTap.wrap(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchCustomerScreen()),
                            ))!,
                          ),
                          SummaryCard(
                            title: "Today's Due",
                            value: '${customerProvider.todayDueCustomers.length}',
                            icon: Icons.calendar_today_rounded,
                            color: AppTheme.statusDueToday,
                            onTap: SafeTap.wrap(() => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DueServicesScreen(initialIndex: 0),
                              ),
                            ))!,
                          ),
                          SummaryCard(
                            title: 'Overdue Services',
                            value: '${customerProvider.overdueCustomers.length}',
                            icon: Icons.warning_amber_rounded,
                            color: AppTheme.statusOverdue,
                            onTap: SafeTap.wrap(() => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DueServicesScreen(initialIndex: 2),
                              ),
                            ))!,
                          ),
                          SummaryCard(
                            title: 'Completed (Month)',
                            value: '${customerProvider.completedServicesThisMonthCount}',
                            icon: Icons.assignment_turned_in_rounded,
                            color: AppTheme.statusCompleted,
                            onTap: SafeTap.wrap(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReportsScreen()),
                            ))!,
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
                            onTap: SafeTap.wrap(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
                            ))!,
                          ),
                          _buildQuickActionButton(
                            context,
                            label: 'Search',
                            icon: Icons.search_rounded,
                            color: Colors.teal,
                            onTap: SafeTap.wrap(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchCustomerScreen()),
                            ))!,
                          ),
                          _buildQuickActionButton(
                            context,
                            label: 'Due Services',
                            icon: Icons.alarm_rounded,
                            color: AppTheme.statusDueToday,
                            onTap: SafeTap.wrap(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DueServicesScreen()),
                            ))!,
                          ),
                          _buildQuickActionButton(
                            context,
                            label: 'Reports',
                            icon: Icons.analytics_rounded,
                            color: Colors.indigo,
                            onTap: SafeTap.wrap(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReportsScreen()),
                            ))!,
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
    return _AnimatedQuickActionButton(
      label: label,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }

  // Customer List Tile Widget
  Widget _buildCustomerListItem(BuildContext context, Customer customer) {
    final bool isPaused = customer.amcStatus == 'Paused' || customer.amcStatus == 'Stopped';
    final Color badgeColor = isPaused
        ? Colors.grey
        : (customer.nextServiceDate.isBefore(DateTime.now())
            ? AppTheme.statusOverdue
            : AppTheme.statusCompleted);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.grey.withOpacity(0.16), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailsScreen(customerId: customer.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
          child: Row(
            children: [
              // Avatar with gradient halo
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [badgeColor.withOpacity(0.7), badgeColor.withOpacity(0.15)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.white,
                  backgroundImage: customer.photoUrl != null && customer.photoUrl!.isNotEmpty
                      ? NetworkImage(customer.photoUrl!)
                      : null,
                  child: customer.photoUrl == null || customer.photoUrl!.isEmpty
                      ? Text(
                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // Customer Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      '${customer.productBrand} • ${customer.productModel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.0, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      customer.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
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

class _AnimatedQuickActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedQuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedQuickActionButton> createState() => _AnimatedQuickActionButtonState();
}

class _AnimatedQuickActionButtonState extends State<_AnimatedQuickActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : (_isHovered ? 1.07 : 1.0),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(_isHovered ? 0.22 : 0.12),
                      color.withOpacity(_isHovered ? 0.12 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(
                    color: color.withOpacity(_isHovered ? 0.45 : 0.22),
                    width: _isHovered ? 1.8 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(_isHovered ? 0.28 : 0.08),
                      blurRadius: _isHovered ? 16.0 : 8.0,
                      offset: Offset(0, _isHovered ? 6.0 : 3.0),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _isHovered ? color : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
