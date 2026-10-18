import 'package:flutter/material.dart';

import 'clinic_api.dart';
import 'clinic_models.dart';
export 'clinic_models.dart';

class ClinicStore extends ChangeNotifier {
  ClinicStore() : _api = null {
    branches.addAll(const [
      Branch('Laguna', 'Santa Rosa, Laguna', 45000, 12.4, [
        StaffMember('Dr. Sofia Reyes', 'Branch physician', 4.9, 128),
        StaffMember('Anna Garcia', 'Head nurse', 4.8, 96),
      ]),
      Branch('Pasig', 'Ortigas Center, Pasig', 50000, 18.2, [
        StaffMember('Dr. Miguel Santos', 'Branch physician', 4.9, 156),
        StaffMember('Maria Cruz', 'Head nurse', 4.9, 112),
      ]),
      Branch('Caloocan', 'Grace Park, Caloocan', 40000, 8.7, [
        StaffMember('Dr. Isabel Lim', 'Branch physician', 4.8, 104),
        StaffMember('Paolo Ramos', 'Head nurse', 4.7, 82),
      ]),
      Branch('Parañaque', 'BF Homes, Parañaque', 45000, 14.6, [
        StaffMember('Dr. Lucas Tan', 'Branch physician', 4.9, 119),
        StaffMember('Ella Flores', 'Head nurse', 4.8, 91),
      ]),
      Branch('Quezon City', 'Diliman, Quezon City', 55000, 21.3, [
        StaffMember('Dr. Andrea Torres', 'Branch physician', 5.0, 142),
        StaffMember('Carlo Mendoza', 'Head nurse', 4.9, 103),
      ]),
      Branch('Valenzuela', 'Marulas, Valenzuela', 40000, 9.8, [
        StaffMember('Dr. Rafael Dela Cruz', 'Branch physician', 4.8, 98),
        StaffMember('Nina Bautista', 'Head nurse', 4.8, 77),
      ]),
    ]);
    final today = clinicToday();
    for (var b = 0; b < branches.length; b++) {
      for (var day = 29; day >= 0; day--) {
        final patients = 24 + ((b * 11 + (29 - day) * 7) % 34);
        reports.add(
          DailyReport(
            branch: branches[b].name,
            date: today.subtract(Duration(days: day)),
            patients: patients,
            revenue: patients * (720.0 + b * 65),
            expenses: patients * (260.0 + b * 23),
            notes: 'Daily operations completed.',
          ),
        );
      }
      const names = [
        'Lidocaine 2%',
        'Paracetamol 500 mg',
        'Amoxicillin 500 mg',
        'Ibuprofen 200 mg',
        'Cetirizine 10 mg',
        'Alcohol 70%',
      ];
      const units = [
        'vials',
        'tablets',
        'capsules',
        'tablets',
        'tablets',
        'bottles',
      ];
      for (var m = 0; m < names.length; m++) {
        inventory.add(
          MedicineBatch(
            id: b * 6 + m,
            branch: branches[b].name,
            name: names[m],
            quantity: m == 0 && b.isEven ? 8 + b : 65 + b * 17 + m * 23,
            unit: units[m],
            expiry: today.add(
              Duration(days: m == 2 && b < 2 ? 24 : 160 + m * 38 + b * 9),
            ),
            threshold: m == 0 ? 20 : 40,
          ),
        );
      }
    }
  }

  ClinicStore.remote(ClinicApi api) : _api = api;

  final ClinicApi? _api;
  final List<Branch> branches = [];
  bool get isRemote => _api != null;
  bool get isLoaded => !isRemote || _loaded;
  bool _loaded = false;
  bool isLoading = false;
  String? loadError;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _api?.close();
    super.dispose();
  }

  Future<void> load() async {
    if (!isRemote || isLoading) return;
    isLoading = true;
    loadError = null;
    _notify();
    try {
      final snapshot = await _api!.load();
      if (_disposed) return;
      branches
        ..clear()
        ..addAll(snapshot.branches);
      reports
        ..clear()
        ..addAll(snapshot.reports);
      inventory
        ..clear()
        ..addAll(snapshot.inventory);
      if (!branches.any((b) => b.name == selectedBranch)) {
        selectedBranch = 'All branches';
      }
      _loaded = true;
    } catch (error) {
      if (!_disposed) loadError = error.toString();
    } finally {
      isLoading = false;
      _notify();
    }
  }

  int _branchId(String name) => branches.firstWhere((b) => b.name == name).id!;
  final List<MedicineBatch> inventory = [];
  final List<DailyReport> reports = [];
  String selectedBranch = 'All branches';

  void selectBranch(String value) {
    selectedBranch = value;
    _notify();
  }

  List<Branch> get visibleBranches => branches
      .where(
        (b) => selectedBranch == 'All branches' || b.name == selectedBranch,
      )
      .toList();
  List<MedicineBatch> batches([String? branch]) => inventory
      .where(
        (m) =>
            (branch ?? selectedBranch) == 'All branches' ||
            m.branch == (branch ?? selectedBranch),
      )
      .toList();
  List<DailyReport> periodReports(int days, {String? branch}) {
    final start = clinicToday().subtract(Duration(days: days - 1));
    return reports
        .where(
          (r) =>
              !r.date.isBefore(start) &&
              ((branch ?? selectedBranch) == 'All branches' ||
                  r.branch == (branch ?? selectedBranch)),
        )
        .toList();
  }

  double revenue(int days, {String? branch}) => periodReports(
    days,
    branch: branch,
  ).fold(0.0, (sum, r) => sum + r.revenue);
  double expenses(int days, {String? branch}) => periodReports(
    days,
    branch: branch,
  ).fold(0.0, (sum, r) => sum + r.expenses);
  int patients(int days, {String? branch}) =>
      periodReports(days, branch: branch).fold(0, (sum, r) => sum + r.patients);
  List<MedicineBatch> get alerts =>
      batches().where((m) => m.needsAttention).toList();
  Future<void> addBatch(MedicineBatch batch) async {
    final saved = _api == null
        ? batch
        : await _api.addBatch(batch, _branchId(batch.branch));
    if (_disposed) return;
    inventory.add(saved);
    _notify();
  }

  Future<void> restock(MedicineBatch batch, int amount) =>
      updateStock(batch, amount, adding: true);

  Future<void> updateStock(
    MedicineBatch batch,
    int quantity, {
    required bool adding,
  }) async {
    if ((adding && quantity < 1) || (!adding && quantity < 0)) {
      throw ArgumentError('Enter a valid nonnegative quantity.');
    }
    if (_api == null) {
      batch.quantity = adding ? batch.quantity + quantity : quantity;
    } else {
      final saved = await _api.updateStock(batch.id, quantity, adding: adding);
      if (_disposed) return;
      final index = inventory.indexWhere((m) => m.id == saved.id);
      if (index >= 0) inventory[index] = saved;
    }
    _notify();
  }

  Future<void> saveReport(DailyReport report) async {
    final saved = _api == null
        ? report
        : await _api.saveReport(report, _branchId(report.branch));
    if (_disposed) return;
    reports.removeWhere(
      (r) =>
          r.branch == saved.branch && DateUtils.isSameDay(r.date, saved.date),
    );
    reports.add(saved);
    _notify();
  }
}
