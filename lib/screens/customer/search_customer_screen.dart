import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import 'customer_details_screen.dart';
import '../../models/customer.dart';

class SearchCustomerScreen extends StatefulWidget {
  const SearchCustomerScreen({super.key});

  @override
  State<SearchCustomerScreen> createState() => _SearchCustomerScreenState();
}

class _SearchCustomerScreenState extends State<SearchCustomerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchFilter = 'All';
  final List<String> _filterOptions = const ['All', 'Name', 'Serial No.', 'Mobile', 'Address'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final results = customerProvider.searchCustomers(_searchQuery, filterType: _searchFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Customers'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by Name, Mobile, RO model, Area...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Search Filter Chips Row
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final isSelected = _searchFilter == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.0,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _searchFilter = option;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12.0),
          
          // Results Count Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  _searchQuery.isEmpty ? 'All Registered Customers' : 'Search Results',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${results.length} found',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Results List View
          Expanded(
            child: results.isEmpty
                ? _buildNoResultsState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final customer = results[index];
                      return _buildCustomerSearchCard(context, customer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSearchCard(BuildContext context, Customer customer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            fontSize: 16.0,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(customer.mobile, style: const TextStyle(fontSize: 13.0)),
                ],
              ),
              const SizedBox(height: 2.0),
              Row(
                children: [
                  const Icon(Icons.devices_other_rounded, size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${customer.productBrand} - ${customer.productModel} ${customer.serialNumber.isNotEmpty ? "(S/N: ${customer.serialNumber})" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customer.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16.0),
          const Text(
            'No matching customers found.',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4.0),
          const Text(
            'Try searching name, mobile, model, or area.',
            style: TextStyle(
              fontSize: 13.0,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
