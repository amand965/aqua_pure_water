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

    test('Should calculate 1 to 4 months service extensions correctly', () {
      final baseDate = DateTime(2026, 7, 1);
      
      expect(calculateNextServiceDate(baseDate, 1), equals(DateTime(2026, 8, 1)));
      expect(calculateNextServiceDate(baseDate, 2), equals(DateTime(2026, 9, 1)));
      expect(calculateNextServiceDate(baseDate, 3), equals(DateTime(2026, 10, 1)));
      expect(calculateNextServiceDate(baseDate, 4), equals(DateTime(2026, 11, 1)));
    });
  });

  group('Manual Date String Parsing Tests', () {
    DateTime? parseDate(String text) {
      text = text.trim();
      if (text.isEmpty) return null;
      
      final parts = text.split(RegExp(r'[/\.\-\s]+'));
      if (parts.length == 3) {
        int? p1 = int.tryParse(parts[0]);
        int? p2 = int.tryParse(parts[1]);
        int? p3 = int.tryParse(parts[2]);
        if (p1 != null && p2 != null && p3 != null) {
          int day, month, year;
          if (p1 > 1000) {
            year = p1; month = p2; day = p3;
          } else {
            day = p1; month = p2; year = p3;
          }
          try {
            final dt = DateTime(year, month, day);
            if (dt.day == day && dt.month == month && dt.year == year) {
              return dt;
            }
          } catch (_) {}
        }
      }
      return null;
    }

    test('Should parse DD/MM/YYYY format correctly', () {
      final parsed = parseDate('15/04/2026');
      expect(parsed, equals(DateTime(2026, 4, 15)));
    });

    test('Should parse DD-MM-YYYY format correctly', () {
      final parsed = parseDate('25-12-2025');
      expect(parsed, equals(DateTime(2025, 12, 25)));
    });

    test('Should parse YYYY-MM-DD format correctly', () {
      final parsed = parseDate('2026-08-24');
      expect(parsed, equals(DateTime(2026, 8, 24)));
    });

    test('Should reject invalid dates like 31/02/2026', () {
      final parsed = parseDate('31/02/2026');
      expect(parsed, isNull);
    });
  });
}
