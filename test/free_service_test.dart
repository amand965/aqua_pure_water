import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_pure_water/models/service_record.dart';

void main() {
  group('Free Service Functionality Tests', () {
    test('ServiceRecord correctly encodes and decodes Free Service status with 0.0 charges', () {
      final record = ServiceRecord(
        id: 'serv_123',
        customerId: 'cust_abc',
        serviceDate: DateTime(2026, 9, 10),
        technicianName: 'Rajesh Kumar',
        workDone: 'Filter cleaning and TDS test',
        partsReplaced: 'Sediment Filter',
        charges: 0.0,
        paymentStatus: 'Free Service',
        notes: 'Complimentary first service',
        photoUrls: [],
      );

      final map = record.toMap();
      expect(map['paymentStatus'], equals('Free Service'));
      expect(map['charges'], equals(0.0));

      final restored = ServiceRecord.fromMap(map, 'serv_123');
      expect(restored.paymentStatus, equals('Free Service'));
      expect(restored.charges, equals(0.0));
      expect(restored.technicianName, equals('Rajesh Kumar'));
    });

    test('Filtering logic accurately identifies free services vs paid or pending', () {
      final services = [
        ServiceRecord(
          id: '1',
          customerId: 'c1',
          serviceDate: DateTime(2026, 9, 1),
          technicianName: 'Tech 1',
          workDone: 'RO service',
          partsReplaced: '',
          charges: 0.0,
          paymentStatus: 'Free Service',
          notes: '',
          photoUrls: [],
        ),
        ServiceRecord(
          id: '2',
          customerId: 'c2',
          serviceDate: DateTime(2026, 9, 2),
          technicianName: 'Tech 2',
          workDone: 'Membrane change',
          partsReplaced: 'Membrane',
          charges: 1200.0,
          paymentStatus: 'Paid',
          notes: '',
          photoUrls: [],
        ),
        ServiceRecord(
          id: '3',
          customerId: 'c3',
          serviceDate: DateTime(2026, 9, 3),
          technicianName: 'Tech 3',
          workDone: 'General checkup',
          partsReplaced: '',
          charges: 350.0,
          paymentStatus: 'Pending',
          notes: '',
          photoUrls: [],
        ),
        ServiceRecord(
          id: '4',
          customerId: 'c4',
          serviceDate: DateTime(2026, 9, 4),
          technicianName: 'Tech 1',
          workDone: 'Free warranty maintenance',
          partsReplaced: '',
          charges: 0.0,
          paymentStatus: 'Free Service',
          notes: '',
          photoUrls: [],
        ),
      ];

      final freeServices = services.where((s) => s.paymentStatus == 'Free Service').toList();
      final paidServices = services.where((s) => s.paymentStatus == 'Paid').toList();
      final pendingServices = services.where((s) => s.paymentStatus == 'Pending').toList();

      expect(freeServices.length, equals(2));
      expect(paidServices.length, equals(1));
      expect(pendingServices.length, equals(1));

      // Verify charges are strictly 0.0 for all free services
      for (final s in freeServices) {
        expect(s.charges, equals(0.0));
      }
    });
  });
}
