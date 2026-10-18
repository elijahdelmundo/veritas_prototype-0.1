import 'package:flutter/material.dart';

import '../data/clinic_store.dart';
import '../widgets/clinic_ui.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.store});
  final ClinicStore store;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int days = 7;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final total = store.patients(days);
    final team = store.visibleBranches.expand((b) => b.staff).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final reviews = team.fold(0, (sum, s) => sum + s.reviews);
    final rating =
        team.fold(0.0, (sum, s) => sum + s.rating * s.reviews) / reviews;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
          ],
          selected: {days},
          onSelectionChanged: (v) => setState(() => days = v.first),
        ),
        const SizedBox(height: 22),
        ResponsiveGrid(
          maxColumns: 3,
          children: [
            MetricCard(
              label: 'Total patient visits',
              value: '$total',
              icon: Icons.people_outline,
              detail: 'Last $days days',
            ),
            MetricCard(
              label: 'Average daily visits',
              value: (total / days).toStringAsFixed(1),
              icon: Icons.monitor_heart_outlined,
              detail: 'Across selected branches',
              color: AppColors.green,
            ),
            MetricCard(
              label: 'Patient satisfaction',
              value: '${rating.toStringAsFixed(1)}/5',
              icon: Icons.star_outline_rounded,
              detail: '$reviews all-time reviews',
              color: AppColors.orange,
            ),
          ],
        ),
        const SectionTitle(
          'Patient activity',
          subtitle: 'Daily visits across your selected branches',
        ),
        Panel(
          child: TrendChart(
            values: dailyValues(store, days, patients: true),
            labels: [
              dateLabel(clinicToday().subtract(Duration(days: days - 1))),
              'Today',
            ],
            color: AppColors.green,
          ),
        ),
        SectionTitle(
          'Branch comparison',
          subtitle: 'Patient visits in the last $days days',
        ),
        Panel(
          child: Column(
            children: store.visibleBranches.map((b) {
              final count = store.patients(days, branch: b.name);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$count visits',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : count / total,
                        minHeight: 8,
                        color: AppColors.blue,
                        backgroundColor: const Color(0xFFEEF3FD),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SectionTitle(
          'Staff ratings',
          subtitle: 'All-time patient feedback · highest rated first',
        ),
        Panel(
          child: Column(
            children: team
                .map(
                  (s) => StaffTile(
                    staff: s,
                    branch: store.visibleBranches
                        .firstWhere((b) => b.staff.contains(s))
                        .name,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
