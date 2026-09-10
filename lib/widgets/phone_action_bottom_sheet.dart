import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';

enum PhoneActionMode { call, whatsapp }

class PhoneActionBottomSheet extends StatelessWidget {
  final Customer customer;
  final PhoneActionMode mode;

  const PhoneActionBottomSheet({
    super.key,
    required this.customer,
    required this.mode,
  });

  /// Entry point to initiate a Call or WhatsApp action:
  /// - If customer has 0 numbers -> shows warning SnackBar.
  /// - If customer has 1 number -> directly launches Call or WhatsApp.
  /// - If customer has 2+ numbers -> shows modal selection bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required Customer customer,
    required PhoneActionMode mode,
  }) async {
    final numbers = customer.allPhoneNumbers;
    if (numbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contact numbers available for this customer.'),
          backgroundColor: AppTheme.statusOverdue,
        ),
      );
      return;
    }

    if (numbers.length == 1) {
      if (mode == PhoneActionMode.call) {
        await launchCall(context, numbers.first);
      } else {
        await launchWhatsApp(context, numbers.first, customer.name);
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhoneActionBottomSheet(
        customer: customer,
        mode: mode,
      ),
    );
  }

  static Future<void> launchCall(BuildContext context, String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse("tel:$cleanMobile");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start phone dialer.'),
            backgroundColor: AppTheme.statusOverdue,
          ),
        );
      }
    }
  }

  static Future<void> launchWhatsApp(BuildContext context, String mobile, String customerName) async {
    String cleanNumber = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber'; // Default India prefix
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp application.'),
            backgroundColor: AppTheme.statusOverdue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCall = mode == PhoneActionMode.call;
    final primaryColor = isCall ? AppTheme.primaryBlue : AppTheme.statusCompleted;
    final numbers = customer.allPhoneNumbers;

    return Container(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 28.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCall ? Icons.phone_forwarded_rounded : Icons.chat_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCall ? 'Select Number to Call' : 'Select WhatsApp Number',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer.name} • ${numbers.length} numbers available',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
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

          // Number choices list
          ...numbers.asMap().entries.map((entry) {
            final index = entry.key;
            final number = entry.value;
            final isPrimary = index == 0;
            final badgeLabel = isPrimary ? 'PRIMARY' : 'ALT $index';
            final badgeColor = isPrimary ? AppTheme.primaryBlue : Colors.teal;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPrimary
                      ? primaryColor.withOpacity(0.3)
                      : Colors.grey[300]!,
                  width: isPrimary ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: (isPrimary ? primaryColor : Colors.grey).withOpacity(0.12),
                  child: Icon(
                    isPrimary ? Icons.star_rounded : Icons.phone_android_rounded,
                    color: isPrimary ? primaryColor : Colors.black87,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      number,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  isPrimary ? 'Main contact number' : 'Alternate contact #$index',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                trailing: ElevatedButton.icon(
                  icon: Icon(
                    isCall ? Icons.call_rounded : Icons.send_rounded,
                    size: 16,
                  ),
                  label: Text(isCall ? 'CALL' : 'CHAT', style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (isCall) {
                      await launchCall(context, number);
                    } else {
                      await launchWhatsApp(context, number, customer.name);
                    }
                  },
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (isCall) {
                    await launchCall(context, number);
                  } else {
                    await launchWhatsApp(context, number, customer.name);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
