import 'package:flutter/material.dart';

import '../data/clinic_store.dart';
import '../widgets/clinic_ui.dart';
import '../widgets/app_motion.dart';
import 'inventory_page.dart';

class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key, required this.store});
  final ClinicStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Six communities. One standard of care.',
        style: TextStyle(color: AppColors.muted, height: 1.6),
      ),
      const SizedBox(height: 22),
      ResponsiveGrid(
        maxColumns: 3,
        minWidth: 260,
        children: store.visibleBranches
            .map(
              (b) => MotionFeedback(
                child: BranchCard(store: store, branch: b),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class BranchCard extends StatelessWidget {
  const BranchCard({super.key, required this.store, required this.branch});
  final ClinicStore store;
  final Branch branch;
  @override
  Widget build(BuildContext context) {
    final revenue = store.revenue(1, branch: branch.name);
    final progress = (revenue / branch.target).clamp(0.0, 1.0);
    final alerts = store
        .batches(branch.name)
        .where((b) => b.needsAttention)
        .length;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => BranchDetailPage(store: store, branch: branch),
        ),
      ),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.local_hospital_outlined,
                    color: AppColors.blue,
                    size: 22,
                  ),
                ),
                const Spacer(),
                StatusPill(
                  revenue >= branch.target ? 'On target' : 'Below target',
                  color: revenue >= branch.target
                      ? AppColors.green
                      : AppColors.orange,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(branch.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              branch.address,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${store.patients(1, branch: branch.name)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Patients today',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        money(revenue),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.7,
                        ),
                      ),
                      const Text(
                        'Revenue today',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.line,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              '${(progress * 100).round()}% of ${money(branch.target)} daily target',
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            Row(
              children: [
                Icon(
                  alerts > 0
                      ? Icons.info_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: alerts > 0 ? AppColors.orange : AppColors.green,
                ),
                const SizedBox(width: 5),
                Text(
                  alerts > 0 ? '$alerts inventory alerts' : 'Inventory healthy',
                  style: TextStyle(
                    fontSize: 10,
                    color: alerts > 0 ? AppColors.orange : AppColors.green,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: AppColors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BranchDetailPage extends StatelessWidget {
  const BranchDetailPage({
    super.key,
    required this.store,
    required this.branch,
  });
  final ClinicStore store;
  final Branch branch;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final stock = store.batches(branch.name);
      return Scaffold(
        appBar: AppBar(title: Text('${branch.name} branch')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.address,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  ResponsiveGrid(
                    children: [
                      MetricCard(
                        label: 'Patients today',
                        value: '${store.patients(1, branch: branch.name)}',
                        icon: Icons.people_outline,
                        detail: 'Daily patient visits',
                      ),
                      MetricCard(
                        label: 'Revenue today',
                        value: money(store.revenue(1, branch: branch.name)),
                        icon: Icons.payments_outlined,
                        detail: 'Target ${money(branch.target)}',
                        color: AppColors.green,
                      ),
                      MetricCard(
                        label: '30-day visits',
                        value: '${store.patients(30, branch: branch.name)}',
                        icon: Icons.monitor_heart_outlined,
                        detail: 'Last 30 days',
                      ),
                      MetricCard(
                        label: 'Medicine batches',
                        value: '${stock.length}',
                        icon: Icons.medication_outlined,
                        detail:
                            '${stock.where((m) => m.needsAttention).length} need attention',
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                  const SectionTitle(
                    'Daily patient activity',
                    subtitle: 'Last 7 days',
                  ),
                  Panel(
                    child: TrendChart(
                      values: List.generate(7, (i) {
                        final d = clinicToday().subtract(Duration(days: 6 - i));
                        return store
                            .periodReports(7, branch: branch.name)
                            .where((r) => DateUtils.isSameDay(r.date, d))
                            .fold(0.0, (sum, r) => sum + r.patients);
                      }),
                      labels: List.generate(
                        7,
                        (i) =>
                            '${clinicToday().subtract(Duration(days: 6 - i)).day}',
                      ),
                    ),
                  ),
                  SectionTitle(
                    'Medicine inventory',
                    subtitle: 'Batch quantities and expiry monitoring',
                    action: 'Manage ↗',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            InventoryPage(store: store, branch: branch.name),
                      ),
                    ),
                  ),
                  Panel(
                    child: Column(
                      children: stock
                          .map(
                            (m) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.medication_outlined,
                                    color: AppColors.blue,
                                    size: 20,
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
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${m.quantity} ${m.unit} · Exp ${dateLabel(m.expiry)}',
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
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SectionTitle(
                    'Your care team',
                    subtitle: 'Staff ratings from patient feedback',
                  ),
                  Panel(
                    child: Column(
                      children: branch.staff
                          .map((s) => StaffTile(staff: s, branch: branch.name))
                          .toList(),
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
