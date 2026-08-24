import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/customer.dart';
import '../../models/service_record.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/date_input_field.dart';
import '../../widgets/safe_tap.dart';

class AddServiceScreen extends StatefulWidget {
  final Customer customer;

  const AddServiceScreen({super.key, required this.customer});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _technicianController = TextEditingController();
  final _workDoneController = TextEditingController();
  final _partsController = TextEditingController();
  final _chargesController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();

  // State values
  DateTime _serviceDate = DateTime.now();
  String _paymentStatus = 'Paid';
  final List<File> _selectedPhotos = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _technicianController.dispose();
    _workDoneController.dispose();
    _partsController.dispose();
    _chargesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos allowed.')),
      );
      return;
    }
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _selectedPhotos.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to launch camera.')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<List<String>> _uploadPhotos(String serviceId) async {
    final List<String> urls = [];
    for (int i = 0; i < _selectedPhotos.length; i++) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('services/$serviceId/photo_$i.jpg');
        final uploadTask = await ref.putFile(_selectedPhotos[i]);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        debugPrint("Error uploading photo $i: $e");
        // Offline support: skip uploading this photo if it fails, or queue.
      }
    }
    return urls;
  }

  void _saveService() async {
    if (_isSaving) return; // Prevent double-submit
    if (!SafeTap.canTap(1000)) return; // Debounce rapid multi-clicks
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final serviceId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // 1. Upload service photos
      final photoUrls = await _uploadPhotos(serviceId);

      // 2. Build ServiceRecord
      final newRecord = ServiceRecord(
        id: serviceId,
        customerId: widget.customer.id,
        serviceDate: _serviceDate,
        technicianName: _technicianController.text.trim(),
        workDone: _workDoneController.text.trim(),
        partsReplaced: _partsController.text.trim(),
        charges: double.tryParse(_chargesController.text) ?? 0.0,
        paymentStatus: _paymentStatus,
        notes: _notesController.text.trim(),
        photoUrls: photoUrls,
      );

      // 3. Save Service (this automatically updates the Customer's due dates in Firestore)
      await provider.logService(newRecord, widget.customer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service logged for ${widget.customer.name}'),
            backgroundColor: AppTheme.statusCompleted,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving service: $e'),
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
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Service Work'),
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 16),
                  Text('Logging service record...', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('This will auto-calculate next service date', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                    // Client Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlueBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CUSTOMER', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(widget.customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('${widget.customer.productBrand} - ${widget.customer.productModel}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Service Date Picker
                    DateInputField(
                      label: 'Service Completion Date*',
                      dateValue: _serviceDate,
                      isRequired: true,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (picked) {
                        if (picked != null) {
                          setState(() {
                            _serviceDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Technician Input
                    TextFormField(
                      controller: _technicianController,
                      decoration: const InputDecoration(
                        labelText: 'Technician Name*',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter technician name' : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Work Done Input
                    TextFormField(
                      controller: _workDoneController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Work Done / Details*',
                        prefixIcon: Icon(Icons.build_circle_outlined),
                        hintText: 'e.g. Filters changed, Membrane washed, General inspection',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter service work details' : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Parts Replaced Input
                    TextFormField(
                      controller: _partsController,
                      decoration: const InputDecoration(
                        labelText: 'Parts Replaced (if any)',
                        prefixIcon: Icon(Icons.settings_outlined),
                        hintText: 'e.g. Sediment filter, Pre-filter, Pump',
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Charges Input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _chargesController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Charges (₹)*',
                              prefixIcon: Icon(Icons.currency_rupee_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Enter charges';
                              if (double.tryParse(value) == null) return 'Enter a valid amount';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Payment Status Dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _paymentStatus,
                            decoration: const InputDecoration(
                              labelText: 'Payment Status*',
                              prefixIcon: Icon(Icons.payment_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _paymentStatus = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    // Camera/Photo Section
                    const Text('Service Documentation Photos (Max 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8.0),
                    _buildPhotoSelectorGrid(),
                    const SizedBox(height: 20.0),

                    // Notes Input
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Additional Service Notes',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : SafeTap.wrap(_saveService),
                      child: const Text('SUBMIT & MARK COMPLETED'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoSelectorGrid() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedPhotos.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedPhotos.length) {
            // Camera Add Button
            if (_selectedPhotos.length >= 3) return const SizedBox.shrink();
            return GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                ),
                child: const Icon(Icons.add_a_photo_rounded, color: Colors.black54),
              ),
            );
          }

          // Added Photo previews
          return Stack(
            children: [
              Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_selectedPhotos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 10,
                child: GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
