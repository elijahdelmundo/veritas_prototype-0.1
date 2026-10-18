import 'package:flutter/material.dart';

import '../data/clinic_store.dart';
import 'app_motion.dart';

class AppColors {
  static const blue = Color(0xFF246BFD);
  static const green = Color(0xFF229D78);
  static const ink = Color(0xFF18283F);
  static const muted = Color(0xFF8792A3);
  static const background = Color(0xFFF5F7FB);
  static const line = Color(0xFFEDF0F5);
  static const orange = Color(0xFFD68A22);
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x030F274A),
          blurRadius: 20,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color = AppColors.green});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.detail,
    this.color = AppColors.blue,
  });
  final String label;
  final String value;
  final IconData icon;
  final String detail;
  final Color color;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Icon(Icons.north_east_rounded, size: 16, color: color),
          ],
        ),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Text(
          detail,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.maxColumns = 4,
    this.minWidth = 160,
  });
  final List<Widget> children;
  final int maxColumns;
  final double minWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = ((constraints.maxWidth + 14) / (minWidth + 14))
          .floor()
          .clamp(1, maxColumns);
      final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (var i = 0; i < children.length; i++)
            SizedBox(
              width: width,
              child: MotionEntrance(order: i, child: children[i]),
            ),
        ],
      );
    },
  );
}

class BranchSelector extends StatelessWidget {
  const BranchSelector({super.key, required this.store});
  final ClinicStore store;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.line),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: store.selectedBranch,
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        items: [
          'All branches',
          ...store.branches.map((b) => b.name),
        ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
        onChanged: (value) {
          if (value != null) store.selectBranch(value);
        },
      ),
    ),
  );
}

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    this.color = AppColors.blue,
    this.labels = const [],
  });
  final List<double> values;
  final Color color;
  final List<String> labels;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 145,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: reduceMotion(context)
              ? Duration.zero
              : const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) =>
              CustomPaint(painter: _TrendPainter(values, color, progress)),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels
            .map(
              (l) => Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.color, this.progress);
  final List<double> values;
  final Color color;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    final max = values.reduce((a, b) => a > b ? a : b) * 1.2;
    final points = List.generate(
      values.length,
      (i) => Offset(
        size.width * i / (values.length - 1),
        size.height - (max == 0 ? 0 : values[i] / max) * size.height,
      ),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final next = points[i];
      final mid = (prev.dx + next.dx) / 2;
      path.cubicTo(mid, prev.dy, mid, next.dy, next.dx, next.dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .18), color.withValues(alpha: .01)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(points.last, 5, Paint()..color = Colors.white);
    canvas.drawCircle(points.last, 3, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress;
}

List<double> dailyValues(
  ClinicStore store,
  int days, {
  bool patients = false,
}) => List.generate(days, (i) {
  final date = clinicToday().subtract(Duration(days: days - 1 - i));
  return store
      .periodReports(days)
      .where((r) => DateUtils.isSameDay(r.date, date))
      .fold(0.0, (sum, r) => sum + (patients ? r.patients : r.revenue));
});

class StaffTile extends StatelessWidget {
  const StaffTile({super.key, required this.staff, required this.branch});
  final StaffMember staff;
  final String branch;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFEAF1FF),
          foregroundColor: AppColors.blue,
          child: Text(
            staff.name
                .replaceFirst('Dr. ', '')
                .split(' ')
                .take(2)
                .map((s) => s[0])
                .join(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staff.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${staff.role} · $branch',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFE5AE40),
                  size: 17,
                ),
                Text(
                  ' ${staff.rating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Text(
              '${staff.reviews} reviews',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      ],
    ),
  );
}
