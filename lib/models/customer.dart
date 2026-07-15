import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String mobile;
  final String alternateMobile;
  final String address;
  final String serialNumber; // Unique serial number for product tracking
  final String productBrand;
  final String productModel;
  final DateTime installationDate;
  final int serviceInterval; // in months: 3, 6, or 12
  final DateTime? lastServiceDate;
  final DateTime nextServiceDate;
  final DateTime? warrantyExpiry;
  final String amcStatus; // 'None', 'Active', 'Expired'
  final String notes;
  final String? photoUrl;

  Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.alternateMobile,
    required this.address,
    this.serialNumber = '', // Optional with default empty string to prevent compile breakage
    required this.productBrand,
    required this.productModel,
    required this.installationDate,
    required this.serviceInterval,
    this.lastServiceDate,
    required this.nextServiceDate,
    this.warrantyExpiry,
    required this.amcStatus,
    required this.notes,
    this.photoUrl,
  });

  // Create a Customer from a Firestore Document
  factory Customer.fromMap(Map<String, dynamic> map, String documentId) {
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

    return Customer(
      id: documentId,
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      alternateMobile: map['alternateMobile'] ?? '',
      address: map['address'] ?? '',
      serialNumber: map['serialNumber'] ?? '', // maps serialNumber with default fallback
      productBrand: map['productBrand'] ?? map['roBrand'] ?? '',
      productModel: map['productModel'] ?? map['roModel'] ?? '',
      installationDate: toDateTime(map['installationDate']) ?? DateTime.now(),
      serviceInterval: map['serviceInterval'] is int 
          ? map['serviceInterval'] 
          : int.tryParse(map['serviceInterval']?.toString() ?? '') ?? 3,
      lastServiceDate: toDateTime(map['lastServiceDate']),
      nextServiceDate: toDateTime(map['nextServiceDate']) ?? DateTime.now(),
      warrantyExpiry: toDateTime(map['warrantyExpiry']),
      amcStatus: map['amcStatus'] ?? 'None',
      notes: map['notes'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  // Convert a Customer to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobile': mobile,
      'alternateMobile': alternateMobile,
      'address': address,
      'serialNumber': serialNumber,
      'productBrand': productBrand,
      'productModel': productModel,
      'installationDate': Timestamp.fromDate(installationDate),
      'serviceInterval': serviceInterval,
      'lastServiceDate': lastServiceDate != null ? Timestamp.fromDate(lastServiceDate!) : null,
      'nextServiceDate': Timestamp.fromDate(nextServiceDate),
      'warrantyExpiry': warrantyExpiry != null ? Timestamp.fromDate(warrantyExpiry!) : null,
      'amcStatus': amcStatus,
      'notes': notes,
      'photoUrl': photoUrl,
    };
  }

  // Helper copyWith method
  Customer copyWith({
    String? id,
    String? name,
    String? mobile,
    String? alternateMobile,
    String? address,
    String? serialNumber,
    String? productBrand,
    String? productModel,
    DateTime? installationDate,
    int? serviceInterval,
    DateTime? lastServiceDate,
    DateTime? nextServiceDate,
    DateTime? warrantyExpiry,
    String? amcStatus,
    String? notes,
    String? photoUrl,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      alternateMobile: alternateMobile ?? this.alternateMobile,
      address: address ?? this.address,
      serialNumber: serialNumber ?? this.serialNumber,
      productBrand: productBrand ?? this.productBrand,
      productModel: productModel ?? this.productModel,
      installationDate: installationDate ?? this.installationDate,
      serviceInterval: serviceInterval ?? this.serviceInterval,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      amcStatus: amcStatus ?? this.amcStatus,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
