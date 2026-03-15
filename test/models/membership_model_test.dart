import 'package:flutter_test/flutter_test.dart';
import 'package:gymos_ai/core/database_values.dart';
import 'package:gymos_ai/core/enums.dart';
import 'package:gymos_ai/models/membership_model.dart';

void main() {
  group('Membership', () {
    test('uses the shared default currency', () {
      final membership = Membership(
        id: 'mem-1',
        clientId: 'client-1',
        gymId: 'gym-1',
        planName: 'Monthly',
        startDate: DateTime.parse('2026-03-01'),
        endDate: DateTime.parse('2026-04-01'),
        createdAt: DateTime.parse('2026-03-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-03-01T00:00:00Z'),
      );

      expect(membership.currency, DatabaseValues.defaultCurrency);
    });

    test('isActive becomes false when an active membership is expired', () {
      final membership = Membership(
        id: 'mem-2',
        clientId: 'client-1',
        gymId: 'gym-1',
        planName: 'Monthly',
        status: MembershipStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 40)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(membership.isExpired, isTrue);
      expect(membership.isActive, isFalse);
    });
  });
}
