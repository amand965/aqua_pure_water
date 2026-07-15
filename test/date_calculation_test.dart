import 'package:flutter_test/flutter_test.dart';

// The logic used in DatabaseService.addServiceRecord to calculate the next service date.
DateTime calculateNextServiceDate(DateTime lastServiceDate, int intervalMonths) {
  return DateTime(
    lastServiceDate.year,
    lastServiceDate.month + intervalMonths,
    lastServiceDate.day,
  );
}

void main() {
  group('RO Service Interval Date Calculations', () {
    test('Should calculate 3 months interval correctly', () {
      final lastServiceDate = DateTime(2026, 1, 15); // Jan 15
      final nextServiceDate = calculateNextServiceDate(lastServiceDate, 3);
      
      expect(nextServiceDate.year, equals(2026));
      expect(nextServiceDate.month, equals(4)); // April
      expect(nextServiceDate.day, equals(15));
    });

    test('Should calculate 6 months interval correctly', () {
      final lastServiceDate = DateTime(2026, 5, 20); // May 20
      final nextServiceDate = calculateNextServiceDate(lastServiceDate, 6);
      
      expect(nextServiceDate.year, equals(2026));
      expect(nextServiceDate.month, equals(11)); // Nov
      expect(nextServiceDate.day, equals(20));
    });

    test('Should calculate 12 months interval correctly (yearly rollover)', () {
      final lastServiceDate = DateTime(2026, 10, 10); // Oct 10, 2026
      final nextServiceDate = calculateNextServiceDate(lastServiceDate, 12);
      
      expect(nextServiceDate.year, equals(2027)); // Year rollovers to 2027
      expect(nextServiceDate.month, equals(10)); // Oct
      expect(nextServiceDate.day, equals(10));
    });

    test('Should handle leap year rollover correctly', () {
      // Leap year: 2028 is a leap year (Feb has 29 days)
      final lastServiceDate = DateTime(2028, 2, 29); 
      final nextServiceDate = calculateNextServiceDate(lastServiceDate, 12); // add 12 months (Feb 29, 2029)
      
      // Since 2029 is not a leap year, DateTime constructor will automatically normalize Feb 29, 2029 to March 1, 2029.
      expect(nextServiceDate.year, equals(2029));
      expect(nextServiceDate.month, equals(3)); // March
      expect(nextServiceDate.day, equals(1)); // 1st
    });

    test('Should handle month end overflows correctly', () {
      // March 31 + 3 months = June 31 (but June only has 30 days)
      final lastServiceDate = DateTime(2026, 3, 31);
      final nextServiceDate = calculateNextServiceDate(lastServiceDate, 3);
      
      // DateTime normalizes June 31 to July 1 automatically
      expect(nextServiceDate.year, equals(2026));
      expect(nextServiceDate.month, equals(7)); // July
      expect(nextServiceDate.day, equals(1)); // 1st
    });
  });
}
