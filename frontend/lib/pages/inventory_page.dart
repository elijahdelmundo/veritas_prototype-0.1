import 'package:flutter/material.dart';

import '../data/clinic_store.dart';
import '../widgets/clinic_ui.dart';
import '../widgets/save_dialog.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.store,
    this.branch,
    this.alertsOnly = false,
  });
  final ClinicStore store;
  final String? branch;
  final bool alertsOnly;
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String query = '';
  late bool alertsOnly = widget.alertsOnly;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final all = widget.store.batches(widget.branch);
      final batches = all
          .where(
            (m) =>
                (!alertsOnly || m.needsAttention) &&
                '${m.name} ${m.branch}'.toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Medicine inventory')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) =>
                _BatchDialog(store: widget.store, branch: widget.branch),
          ),
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add medicine'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.branch ?? widget.store.selectedBranch,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track every batch. Stay ahead of low stock and expiry.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ResponsiveGrid(
                    maxColumns: 3,
                    minWidth: 140,
                    children: [
                      MetricCard(
                        label: 'Medicine batches',
                        value: '${all.length}',
                        icon: Icons.medication_outlined,
                        detail: 'In selected branches',
                      ),
                      MetricCard(
                        label: 'Low stock',
                        value: '${all.where((m) => m.low).length}',
                        icon: Icons.inventory_2_outlined,
                        detail: 'At or below threshold',
                        color: AppColors.orange,
                      ),
                      MetricCard(
                        label: 'Expiry alerts',
                        value:
                            '${all.where((m) => m.expired || m.expiring).length}',
                        icon: Icons.event_outlined,
                        detail: 'Expired or within 60 days',
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search medicine or branch',
                      prefixIcon: Icon(Icons.search_rounded),
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All medicines'),
                        selected: !alertsOnly,
                        onSelected: (_) => setState(() => alertsOnly = false),
                      ),
                      ChoiceChip(
                        label: const Text('Needs attention'),
                        selected: alertsOnly,
                        onSelected: (_) => setState(() => alertsOnly = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (batches.isEmpty)
                    const Panel(
                      child: Center(
                        child: Text('No medicine batches match your filters.'),
                      ),
                    ),
                  for (final m in batches)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Panel(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.medication_outlined,
                                    color: AppColors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${m.branch} · Batch VC-${m.id.toString().padLeft(4, '0')}',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(
                                  m.status,
                                  color: m.needsAttention
                                      ? AppColors.orange
                                      : AppColors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 24,
                              runSpacing: 12,
                              children: [
                                _Info('ON HAND', '${m.quantity} ${m.unit}'),
                                _Info('EXPIRY DATE', dateLabel(m.expiry)),
                                _Info(
                                  'LOW STOCK AT',
                                  '${m.threshold} ${m.unit}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: m.expired
                                      ? null
                                      : () => showDialog<void>(
                                          context: context,
                                          builder: (_) => _StockDialog(
                                            store: widget.store,
                                            batch: m,
                                          ),
                                        ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Adjust stock'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: m.expired
                                      ? null
                                      : () => showDialog<void>(
                                          context: context,
                                          builder: (_) => _StockDialog(
                                            store: widget.store,
                                            batch: m,
                                            adding: true,
                                          ),
                                        ),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Restock'),
                                ),
                              ],
                            ),
                            if (m.expired)
                              const Text(
                                'Expired batch. Add a new batch with a valid expiry date.',
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: .7,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _StockDialog extends StatefulWidget {
  const _StockDialog({
    required this.store,
    required this.batch,
    this.adding = false,
  });
  final ClinicStore store;
  final MedicineBatch batch;
  final bool adding;
  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SaveDialog(
    title: Text(widget.adding ? 'Restock medicine' : 'Adjust stock'),
    content: SizedBox(
      width: 350,
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.batch.name} · ${widget.batch.branch}'),
            const SizedBox(height: 8),
            Text(
              'Current: ${widget.batch.quantity} ${widget.batch.unit}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.adding
                    ? 'Quantity to add'
                    : 'New on-hand quantity',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < (widget.adding ? 1 : 0)
                    ? 'Enter a valid whole number'
                    : null;
              },
            ),
          ],
        ),
      ),
    ),
    saveLabel: 'Save stock',
    onSave: () async {
      if (!form.currentState!.validate()) return false;
      await widget.store.updateStock(
        widget.batch,
        int.parse(amount.text),
        adding: widget.adding,
      );
      return true;
    },
  );
}

class _BatchDialog extends StatefulWidget {
  const _BatchDialog({required this.store, this.branch});
  final ClinicStore store;
  final String? branch;
  @override
  State<_BatchDialog> createState() => _BatchDialogState();
}

class _BatchDialogState extends State<_BatchDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final quantity = TextEditingController();
  final threshold = TextEditingController(text: '20');
  String unit = 'vials';
  late String branch =
      widget.branch ??
      (widget.store.selectedBranch == 'All branches'
          ? 'Pasig'
          : widget.store.selectedBranch);
  DateTime? expiry;
  String? expiryError;
  @override
  void dispose() {
    name.dispose();
    quantity.dispose();
    threshold.dispose();
    super.dispose();
  }

  String? number(String? v) =>
      int.tryParse(v ?? '') == null || int.parse(v!) < 0
      ? 'Enter zero or a positive whole number'
      : null;
  @override
  Widget build(BuildContext context) => SaveDialog(
    title: const Text('Add medicine batch'),
    content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: branch,
                decoration: const InputDecoration(labelText: 'Branch'),
                items: widget.store.branches
                    .map(
                      (b) =>
                          DropdownMenuItem(value: b.name, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => branch = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Medicine name & strength',
                  hintText: 'e.g. Lidocaine 2%',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a medicine name'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: quantity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items:
                          ['vials', 'tablets', 'capsules', 'bottles', 'boxes']
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                      onChanged: (v) => unit = v!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: threshold,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low-stock alert threshold',
                ),
                validator: number,
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.event_outlined,
                  color: AppColors.blue,
                ),
                title: Text(
                  expiry == null ? 'Select expiry date' : dateLabel(expiry!),
                ),
                subtitle: expiryError == null
                    ? null
                    : Text(
                        expiryError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        expiry ?? clinicToday().add(const Duration(days: 365)),
                    firstDate: clinicToday(),
                    lastDate: clinicToday().add(const Duration(days: 3650)),
                  );
                  if (date != null && mounted) {
                    setState(() {
                      expiry = date;
                      expiryError = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
    saveLabel: 'Add batch',
    onSave: () async {
      final valid = form.currentState!.validate();
      if (expiry == null) {
        setState(() => expiryError = 'An expiry date is required');
      }
      if (!valid || expiry == null) return false;
      final id =
          widget.store.inventory.fold(0, (max, m) => m.id > max ? m.id : max) +
          1;
      await widget.store.addBatch(
        MedicineBatch(
          id: id,
          branch: branch,
          name: name.text.trim(),
          quantity: int.parse(quantity.text),
          unit: unit,
          expiry: expiry!,
          threshold: int.parse(threshold.text),
        ),
      );
      return true;
    },
  );
}
