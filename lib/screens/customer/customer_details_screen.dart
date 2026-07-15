import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer.dart';
import '../../models/service_record.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../service/add_service_screen.dart';
import 'add_edit_customer_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  Future<void> _launchCall(BuildContext context, String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse("tel:$cleanMobile");
    try {
      await launchUrl(url);
    } catch (e) {
      _showErrorSnackBar(context, 'Could not start call dialer.');
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String mobile, String customerName) async {
    String cleanNumber = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber'; // India country code
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
      _showErrorSnackBar(context, 'Could not open WhatsApp application.');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.statusOverdue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    
    // Find customer in provider's local list
    final customerList = customerProvider.customers.where((c) => c.id == customerId);
    if (customerList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: Text('Customer not found.')),
      );
    }
    
    final customer = customerList.first;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditCustomerScreen(customer: customer),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.statusOverdue),
            tooltip: 'Delete Customer',
            onPressed: () {
              _confirmDelete(context, customerProvider, customer);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
            _buildProfileHeader(context, customer),

            // Communication Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.phone_rounded),
                      label: const Text('CALL'),
                      onPressed: () => _launchCall(context, customer.mobile),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message_rounded),
                      label: const Text('WHATSAPP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusCompleted,
                      ),
                      onPressed: () => _launchWhatsApp(context, customer.mobile, customer.name),
                    ),
                  ),
                ],
              ),
            ),
            
            // Core Info Card
            _buildCoreInfoCard(context, customer, dateFormat),

            // Warranty & AMC Contract Cards
            _buildWarrantyAndAmcSection(context, customer, dateFormat),

            // Service History Section
            _buildServiceHistorySection(context, customerProvider, customer, dateFormat),
          ],
        ),
      ),
    );
  }

  // Beautiful Header Profile card showing photo name brand
  Widget _buildProfileHeader(BuildContext context, Customer customer) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.lightBlueBackground,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: customer.photoUrl != null && customer.photoUrl!.isNotEmpty
                ? NetworkImage(customer.photoUrl!)
                : null,
            child: customer.photoUrl == null || customer.photoUrl!.isEmpty
                ? const Icon(Icons.person_rounded, size: 44, color: AppTheme.primaryBlue)
                : null,
          ),
          const SizedBox(width: 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6.0),
                Row(
                  children: [
                    const Icon(Icons.devices_other_rounded, size: 16, color: AppTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${customer.productBrand} (${customer.productModel})',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  customer.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.0, color: Colors.black45),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Profile details parameters list
  Widget _buildCoreInfoCard(BuildContext context, Customer customer, DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            const Divider(height: 20),
            _buildDetailRow(Icons.phone_rounded, 'Mobile Number', customer.mobile),
            _buildDetailRow(Icons.tag_rounded, 'Serial Number', customer.serialNumber.isNotEmpty ? customer.serialNumber : 'N/A'),
            if (customer.alternateMobile.isNotEmpty)
              _buildDetailRow(Icons.phone_paused_rounded, 'Alternate Contact', customer.alternateMobile),
            _buildDetailRow(Icons.calendar_month_rounded, 'Installation Date', dateFormat.format(customer.installationDate)),
            _buildDetailRow(Icons.timelapse_rounded, 'Service Interval', 'Every ${customer.serviceInterval} Months'),
            _buildDetailRow(
              Icons.notifications_active_outlined, 
              'Next Scheduled Service', 
              dateFormat.format(customer.nextServiceDate),
              valueColor: _isOverdue(customer.nextServiceDate) ? AppTheme.statusOverdue : AppTheme.primaryBlue,
              isBold: true,
            ),
            if (customer.notes.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(customer.notes, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }

  // Warranty and AMC Contract badges
  Widget _buildWarrantyAndAmcSection(BuildContext context, Customer customer, DateFormat dateFormat) {
    // Determine AMC Color tag
    Color amcColor;
    if (customer.amcStatus == 'Active') {
      amcColor = AppTheme.statusCompleted;
    } else if (customer.amcStatus == 'Expired') {
      amcColor = AppTheme.statusOverdue;
    } else {
      amcColor = Colors.grey;
    }

    // Determine Warranty status
    final hasWarranty = customer.warrantyExpiry != null && customer.warrantyExpiry!.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        children: [
          // AMC Info Card
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text('AMC Status', style: TextStyle(fontSize: 12.0, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: amcColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        customer.amcStatus.toUpperCase(),
                        style: TextStyle(color: amcColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Warranty Info Card
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text('Warranty Status', style: TextStyle(fontSize: 12.0, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (hasWarranty ? AppTheme.statusCompleted : Colors.grey).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasWarranty
                            ? 'WARRANTY ACTIVE'
                            : 'NO WARRANTY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: hasWarranty ? AppTheme.statusCompleted : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Service history timelines view
  Widget _buildServiceHistorySection(
    BuildContext context, 
    CustomerProvider provider, 
    Customer customer, 
    DateFormat dateFormat,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Service History',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('LOG SERVICE', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
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
              ],
            ),
            const Divider(height: 20),
            
            // Subscribed timeline stream
            StreamBuilder<List<ServiceRecord>>(
              stream: provider.getCustomerServiceHistory(customer.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error loading history: ${snapshot.error}');
                }

                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8.0),
                        const Text(
                          'No service history logged yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 13.0),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return _buildTimelineItem(context, record, dateFormat);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Single card element in the service history timeline
  Widget _buildTimelineItem(BuildContext context, ServiceRecord record, DateFormat dateFormat) {
    final isPaid = record.paymentStatus == 'Paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Date and Charge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(record.serviceDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPaid ? AppTheme.statusCompleted : AppTheme.statusOverdue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: isPaid ? AppTheme.statusCompleted : AppTheme.statusOverdue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            
            // Service execution fields
            _buildTimelineRow('Technician', record.technicianName),
            _buildTimelineRow('Work Done', record.workDone),
            if (record.partsReplaced.isNotEmpty)
              _buildTimelineRow('Parts Changed', record.partsReplaced),
            _buildTimelineRow('Charges', '₹ ${record.charges.toStringAsFixed(2)}'),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${record.notes}',
                style: const TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.0, color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }

  // Row formatter for generic details list
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue.withOpacity(0.7)),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13.0),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(DateTime date) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return date.isBefore(startOfToday);
  }

  void _confirmDelete(BuildContext context, CustomerProvider provider, Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to permanently delete customer "${customer.name}" and all their service history? This action cannot be undone.'),
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
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // pop dialog
                Navigator.of(context).pop(); // pop details screen
                await provider.deleteCustomer(customer.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted customer ${customer.name}'),
                      backgroundColor: AppTheme.statusOverdue,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
