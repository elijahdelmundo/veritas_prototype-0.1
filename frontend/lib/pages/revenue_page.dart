import 'package:flutter/material.dart';

import '../data/clinic_store.dart';
import '../widgets/clinic_ui.dart';

class RevenuePage extends StatefulWidget {
  const RevenuePage({super.key, required this.store});
  final ClinicStore store;
  @override
  State<RevenuePage> createState() => _RevenuePageState();
}

class _RevenuePageState extends State<RevenuePage> {
  int days = 30;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final gross = store.revenue(days);
    final costs = store.expenses(days);
    final net = gross - costs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('Today')),
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
          ],
          selected: {days},
          onSelectionChanged: (v) => setState(() => days = v.first),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF15775D), Color(0xFF2AA783)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NET REVENUE',
                style: TextStyle(
                  color: Color(0xFFC2EBDD),
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 14),
              FittedBox(
                child: Text(
                  money(net),
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${gross == 0 ? '0.0' : (net / gross * 100).toStringAsFixed(1)}% net margin · ${days == 1 ? 'Today' : 'Last $days days'}',
                style: const TextStyle(color: Color(0xFFDAF2E9), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          maxColumns: 2,
          minWidth: 140,
          children: [
            MetricCard(
              label: 'Gross collections',
              value: money(gross),
              icon: Icons.south_west_rounded,
              detail: 'Total reported revenue',
              color: AppColors.green,
            ),
            MetricCard(
              label: 'Operating expenses',
              value: money(costs),
              icon: Icons.north_east_rounded,
              detail: 'Total reported expenses',
              color: AppColors.orange,
            ),
          ],
        ),
        SectionTitle(
          'Collection trend',
          subtitle: days == 1
              ? 'Last 7 days for context'
              : 'Daily gross revenue · last $days days',
        ),
        Panel(
          child: TrendChart(
            values: dailyValues(store, days == 1 ? 7 : days),
            color: AppColors.green,
            labels: [
              dateLabel(
                clinicToday().subtract(
                  Duration(days: (days == 1 ? 7 : days) - 1),
                ),
              ),
              'Today',
            ],
          ),
        ),
        const SectionTitle(
          'Revenue by branch',
          subtitle: 'Collections, expenses, and net revenue',
        ),
        for (final b in store.visibleBranches)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        color: AppColors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        money(store.revenue(days, branch: b.name)),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 24,
                    runSpacing: 10,
                    children: [
                      Text(
                        'Expenses ${money(store.expenses(days, branch: b.name))}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Net ${money(store.revenue(days, branch: b.name) - store.expenses(days, branch: b.name))}',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
