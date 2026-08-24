import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/date_input_field.dart';
import '../../widgets/safe_tap.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer; // If null, we are in Add mode. If provided, we are in Edit mode.

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _alternateMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _productBrandController = TextEditingController();
  final _productModelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // State values
  DateTime _installationDate = DateTime.now();
  int _serviceInterval = 3; // default 3 months
  DateTime? _lastServiceDate;
  DateTime _nextServiceDate = DateTime.now().add(const Duration(days: 90));
  DateTime? _warrantyExpiry;
  String _amcStatus = 'None';
  
  File? _selectedImage;
  String? _existingPhotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _existingPhotoUrl = widget.customer?.photoUrl;
    
    if (widget.customer != null) {
      final c = widget.customer!;
      _nameController.text = c.name;
      _mobileController.text = c.mobile;
      _alternateMobileController.text = c.alternateMobile;
      _addressController.text = c.address;
      _productBrandController.text = c.productBrand;
      _productModelController.text = c.productModel;
      _serialNumberController.text = c.serialNumber;
      _notesController.text = c.notes;
      _installationDate = c.installationDate;
      _serviceInterval = c.serviceInterval;
      _lastServiceDate = c.lastServiceDate;
      _nextServiceDate = c.nextServiceDate;
      _warrantyExpiry = c.warrantyExpiry;
      _amcStatus = c.amcStatus;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _alternateMobileController.dispose();
    _addressController.dispose();
    _productBrandController.dispose();
    _productModelController.dispose();
    _serialNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Calculate next service date based on interval and last service (or installation) date
  void _recalculateNextServiceDate() {
    final baseDate = _lastServiceDate ?? _installationDate;
    setState(() {
      _nextServiceDate = DateTime(
        baseDate.year,
        baseDate.month + _serviceInterval,
        baseDate.day,
      );
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image.')),
      );
    }
  }

  Future<String?> _uploadImage(String customerId) async {
    if (_selectedImage == null) return _existingPhotoUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('customers/$customerId/profile.jpg');
      final uploadTask = await ref.putFile(_selectedImage!);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading customer image: $e");
      // Let the save continue even if image upload fails, offline fallback
      return _existingPhotoUrl;
    }
  }

  void _saveCustomer() async {
    if (_isSaving) return; // Prevent double-submit
    if (!SafeTap.canTap(1000)) return; // Debounce rapid multi-clicks
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final isEdit = widget.customer != null;
    final customerId = widget.customer?.id ?? '';

    try {
      // If adding new, generate local temporary ID or let Firebase do it.
      // We will perform upload. If offline, the task uploads once online.
      String targetId = customerId;
      String? finalPhotoUrl = _existingPhotoUrl;

      if (!isEdit) {
        // Create an empty reference to get an ID first, so we can upload image to a specific path
        // We can just use Uuid or database helper
        targetId = DateTime.now().millisecondsSinceEpoch.toString();
      }

      if (_selectedImage != null) {
        finalPhotoUrl = await _uploadImage(targetId);
      }

      final customerData = Customer(
        id: targetId,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        alternateMobile: _alternateMobileController.text.trim(),
        address: _addressController.text.trim(),
        productBrand: _productBrandController.text.trim(),
        productModel: _productModelController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        installationDate: _installationDate,
        serviceInterval: _serviceInterval,
        lastServiceDate: _lastServiceDate,
        nextServiceDate: _nextServiceDate,
        warrantyExpiry: _warrantyExpiry,
        amcStatus: _amcStatus,
        notes: _notesController.text.trim(),
        photoUrl: finalPhotoUrl,
      );

      if (isEdit) {
        await provider.updateCustomer(customerData);
      } else {
        await provider.addCustomer(customerData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Customer profile updated' : 'Customer added successfully'),
            backgroundColor: AppTheme.statusCompleted,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customer: $e'),
            backgroundColor: AppTheme.statusOverdue,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'Add New Customer'),
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 16),
                  Text('Saving customer records...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Picker
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                                    ? NetworkImage(_existingPhotoUrl!) as ImageProvider
                                    : null),
                            child: _selectedImage == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty)
                                ? Icon(Icons.person_add_alt_1_rounded, size: 40, color: Colors.grey[400])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primaryBlue,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Section: Basic Info
                    const Text('Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 12.0),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Customer Name*', prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter customer name' : null,
                    ),
                    const SizedBox(height: 16.0),

                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: const InputDecoration(labelText: 'Mobile Number*', prefixIcon: Icon(Icons.phone_android_outlined)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter mobile number';
                        final clean = value.trim();
                        if (clean.length != 10 || int.tryParse(clean) == null) {
                          return 'Mobile number must be exactly 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    TextFormField(
                      controller: _alternateMobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: const InputDecoration(labelText: 'Alternate Contact Number', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null; // optional
                        final clean = value.trim();
                        if (clean.length != 10 || int.tryParse(clean) == null) {
                          return 'Alternate number must be exactly 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Site Address*', prefixIcon: Icon(Icons.location_on_outlined)),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter address' : null,
                    ),
                    const SizedBox(height: 24.0),

                    // Section: Product Details
                    const Text('Product Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 12.0),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _productBrandController,
                            decoration: const InputDecoration(labelText: 'Product Brand*', hintText: 'e.g. Samsung, Kent, LG'),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Enter product brand' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _productModelController,
                            decoration: const InputDecoration(labelText: 'Product Model/Type*', hintText: 'e.g. TV, Geyser, Active'),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Enter product model/type' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Serial Number (Unique)*',
                        hintText: 'Enter unique serial number assigned to product',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a unique serial number' : null,
                    ),
                    const SizedBox(height: 24.0),

                    // Section: Service Settings
                    const Text('Service & AMC Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 12.0),

                    // Service Interval Dropdown
                    DropdownButtonFormField<int>(
                      value: _serviceInterval,
                      decoration: const InputDecoration(labelText: 'Service Interval*', prefixIcon: Icon(Icons.update_rounded)),
                      items: List.generate(12, (index) {
                        final months = index + 1;
                        return DropdownMenuItem(
                          value: months,
                          child: Text(months == 1 ? 'Every 1 Month' : 'Every $months Months'),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _serviceInterval = val;
                          });
                          _recalculateNextServiceDate();
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // AMC Status Dropdown
                    DropdownButtonFormField<String>(
                      value: _amcStatus,
                      decoration: const InputDecoration(labelText: 'AMC Status*', prefixIcon: Icon(Icons.verified_user_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'None', child: Text('No AMC Contract')),
                        DropdownMenuItem(value: 'Active', child: Text('Active AMC Contract')),
                        DropdownMenuItem(value: 'Expired', child: Text('Expired AMC Contract')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _amcStatus = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Installation Date Picker
                    DateInputField(
                      label: 'Installation Date*',
                      dateValue: _installationDate,
                      isRequired: true,
                      onDateChanged: (picked) {
                        if (picked != null) {
                          setState(() {
                            _installationDate = picked;
                          });
                          _recalculateNextServiceDate();
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Last Service Date Picker (Optional)
                    DateInputField(
                      label: 'Last Service Date',
                      dateValue: _lastServiceDate,
                      hint: 'DD/MM/YYYY (Optional)',
                      allowClear: true,
                      onDateChanged: (picked) {
                        setState(() {
                          _lastServiceDate = picked;
                        });
                        _recalculateNextServiceDate();
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Next Service Date Picker
                    DateInputField(
                      label: 'Calculated Next Service Date*',
                      dateValue: _nextServiceDate,
                      isRequired: true,
                      isHighlighted: true,
                      onDateChanged: (picked) {
                        if (picked != null) {
                          setState(() {
                            _nextServiceDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Warranty Expiry Date Picker (Optional)
                    DateInputField(
                      label: 'Warranty Expiry Date',
                      dateValue: _warrantyExpiry,
                      hint: 'DD/MM/YYYY (Optional)',
                      allowClear: true,
                      onDateChanged: (picked) {
                        setState(() {
                          _warrantyExpiry = picked;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Notes Field
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Machine/Client Notes', prefixIcon: Icon(Icons.notes_rounded)),
                    ),
                    const SizedBox(height: 32.0),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveCustomer,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                            )
                          : Text(isEdit ? 'SAVE CHANGES' : 'REGISTER CUSTOMER'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
