import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymos_ai/config/theme.dart';
import 'package:gymos_ai/widgets/dashboard_more_sheet.dart';

void main() {
  testWidgets('DashboardMoreSheet exposes Diet Plans and Settings actions',
      (tester) async {
    final selections = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: DashboardMoreSheet(
            onSelect: selections.add,
          ),
        ),
      ),
    );

    expect(find.text('Diet Plans'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Diet Plans'));
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(selections, [4, 5]);
  });
}
