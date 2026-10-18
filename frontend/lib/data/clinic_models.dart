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
  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    json['name'] as String,
    json['role'] as String,
    _number(json['rating']),
    json['reviews'] as int,
  );
  final String name;
  final String role;
  final double rating;
  final int reviews;
}

class Branch {
  const Branch(
    this.name,
    this.address,
    this.target,
    this.growth,
    this.staff, {
    this.id,
  });
  final int? id;
  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    json['name'] as String,
    json['address'] as String,
    json['target'] as int,
    _number(json['growth']),
    (json['staff'] as List)
        .map((s) => StaffMember.fromJson(s as Map<String, dynamic>))
        .toList(),
    id: json['id'] as int,
  );
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
  factory MedicineBatch.fromJson(Map<String, dynamic> json) => MedicineBatch(
    id: json['id'] as int,
    branch: json['branch'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    unit: json['unit'] as String,
    expiry: DateTime.parse(json['expiry'] as String),
    threshold: json['threshold'] as int,
  );
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
  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
    branch: json['branch'] as String,
    date: DateTime.parse(json['date'] as String),
    patients: json['patients'] as int,
    revenue: _number(json['revenue']),
    expenses: _number(json['expenses']),
    notes: json['notes'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {
    'patients': patients,
    'revenue': revenue,
    'expenses': expenses,
    'notes': notes,
  };
  final int patients;
  final double revenue;
  final double expenses;
  final String notes;
}

double _number(Object? value) =>
    value is num ? value.toDouble() : double.parse(value as String);

String apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
