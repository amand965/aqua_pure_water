import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRecord {
  final String id;
  final String customerId;
  final DateTime serviceDate;
  final String technicianName;
  final String workDone;
  final String partsReplaced;
  final double charges;
  final String paymentStatus; // 'Paid', 'Pending'
  final String notes;
  final List<String> photoUrls;

  ServiceRecord({
    required this.id,
    required this.customerId,
    required this.serviceDate,
    required this.technicianName,
    required this.workDone,
    required this.partsReplaced,
    required this.charges,
    required this.paymentStatus,
    required this.notes,
    required this.photoUrls,
  });

  // Create a ServiceRecord from a Firestore Document
  factory ServiceRecord.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? toDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    List<String> toStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [value.toString()];
    }

    return ServiceRecord(
      id: documentId,
      customerId: map['customerId'] ?? '',
      serviceDate: toDateTime(map['serviceDate']) ?? DateTime.now(),
      technicianName: map['technician'] ?? map['technicianName'] ?? '', // support both key variants
      workDone: map['workDone'] ?? '',
      partsReplaced: map['partsChanged'] ?? map['partsReplaced'] ?? '', // support both key variants
      charges: toDouble(map['charges']),
      paymentStatus: map['paymentStatus'] ?? 'Pending',
      notes: map['notes'] ?? '',
      photoUrls: toStringList(map['photos'] ?? map['photoUrls']),
    );
  }

  // Convert a ServiceRecord to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'serviceDate': Timestamp.fromDate(serviceDate),
      'technician': technicianName,
      'workDone': workDone,
      'partsChanged': partsReplaced,
      'charges': charges,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'photos': photoUrls,
    };
  }
}
