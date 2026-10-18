import 'dart:async';
import 'dart:convert';

import 'package:demo_demo/data/clinic_api.dart';
import 'package:demo_demo/data/clinic_store.dart';
import 'package:demo_demo/main.dart';
import 'package:demo_demo/widgets/save_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> branchJson() => {
  'id': 2,
  'name': 'Pasig',
  'address': 'Ortigas',
  'target': 50000,
  'growth': 18.2,
  'staff': [
    {'name': 'Sample doctor', 'role': 'Doctor', 'rating': 4.9, 'reviews': 10},
  ],
};
Map<String, dynamic> reportJson() => {
  'id': 10,
  'branch_id': 2,
  'branch': 'Pasig',
  'date': apiDate(clinicToday()),
  'patients': 20,
  'revenue': '1234.56',
  'expenses': '234.12',
  'notes': 'Stored',
};
Map<String, dynamic> batchJson() => {
  'id': 42,
  'branch_id': 2,
  'branch': 'Pasig',
  'name': 'Test medicine',
  'quantity': 5,
  'unit': 'vials',
  'expiry': apiDate(clinicToday().add(const Duration(days: 30))),
  'threshold': 10,
};
http.Response ok(Object data, {int status = 200}) => http.Response(
  jsonEncode({'data': data}),
  status,
  headers: {'content-type': 'application/json'},
);
http.Response initialGet(http.Request request) {
  final resource = request.url.pathSegments.last;
  return ok(switch (resource) {
    'branches' => [branchJson()],
    'reports' => [reportJson()],
    'medicine-batches' => [batchJson()],
    _ => [],
  });
}

ClinicStore remoteStore(MockClient client) => ClinicStore.remote(
  ClinicApi(baseUrl: 'http://clinic.test/api/v1/', client: client),
);

void main() {
  test(
    'Remote load parses Laravel decimal strings and server branch identifiers',
    () async {
      final store = remoteStore(MockClient((r) async => initialGet(r)));
      addTearDown(store.dispose);
      expect(store.isLoaded, isFalse);
      expect(store.reports, isEmpty);
      await store.load();
      expect(store.isLoaded, isTrue);
      expect(store.branches.single.id, 2);
      expect(store.revenue(1), 1234.56);
      expect(store.expenses(1), 234.12);
      expect(store.inventory.single.id, 42);
    },
  );

  test(
    'Report save uses PUT and accepts only server-confirmed values',
    () async {
      late http.Request write;
      final store = remoteStore(
        MockClient((r) async {
          if (r.method == 'GET') return initialGet(r);
          write = r;
          return ok({
            ...reportJson(),
            ...jsonDecode(r.body) as Map<String, dynamic>,
            'revenue': '2000.25',
          });
        }),
      );
      addTearDown(store.dispose);
      await store.load();
      await store.saveReport(
        DailyReport(
          branch: 'Pasig',
          date: clinicToday(),
          patients: 55,
          revenue: 2000.25,
          expenses: 250.10,
          notes: 'Changed',
        ),
      );
      expect(write.method, 'PUT');
      expect(
        write.url.path,
        '/api/v1/branches/2/reports/${apiDate(clinicToday())}',
      );
      expect(write.headers['Accept'], 'application/json');
      expect(store.reports, hasLength(1));
      expect(store.revenue(1), 2000.25);
      expect(store.patients(1), 55);
    },
  );

  test(
    'Failed writes preserve existing data and expose server validation errors',
    () async {
      final store = remoteStore(
        MockClient(
          (r) async => r.method == 'GET'
              ? initialGet(r)
              : http.Response(
                  jsonEncode({
                    'message': 'Invalid data',
                    'errors': {
                      'quantity': ['Quantity is not valid.'],
                    },
                  }),
                  422,
                ),
        ),
      );
      addTearDown(store.dispose);
      await store.load();
      await expectLater(
        store.restock(store.inventory.single, 10),
        throwsA(
          isA<ClinicApiException>().having(
            (e) => e.message,
            'message',
            'Quantity is not valid.',
          ),
        ),
      );
      expect(store.inventory.single.quantity, 5);
      final report = store.reports.single;
      await expectLater(
        store.saveReport(
          DailyReport(
            branch: 'Pasig',
            date: clinicToday(),
            patients: 99,
            revenue: 1,
            expenses: 0,
            notes: 'Rejected',
          ),
        ),
        throwsA(isA<ClinicApiException>()),
      );
      expect(identical(store.reports.single, report), isTrue);
    },
  );

  test('Batch creation uses server ID; restock and correction use distinct operations', () async {
    final writes = <http.Request>[];
    final store = remoteStore(
      MockClient((r) async {
        if (r.method == 'GET') return initialGet(r);
        writes.add(r);
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        if (r.method == 'POST') {
          return ok({...batchJson(), ...body, 'id': 99}, status: 201);
        }
        return ok({
          ...batchJson(),
          'quantity': body['operation'] == 'set' ? body['quantity'] : 18,
        });
      }),
    );
    addTearDown(store.dispose);
    await store.load();
    await store.restock(store.inventory.first, 10);
    expect(store.inventory.first.quantity, 18);
    expect(jsonDecode(writes.last.body)['operation'], 'restock');
    await store.updateStock(store.inventory.first, 0, adding: false);
    expect(store.inventory.first.quantity, 0);
    expect(jsonDecode(writes.last.body)['operation'], 'set');
    await store.addBatch(
      MedicineBatch(
        id: 999,
        branch: 'Pasig',
        name: 'New',
        quantity: 4,
        unit: 'boxes',
        expiry: clinicToday(),
        threshold: 2,
      ),
    );
    expect(store.inventory.last.id, 99);
    expect(jsonDecode(writes.last.body)['branch_id'], 2);
    expect(jsonDecode(writes.last.body).containsKey('id'), isFalse);
  });

  test(
    'Refresh failure retains the last snapshot without switching to demo data',
    () async {
      var failing = false;
      final store = remoteStore(
        MockClient((r) async {
          if (failing) throw http.ClientException('offline');
          return initialGet(r);
        }),
      );
      addTearDown(store.dispose);
      await store.load();
      failing = true;
      await store.load();
      expect(store.loadError, contains('Cannot connect'));
      expect(store.isLoaded, isTrue);
      expect(store.branches, hasLength(1));
      expect(store.revenue(1), 1234.56);
    },
  );

  testWidgets('Connection errors show Retry and recover into the dashboard', (
    tester,
  ) async {
    var failing = true;
    final store = remoteStore(
      MockClient((r) async {
        if (failing) throw http.ClientException('offline');
        return initialGet(r);
      }),
    );
    await tester.pumpWidget(MyApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Connection unavailable'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    failing = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    expect(
      find.text('Local clinic server · Changes saved to database'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Save dialog blocks duplicate submissions and preserves input on failure',
    (tester) async {
      final pending = Completer<bool>();
      var attempts = 0;
      final controller = TextEditingController(text: 'Keep this input');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => SaveDialog(
                    title: const Text('Edit'),
                    content: TextField(controller: controller),
                    saveLabel: 'Save',
                    onSave: () {
                      attempts++;
                      return pending.future;
                    },
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(attempts, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      pending.completeError(
        const ClinicApiException('Server rejected this save.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Server rejected this save.'), findsOneWidget);
      expect(controller.text, 'Keep this input');
      expect(find.text('Edit'), findsOneWidget);
    },
  );
}
