import 'package:flutter/material.dart';

import '../data/clinic_store.dart';
import '../widgets/clinic_ui.dart';
import '../widgets/app_motion.dart';
import 'home_page.dart';
import 'daily_reports_page.dart';
import 'statistics_page.dart';
import 'revenue_page.dart';
import 'branches_page.dart';
import 'inventory_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final ClinicStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  int tabDirection = 1;
  final scroll = ScrollController();
  static const labels = [
    'Home',
    'Daily reports',
    'Statistics',
    'Revenue',
    'Branches',
  ];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.assignment_outlined,
    Icons.bar_chart_rounded,
    Icons.account_balance_wallet_outlined,
    Icons.business_outlined,
  ];
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void select(int value) {
    if (value == index) return;
    setState(() {
      tabDirection = value > index ? 1 : -1;
      index = value;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void inventory({bool alerts = false}) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => InventoryPage(store: widget.store, alertsOnly: alerts),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final wide = MediaQuery.sizeOf(context).width >= 1000;
      final pages = [
        HomePage(store: store, onNavigate: select, onInventory: inventory),
        DailyReportsPage(store: store),
        StatisticsPage(store: store),
        RevenuePage(store: store),
        BranchesPage(store: store),
      ];
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                Container(
                  width: 218,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.line)),
                  ),
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 34, 20, 35),
                          child: _Brand(),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 26, bottom: 16),
                          child: Text(
                            'WORKSPACE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        for (var i = 0; i < labels.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              selected: index == i,
                              selectedTileColor: const Color(0xFFEDF3FF),
                              selectedColor: AppColors.blue,
                              leading: Icon(icons[i], size: 21),
                              title: Text(
                                labels[i],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () => select(i),
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 16,
                          ),
                          child: Divider(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: ListTile(
                            leading: const Icon(
                              Icons.medication_outlined,
                              size: 21,
                            ),
                            title: const Text(
                              'Inventory',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: inventory,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Panel(
                            color: const Color(0xFFF1F8F5),
                            padding: const EdgeInsets.all(16),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.health_and_safety_outlined,
                                  color: AppColors.green,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Better care, together.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'One view. Every branch.\nA healthier tomorrow.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(25, 0, 20, 24),
                          child: Text(
                            'VISTA CARE  /  OWNER PORTAL',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                              letterSpacing: .7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 36 : 20,
                        vertical: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: AppColors.line),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (!wide)
                            const Flexible(child: _Brand())
                          else
                            Text(
                              'Your clinic, connected.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Stock & expiry alerts',
                            onPressed: () => inventory(alerts: true),
                            icon: Badge(
                              isLabelVisible: store.alerts.isNotEmpty,
                              label: Text('${store.alerts.length}'),
                              backgroundColor: AppColors.blue,
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F3EF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'VC',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (wide)
                            const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Clinic owner',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Administrator',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scroll,
                        padding: EdgeInsets.fromLTRB(
                          wide ? 36 : 20,
                          28,
                          wide ? 36 : 20,
                          32,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            index == 0
                                                ? 'Overview'
                                                : labels[index],
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineLarge,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            dateLabel(clinicToday()),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    BranchSelector(store: store),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                MotionPage(
                                  pageKey: index,
                                  direction: tabDirection,
                                  child: pages[index],
                                ),
                                const SizedBox(height: 30),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.science_outlined,
                                      size: 13,
                                      color: AppColors.muted,
                                    ),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Demo workspace · Sample data · Changes reset on restart',
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: select,
                  height: 74,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: const Color(0xFFEAF1FF),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      fontSize: 10,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: states.contains(WidgetState.selected)
                          ? AppColors.blue
                          : AppColors.muted,
                    ),
                  ),
                  destinations: List.generate(
                    labels.length,
                    (i) => NavigationDestination(
                      icon: Icon(icons[i], size: 23, color: AppColors.muted),
                      selectedIcon: Icon(
                        icons[i],
                        size: 23,
                        color: AppColors.blue,
                      ),
                      label: labels[i],
                    ),
                  ),
                ),
              ),
      );
    },
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 9),
        const Text(
          'vista',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -.9,
            color: AppColors.ink,
          ),
        ),
        const Text(
          'care',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            letterSpacing: -.9,
            color: AppColors.green,
          ),
        ),
      ],
    ),
  );
}
