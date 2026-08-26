import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/service_record.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class CustomerProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Customer> _customers = [];
  List<ServiceRecord> _completedServicesThisMonth = [];
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<List<Customer>>? _customersSubscription;
  StreamSubscription<List<ServiceRecord>>? _servicesSubscription;

  CustomerProvider() {
    _initializeServices();
  }

  // Getters
  List<Customer> get customers => _customers;
  List<ServiceRecord> get completedServicesThisMonth {
    final seenIds = <String>{};
    return _completedServicesThisMonth.where((s) => seenIds.add(s.id)).toList();
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered Getters (excludes Paused or Stopped services)
  List<Customer> get todayDueCustomers {
    final today = DateTime.now();
    return _customers.where((c) => 
      c.amcStatus != 'Paused' && 
      c.amcStatus != 'Stopped' && 
      _isSameDay(c.nextServiceDate, today)
    ).toList();
  }

  List<Customer> get overdueCustomers {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return _customers.where((c) => 
      c.amcStatus != 'Paused' && 
      c.amcStatus != 'Stopped' && 
      c.nextServiceDate.isBefore(startOfToday)
    ).toList();
  }

  List<Customer> get upcomingCustomers {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final upcomingLimit = startOfToday.add(const Duration(days: 30));
    
    return _customers.where((c) => 
      c.amcStatus != 'Paused' && 
      c.amcStatus != 'Stopped' && 
      c.nextServiceDate.isAfter(startOfToday) && 
      (c.nextServiceDate.isBefore(upcomingLimit) || _isSameDay(c.nextServiceDate, upcomingLimit))
    ).toList();
  }

  List<Customer> get pausedOrStoppedCustomers {
    return _customers.where((c) => c.amcStatus == 'Paused' || c.amcStatus == 'Stopped').toList();
  }

  List<Customer> get recentCustomers {
    // Return last 5 added customers based on installationDate or sorted by ID
    // Since we don't have a createdDate, sorting by ID descending is a good fallback,
    // or just sorting by installation date. Let's do installation date descending.
    final sorted = List<Customer>.from(_customers);
    sorted.sort((a, b) => b.installationDate.compareTo(a.installationDate));
    return sorted.take(5).toList();
  }

  int get completedServicesThisMonthCount => _completedServicesThisMonth.length;

  // Initialize streams
  void _initializeServices() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      debugPrint("Notification service initialization error: $e");
    }
    
    // Safety fallback: Ensure _isLoading becomes false within 2.5 seconds
    // to prevent getting stuck on the loading indicator during network delays.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    });

    // Subscribe to customers stream
    _customersSubscription = _dbService.getCustomersStream().listen(
      (customerList) {
        _customers = customerList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore stream subscription error: $error. Falling back to local memory database.");
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }
    );

    // Subscribe to completed services stream for current month
    _servicesSubscription = _dbService.getCompletedServicesThisMonthStream().listen(
      (servicesList) {
        _completedServicesThisMonth = servicesList;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Error fetching monthly services: $error");
      }
    );

    // Schedule daily reminder check safely
    try {
      await _notificationService.scheduleDailyReminder();
    } catch (e) {
      debugPrint("Schedule daily reminder failed: $e");
    }
  }

  // Trigger local notification for due services
  void _triggerDueServicesNotification() {
    final todayCount = todayDueCustomers.length;
    final overdueCount = overdueCustomers.length;
    final upcomingCount = upcomingCustomers.length;

    _notificationService.showDueServicesSummaryNotification(
      todayCount: todayCount,
      overdueCount: overdueCount,
      upcomingCount: upcomingCount,
    );
  }

  // ================= ACTIONS =================

  // Add Customer
  Future<void> addCustomer(Customer customer) async {
    try {
      await _dbService.addCustomer(customer);
    } catch (e) {
      debugPrint("Firebase database write failed: $e. Saving locally to memory.");
    }
    
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx == -1) {
      _customers.add(customer);
      // _triggerDueServicesNotification();
      notifyListeners();
    }
  }

  // Update Customer
  Future<void> updateCustomer(Customer customer) async {
    try {
      await _dbService.updateCustomer(customer);
    } catch (e) {
      debugPrint("Firebase database update failed: $e. Updating locally in memory.");
    }
    
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      _customers[idx] = customer;
      // _triggerDueServicesNotification();
      notifyListeners();
    }
  }

  // Delete Customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _dbService.deleteCustomer(customerId);
    } catch (e) {
      debugPrint("Firebase database delete failed: $e. Deleting locally from memory.");
    }
    
    _customers.removeWhere((c) => c.id == customerId);
    _completedServicesThisMonth.removeWhere((s) => s.customerId == customerId);
    // _triggerDueServicesNotification();
    notifyListeners();
  }

  // Extend Next Service Date by 1-4 months
  Future<void> extendCustomerService(Customer customer, int extendMonths, String reason) async {
    try {
      await _dbService.extendCustomerService(customer, extendMonths, reason);
    } catch (e) {
      debugPrint("Firebase service extension failed: $e. Updating locally in memory.");
    }

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

    final updatedCustomer = customer.copyWith(
      nextServiceDate: newNextDate,
      notes: updatedNotes,
      amcStatus: customer.amcStatus == 'Paused' ? 'Active' : customer.amcStatus,
    );

    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      _customers[idx] = updatedCustomer;
      notifyListeners();
    }
  }

  // Update Service / AMC Status (Active, Paused, Stopped)
  Future<void> updateCustomerServiceStatus(Customer customer, String newStatus, {String? reason}) async {
    try {
      await _dbService.updateCustomerServiceStatus(customer, newStatus, reason: reason);
    } catch (e) {
      debugPrint("Firebase status update failed: $e. Updating locally in memory.");
    }

    final timestampStr = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    String updatedNotes = customer.notes;
    
    if (reason != null && reason.trim().isNotEmpty) {
      final statusNote = "[$timestampStr] Status changed to $newStatus. Reason: $reason";
      updatedNotes = customer.notes.trim().isEmpty 
          ? statusNote 
          : "${customer.notes}\n$statusNote";
    }

    final updatedCustomer = customer.copyWith(
      amcStatus: newStatus,
      notes: updatedNotes,
    );

    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      _customers[idx] = updatedCustomer;
      notifyListeners();
    }
  }

  // Record a completed service
  Future<void> logService(ServiceRecord record, Customer customer) async {
    try {
      await _dbService.addServiceRecord(record, customer);
    } catch (e) {
      debugPrint("Firebase service log failed: $e. Saving locally to memory.");
    }
    
    // Automatically calculate next service details locally
    final lastServiceDate = record.serviceDate;
    final intervalMonths = customer.serviceInterval;
    final nextServiceDate = DateTime(
      lastServiceDate.year,
      lastServiceDate.month + intervalMonths,
      lastServiceDate.day,
    );

    // Update customer in list
    final updatedCustomer = customer.copyWith(
      lastServiceDate: lastServiceDate,
      nextServiceDate: nextServiceDate,
    );
    
    final cIdx = _customers.indexWhere((c) => c.id == customer.id);
    if (cIdx != -1) {
      _customers[cIdx] = updatedCustomer;
    }

    // Add service record (safely prevent duplicate entries)
    if (!_completedServicesThisMonth.any((s) => s.id == record.id)) {
      _completedServicesThisMonth.add(record);
    }
    notifyListeners();
  }

  // Fetch service history for a specific customer
  Stream<List<ServiceRecord>> getCustomerServiceHistory(String customerId) {
    return _dbService.getServiceHistoryStream(customerId);
  }

  Future<void> deleteServiceRecord(String serviceId) async {
    await _dbService.deleteServiceRecord(serviceId);
    _completedServicesThisMonth.removeWhere((s) => s.id == serviceId);
    notifyListeners();
  }

  // Advanced Search
  List<Customer> searchCustomers(String query, {String filterType = 'All'}) {
    if (query.trim().isEmpty) return _customers;
    final lowercaseQuery = query.toLowerCase().trim();

    return _customers.where((c) {
      switch (filterType) {
        case 'Name':
          return c.name.toLowerCase().contains(lowercaseQuery);
        case 'Serial No.':
          return c.serialNumber.toLowerCase().contains(lowercaseQuery);
        case 'Mobile':
          return c.mobile.contains(lowercaseQuery) || c.alternateMobile.contains(lowercaseQuery);
        case 'Address':
          return c.address.toLowerCase().contains(lowercaseQuery);
        case 'All':
        default:
          final nameMatch = c.name.toLowerCase().contains(lowercaseQuery);
          final mobileMatch = c.mobile.contains(lowercaseQuery) || c.alternateMobile.contains(lowercaseQuery);
          final modelMatch = c.productModel.toLowerCase().contains(lowercaseQuery) || c.productBrand.toLowerCase().contains(lowercaseQuery);
          final areaMatch = c.address.toLowerCase().contains(lowercaseQuery);
          final serialMatch = c.serialNumber.toLowerCase().contains(lowercaseQuery);
          return nameMatch || mobileMatch || modelMatch || areaMatch || serialMatch;
      }
    }).toList();
  }

  // Helper helper to check if two DateTimes fall on the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _servicesSubscription?.cancel();
    super.dispose();
  }
}
