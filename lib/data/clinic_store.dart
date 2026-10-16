import 'package:flutter/material.dart';

String money(num amount) {
  final digits = amount.round().toString();
  return '₱${digits.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

String dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

DateTime clinicToday() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 8));
  return DateTime(now.year, now.month, now.day);
}

class StaffMember {
  const StaffMember(this.name, this.role, this.rating, this.reviews);
  final String name;
  final String role;
  final double rating;
  final int reviews;
}

class Branch {
  const Branch(this.name, this.address, this.target, this.growth, this.staff);
  final String name;
  final String address;
  final int target;
  final double growth;
  final List<StaffMember> staff;
}

class MedicineBatch {
  MedicineBatch({
    required this.id,
    required this.branch,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.expiry,
    required this.threshold,
  });
  final int id;
  final String branch;
  final String name;
  int quantity;
  final String unit;
  final DateTime expiry;
  final int threshold;
  bool get low => quantity <= threshold;
  bool get expired => expiry.isBefore(clinicToday());
  bool get expiring =>
      !expired && expiry.difference(clinicToday()).inDays <= 60;
  bool get needsAttention => low || expired || expiring;
  String get status => expired
      ? 'Expired'
      : low
      ? 'Low stock'
      : expiring
      ? 'Expiring soon'
      : 'Healthy';
}

class DailyReport {
  DailyReport({
    required this.branch,
    required this.date,
    required this.patients,
    required this.revenue,
    required this.expenses,
    required this.notes,
  });
  final String branch;
  final DateTime date;
  final int patients;
  final double revenue;
  final double expenses;
  final String notes;
}

class ClinicStore extends ChangeNotifier {
  ClinicStore() {
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

  final List<Branch> branches = const [
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
  ];
  final List<MedicineBatch> inventory = [];
  final List<DailyReport> reports = [];
  String selectedBranch = 'All branches';

  void selectBranch(String value) {
    selectedBranch = value;
    notifyListeners();
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
  void addBatch(MedicineBatch batch) {
    inventory.add(batch);
    notifyListeners();
  }

  void restock(MedicineBatch batch, int amount) {
    batch.quantity += amount;
    notifyListeners();
  }

  void saveReport(DailyReport report) {
    reports.removeWhere(
      (r) =>
          r.branch == report.branch && DateUtils.isSameDay(r.date, report.date),
    );
    reports.add(report);
    notifyListeners();
  }
}
