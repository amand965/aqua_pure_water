import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/service_record.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseService() {
    // Explicitly configure Firestore for offline persistence.
    // Cloud Firestore has offline persistence enabled by default on Android,
    // but configuring it ensures it is set correctly.
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ================= CUSTOMER OPERATIONS =================

  // Get Stream of all customers (ordered by name)
  Stream<List<Customer>> getCustomersStream() {
    return _db.collection('customers')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Customer.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get list of all customers once (useful for offline calculations)
  Future<List<Customer>> getCustomersOnce() async {
    final snapshot = await _db.collection('customers').orderBy('name').get();
    return snapshot.docs
        .map((doc) => Customer.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Add a new customer
  Future<String> addCustomer(Customer customer) async {
    final docRef = _db.collection('customers').doc();
    final newCustomer = customer.copyWith(id: docRef.id);
    await docRef.set(newCustomer.toMap());
    return docRef.id;
  }

  // Update customer details
  Future<void> updateCustomer(Customer customer) async {
    await _db.collection('customers').doc(customer.id).update(customer.toMap());
  }

  // Delete customer and their service records
  Future<void> deleteCustomer(String customerId) async {
    final batch = _db.batch();
    
    // Delete customer document
    final customerRef = _db.collection('customers').doc(customerId);
    batch.delete(customerRef);

    // Delete associated services
    final servicesSnapshot = await _db.collection('services')
        .where('customerId', isEqualTo: customerId)
        .get();
        
    for (var doc in servicesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Extend customer next service date by 1 to 4 months
  Future<void> extendCustomerService(Customer customer, int extendMonths, String reason) async {
    final currentNext = customer.nextServiceDate;
    final baseDate = currentNext.isBefore(DateTime.now()) ? DateTime.now() : currentNext;
    final newNextDate = DateTime(
      baseDate.year,
      baseDate.month + extendMonths,
      baseDate.day,
    );

    final timestampStr = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    final extensionNote = "[$timestampStr] Extended service by $extendMonths month(s). Reason: $reason";
    final updatedNotes = customer.notes.trim().isEmpty 
        ? extensionNote 
        : "${customer.notes}\n$extensionNote";

    await _db.collection('customers').doc(customer.id).update({
      'nextServiceDate': Timestamp.fromDate(newNextDate),
      'notes': updatedNotes,
      'amcStatus': customer.amcStatus == 'Paused' ? 'Active' : customer.amcStatus,
    });
  }

  // Update customer AMC / Service status (Active, Paused, Stopped)
  Future<void> updateCustomerServiceStatus(Customer customer, String newStatus, {String? reason}) async {
    final timestampStr = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    String updatedNotes = customer.notes;
    
    if (reason != null && reason.trim().isNotEmpty) {
      final statusNote = "[$timestampStr] Status changed to $newStatus. Reason: $reason";
      updatedNotes = customer.notes.trim().isEmpty 
          ? statusNote 
          : "${customer.notes}\n$statusNote";
    }

    await _db.collection('customers').doc(customer.id).update({
      'amcStatus': newStatus,
      'notes': updatedNotes,
    });
  }


  // ================= SERVICE RECORDS OPERATIONS =================

  // Get Stream of service records for a specific customer
  Stream<List<ServiceRecord>> getServiceHistoryStream(String customerId) {
    return _db.collection('services')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ServiceRecord.fromMap(doc.data(), doc.id))
              .toList();
          // Sort locally in memory descending by date to avoid needing a Firestore composite index!
          list.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
          return list;
        });
  }

  // Add a service record and update customer's last & next service dates
  Future<void> addServiceRecord(ServiceRecord record, Customer customer) async {
    final batch = _db.batch();

    // 1. Create a reference and add the service record
    final serviceRef = _db.collection('services').doc();
    final serviceData = record.toMap();
    batch.set(serviceRef, serviceData);

    // 2. Calculate next service date based on serviceInterval (3, 6, 12 months)
    final lastServiceDate = record.serviceDate;
    final intervalMonths = customer.serviceInterval;
    
    // Add intervalMonths to lastServiceDate to get nextServiceDate
    // Handles leap years and month ends correctly via DateTime behavior
    final nextServiceDate = DateTime(
      lastServiceDate.year,
      lastServiceDate.month + intervalMonths,
      lastServiceDate.day,
    );

    // 3. Update customer's service dates
    final customerRef = _db.collection('customers').doc(customer.id);
    batch.update(customerRef, {
      'lastServiceDate': Timestamp.fromDate(lastServiceDate),
      'nextServiceDate': Timestamp.fromDate(nextServiceDate),
    });

    // 4. Commit batch (supports offline queueing automatically)
    await batch.commit();
  }

  // Delete a specific service record (does not recalculate customer dates automatically,
  // but handles individual record cleanup)
  Future<void> deleteServiceRecord(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
  }

  // Get stream of service records completed in the current month
  Stream<List<ServiceRecord>> getCompletedServicesThisMonthStream() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));

    return _db.collection('services')
        .where('serviceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('serviceDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRecord.fromMap(doc.data(), doc.id))
            .toList());
  }
}
