import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_demo/main.dart';

void main() {
  testWidgets('Phone navigation opens all five owner views', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.text('Overview'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in [
      'Daily reports',
      'Statistics',
      'Revenue',
      'Branches',
      'Home',
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tap(find.byTooltip('Stock & expiry alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Medicine inventory'), findsOneWidget);
    expect(find.text('Lidocaine 2%'), findsWidgets);
    await tester.ensureVisible(find.text('Restock').first);
    final initialAlerts = find.text('Restock').evaluate().length;
    await tester.tap(find.text('Restock').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '30');
    await tester.tap(find.text('Save stock'));
    await tester.pumpAndSettle();
    expect(
      find.text('Restock').evaluate().length,
      initialAlerts - 1,
      reason: 'Restocked batch leaves the attention filter',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Report edits update the owner dashboard', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Daily reports'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Edit daily report').first);
    await tester.tap(find.byTooltip('Edit daily report').first);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '100000');
    await tester.enterText(fields.at(2), '20000');
    await tester.tap(find.text('Save report'));
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
    expect(find.text('₱80,000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Branch details and medicine entry work together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Branches'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pasig').first);
    await tester.tap(find.text('Pasig').first);
    await tester.pumpAndSettle();
    expect(find.text('Pasig branch'), findsOneWidget);
    expect(find.text('Dr. Miguel Santos'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Branch detail layout');
    await tester.ensureVisible(find.text('Manage ↗'));
    await tester.tap(find.text('Manage ↗'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add medicine'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Medicine dialog layout');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Bupivacaine 0.5%');
    await tester.enterText(fields.at(1), '50');
    await tester.enterText(fields.at(2), '10');
    await tester.ensureVisible(find.text('Select expiry date'));
    await tester.tap(find.text('Select expiry date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Expiry selection layout');
    await tester.tap(find.text('Add batch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Bupivacaine');
    await tester.pumpAndSettle();
    expect(find.text('Bupivacaine 0.5%'), findsOneWidget);
    expect(find.text('50 vials'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1440.0]) {
    testWidgets('Dashboard layout at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
