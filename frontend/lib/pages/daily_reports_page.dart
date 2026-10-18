import 'package:flutter/material.dart';

import '../data/clinic_store.dart';
import '../widgets/clinic_ui.dart';
import '../widgets/save_dialog.dart';

class DailyReportsPage extends StatefulWidget {
  const DailyReportsPage({super.key, required this.store});
  final ClinicStore store;
  @override
  State<DailyReportsPage> createState() => _DailyReportsPageState();
}

class _DailyReportsPageState extends State<DailyReportsPage> {
  DateTime date = clinicToday();
  @override
  Widget build(BuildContext context) {
    final reports = widget.store.reports
        .where(
          (r) =>
              DateUtils.isSameDay(r.date, date) &&
              (widget.store.selectedBranch == 'All branches' ||
                  r.branch == widget.store.selectedBranch),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: clinicToday().subtract(const Duration(days: 365)),
                  lastDate: clinicToday(),
                );
                if (picked != null && mounted) setState(() => date = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(dateLabel(date)),
            ),
            FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _ReportDialog(store: widget.store, date: date),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Daily report'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        ResponsiveGrid(
          maxColumns: 3,
          children: [
            MetricCard(
              label: 'Reports submitted',
              value: '${reports.length}/${widget.store.visibleBranches.length}',
              icon: Icons.task_alt_rounded,
              detail: 'For selected date',
            ),
            MetricCard(
              label: 'Patients seen',
              value: '${reports.fold(0, (s, r) => s + r.patients)}',
              icon: Icons.people_outline,
              detail: 'Reported visits',
            ),
            MetricCard(
              label: 'Collections',
              value: money(reports.fold(0.0, (s, r) => s + r.revenue)),
              icon: Icons.payments_outlined,
              detail: 'Reported gross revenue',
              color: AppColors.green,
            ),
          ],
        ),
        const SectionTitle(
          'Branch reports',
          subtitle: 'A daily snapshot of care and operations',
        ),
        if (reports.isEmpty)
          const Panel(
            child: Center(
              child: Text(
                'No reports for this date. Add a daily report to get started.',
              ),
            ),
          ),
        for (final report in reports)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        color: AppColors.blue,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          report.branch,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const StatusPill('Submitted'),
                      IconButton(
                        tooltip: 'Edit daily report',
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _ReportDialog(
                            store: widget.store,
                            date: date,
                            report: report,
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 30,
                    runSpacing: 15,
                    children: [
                      _ReportMetric('Patients', '${report.patients}'),
                      _ReportMetric('Revenue', money(report.revenue)),
                      _ReportMetric('Expenses', money(report.expenses)),
                      _ReportMetric(
                        'Net revenue',
                        money(report.revenue - report.expenses),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Text(
                    report.notes.isEmpty
                        ? 'No operational notes.'
                        : report.notes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
    ],
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.store, required this.date, this.report});
  final ClinicStore store;
  final DateTime date;
  final DailyReport? report;
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final form = GlobalKey<FormState>();
  late String branch =
      widget.report?.branch ??
      (widget.store.selectedBranch == 'All branches'
          ? 'Pasig'
          : widget.store.selectedBranch);
  late final patients = TextEditingController(
    text: widget.report?.patients.toString() ?? '',
  );
  late final revenue = TextEditingController(
    text: widget.report?.revenue.toStringAsFixed(2) ?? '',
  );
  late final expenses = TextEditingController(
    text: widget.report?.expenses.toStringAsFixed(2) ?? '',
  );
  late final notes = TextEditingController(text: widget.report?.notes ?? '');
  @override
  void dispose() {
    patients.dispose();
    revenue.dispose();
    expenses.dispose();
    notes.dispose();
    super.dispose();
  }

  String? validNumber(String? value) {
    final n = double.tryParse(value ?? '');
    return n == null || !n.isFinite || n < 0
        ? 'Enter a valid positive amount or zero'
        : null;
  }

  @override
  Widget build(BuildContext context) => SaveDialog(
    title: Text(widget.report == null ? 'Daily report' : 'Edit report'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel(widget.date),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: branch,
                decoration: const InputDecoration(labelText: 'Branch'),
                items: widget.store.branches
                    .map(
                      (b) =>
                          DropdownMenuItem(value: b.name, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: widget.report == null
                    ? (v) => setState(() => branch = v!)
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: patients,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Patients seen'),
                validator: (v) =>
                    int.tryParse(v ?? '') == null || int.parse(v!) < 0
                    ? 'Enter a whole number of patients'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: revenue,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Gross revenue (₱)',
                ),
                validator: validNumber,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: expenses,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Operating expenses (₱)',
                ),
                validator: validNumber,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Operational notes',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Saving replaces the report for this branch and date.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
    saveLabel: 'Save report',
    onSave: () async {
      if (!form.currentState!.validate()) return false;
      await widget.store.saveReport(
        DailyReport(
          branch: branch,
          date: widget.date,
          patients: int.parse(patients.text),
          revenue: double.parse(revenue.text),
          expenses: double.parse(expenses.text),
          notes: notes.text.trim(),
        ),
      );
      return true;
    },
  );
}
