import 'package:flutter_test/flutter_test.dart';
import 'package:demo_demo/data/clinic_store.dart';

void main() {
  test('Branch filtering isolates visits, revenue, and inventory', () {
    final store = ClinicStore();
    addTearDown(store.dispose);
    final total = store.revenue(1);
    store.selectBranch('Pasig');
    expect(store.visibleBranches.single.name, 'Pasig');
    expect(store.batches().every((b) => b.branch == 'Pasig'), isTrue);
    expect(store.revenue(1), lessThan(total));
    expect(store.patients(1), store.periodReports(1).single.patients);
  });

  test('Report replacement updates totals without double counting', () {
    final store = ClinicStore();
    addTearDown(store.dispose);
    final size = store.reports.length;
    store.saveReport(
      DailyReport(
        branch: 'Pasig',
        date: clinicToday(),
        patients: 100,
        revenue: 50000,
        expenses: 10000,
        notes: 'Updated',
      ),
    );
    expect(store.reports.length, size);
    expect(store.revenue(1, branch: 'Pasig'), 50000);
    expect(store.patients(1, branch: 'Pasig'), 100);
    expect(store.expenses(1, branch: 'Pasig'), 10000);
  });

  test('Restocking clears low stock while retaining expiry alerts', () {
    final store = ClinicStore();
    addTearDown(store.dispose);
    final batch = store.inventory.firstWhere((m) => m.low);
    store.restock(batch, 100);
    expect(batch.low, isFalse);
    final nearExpiry = MedicineBatch(
      id: 99,
      branch: 'Pasig',
      name: 'Test',
      quantity: 5,
      unit: 'vials',
      expiry: clinicToday().add(const Duration(days: 2)),
      threshold: 10,
    );
    store.addBatch(nearExpiry);
    store.restock(nearExpiry, 100);
    expect(nearExpiry.expiring, isTrue);
    expect(store.alerts, contains(nearExpiry));
    final expired = MedicineBatch(
      id: 100,
      branch: 'Pasig',
      name: 'Test',
      quantity: 50,
      unit: 'vials',
      expiry: clinicToday().subtract(const Duration(days: 1)),
      threshold: 10,
    );
    expect(expired.status, 'Expired');
  });
}
