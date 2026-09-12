import 'package:flutter/material.dart';

import '../../controllers/robot_controller.dart';
import '../../data/campus_geo/campus_cleaning_catalog.dart';
import '../../services/product_session.dart';
import 'cleaning_area_sheet.dart';

class QuickCleaningCard extends StatelessWidget {
  const QuickCleaningCard({
    super.key,
    required this.session,
    required this.onRun,
  });

  final ProductSession session;
  final void Function(ControlResult Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      for (final zone in CampusCleaningCatalog.shortcuts)
        OutlinedButton(
          key: Key('quick-clean-${zone.id}'),
          onPressed: session.canStartTask
              ? () => onRun(
                  () => session.campusCoordinator.startCampusCleaning(zone.id),
                )
              : null,
          child: Text(zone.name),
        ),
      OutlinedButton(
        key: const Key('more-cleaning-areas'),
        onPressed: () async {
          final id = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => CleaningAreaSheet(session: session),
          );
          if (id != null && context.mounted) {
            onRun(() => session.campusCoordinator.startCampusCleaning(id));
          }
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('更多区域'), Icon(Icons.chevron_right, size: 18)],
        ),
      ),
    ];
    return Card(
      key: const Key('area-selector'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快捷清扫',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('常用或已具备完整清扫路线的地点，点击即可启动任务。更多地点请进入区域选择器。'),
            if (!session.canStartTask) const Text('当前状态无法启动清扫任务'),
            const SizedBox(height: 10),
            for (var i = 0; i < buttons.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: buttons[i]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: i + 1 < buttons.length
                          ? buttons[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
