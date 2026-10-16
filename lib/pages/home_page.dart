import 'package:flutter/material.dart';

import '../data/clinic_store.dart';
import '../widgets/clinic_ui.dart';
import 'branches_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.store,
    required this.onNavigate,
    required this.onInventory,
  });
  final ClinicStore store;
  final ValueChanged<int> onNavigate;
  final void Function({bool alerts}) onInventory;

  @override
  Widget build(BuildContext context) {
    final alerts = store.alerts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF164FCB), Color(0xFF367EFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .09),
                      width: 40,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -65,
                child: Icon(
                  Icons.add_rounded,
                  size: 220,
                  color: Colors.white.withValues(alpha: .06),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFA4EDCB),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Flexible(
                          child: Text(
                            'YOUR NETWORK AT A GLANCE',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.5,
                              color: Color(0xFFCEDEFF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A clearer view.\nBetter care.',
                      style: TextStyle(
                        fontSize: 32,
                        height: 1.15,
                        letterSpacing: -.9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${store.visibleBranches.length} branches. One connected team.\nHere’s how your clinics are doing today.',
                      style: const TextStyle(
                        color: Color(0xFFDBE7FF),
                        height: 1.7,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                      ),
                      onPressed: () => onNavigate(1),
                      icon: const Icon(Icons.arrow_outward_rounded, size: 16),
                      label: const Text(
                        'View daily reports',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Patients today',
              value: '${store.patients(1)}',
              icon: Icons.people_outline_rounded,
              detail: 'Across selected branches',
            ),
            MetricCard(
              label: 'Revenue today',
              value: money(store.revenue(1)),
              icon: Icons.account_balance_wallet_outlined,
              detail: 'Daily collections',
              color: AppColors.green,
            ),
            MetricCard(
              label: 'Active branches',
              value: store.visibleBranches.length.toString().padLeft(2, '0'),
              icon: Icons.local_hospital_outlined,
              detail: 'Reports available today',
            ),
            MetricCard(
              label: 'Inventory alerts',
              value: alerts.length.toString().padLeft(2, '0'),
              icon: Icons.medication_outlined,
              detail: alerts.isEmpty
                  ? 'All batches healthy'
                  : 'Stock & expiry attention',
              color: AppColors.orange,
            ),
          ],
        ),
        SectionTitle(
          'The pulse of your clinics',
          subtitle: 'Patient visits over the last 7 days',
          action: 'Statistics ↗',
          onTap: () => onNavigate(2),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${store.patients(7)}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'patient visits',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusPill('7 days', color: AppColors.blue),
                ],
              ),
              const SizedBox(height: 26),
              TrendChart(
                values: dailyValues(store, 7, patients: true),
                labels: List.generate(7, (i) {
                  final d = clinicToday().subtract(Duration(days: 6 - i));
                  return '${d.day}/${d.month}';
                }),
              ),
            ],
          ),
        ),
        SectionTitle(
          'Your branches',
          subtitle: 'A little closer to every community',
          action: 'View all ↗',
          onTap: () => onNavigate(4),
        ),
        ResponsiveGrid(
          maxColumns: 3,
          minWidth: 260,
          children: store.visibleBranches
              .map((b) => BranchCard(store: store, branch: b))
              .toList(),
        ),
        SectionTitle(
          'Needs your attention',
          subtitle: 'Keep your clinics ready for every patient',
          action: 'Inventory ↗',
          onTap: () => onInventory(),
        ),
        if (alerts.isEmpty)
          const Panel(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.green),
                SizedBox(width: 12),
                Expanded(child: Text('All stocked up. No inventory alerts.')),
              ],
            ),
          )
        else
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: alerts
                  .take(3)
                  .map(
                    (m) => InkWell(
                      onTap: () => onInventory(alerts: true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.medication_outlined,
                                color: AppColors.orange,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${m.branch} · ${m.quantity} ${m.unit} left',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(m.status, color: AppColors.orange),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SectionTitle(
          'People behind the care',
          subtitle: 'Patient feedback, reflected in your team',
        ),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            children: store.visibleBranches
                .take(3)
                .map((b) => StaffTile(staff: b.staff.first, branch: b.name))
                .toList(),
          ),
        ),
      ],
    );
  }
}
