import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/campus_geo/campus_cleaning_catalog.dart';
import '../../services/product_session.dart';
import 'new_custom_area_page.dart';

class CleaningAreaSheet extends StatefulWidget {
  const CleaningAreaSheet({
    super.key,
    required this.session,
    this.tileProviderFactory,
  });
  final ProductSession session;
  final TileProvider Function()? tileProviderFactory;

  @override
  State<CleaningAreaSheet> createState() => _CleaningAreaSheetState();
}

class _CleaningAreaSheetState extends State<CleaningAreaSheet> {
  CleaningAreaCategory? _category;
  String _query = '';
  final _search = TextEditingController();
  String? _selectedCustomId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _createCustomArea() async {
    FocusScope.of(context).unfocus();
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => NewCustomAreaPage(
          store: widget.session.customCleaningAreas,
          tileProviderFactory: widget.tileProviderFactory,
        ),
      ),
    );
    if (id == null || !mounted) return;
    setState(() {
      _category = CleaningAreaCategory.custom;
      _query = '';
      _search.clear();
      _selectedCustomId = id;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      widget.session,
      widget.session.customCleaningAreas,
    ]),
    builder: (context, _) {
      final areas = CampusCleaningCatalog.areas
          .where(
            (zone) =>
                (_category == null ||
                    CleaningAreaCategory.forZone(zone) == _category) &&
                (zone.name.contains(_query) ||
                    zone.aliases.any((alias) => alias.contains(_query))),
          )
          .toList();
      final customAreas = widget.session.customCleaningAreas.areas
          .where(
            (area) =>
                (_category == null ||
                    _category == CleaningAreaCategory.custom) &&
                area.name.contains(_query),
          )
          .toList();
      return FractionallySizedBox(
        heightFactor: .85,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择清扫区域', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('已配置路线的区域可启动清扫；自定义区域使用边界路线执行演示。'),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: '搜索区域',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('new-custom-area'),
                  onPressed: _createCustomArea,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建自定义区域'),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('全部'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                    ),
                    for (final category in CleaningAreaCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.label),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: areas.isEmpty && customAreas.isEmpty
                    ? const Center(child: Text('暂无符合条件的可执行清扫区域'))
                    : ListView.builder(
                        // Keep newly created areas at the top so they are
                        // immediately visible even when the executable
                        // catalog contains many permanent buildings.
                        itemCount: customAreas.length + areas.length,
                        itemBuilder: (context, index) {
                          if (index < customAreas.length) {
                            final area = customAreas[index];
                            return ListTile(
                              key: Key('custom-area-${area.id}'),
                              selected: _selectedCustomId == area.id,
                              title: Text(area.name),
                              subtitle: Text(
                                '自定义区域 · ${area.type.label}\n已生成闭合演示路线',
                              ),
                              isThreeLine: true,
                              trailing: _selectedCustomId == area.id
                                  ? const Icon(Icons.check_circle_outline)
                                  : const Icon(Icons.chevron_right),
                              onTap: () {
                                setState(() => _selectedCustomId = area.id);
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(area.name),
                                    content: Text(
                                      '已保存区域\n类型：${area.type.label}\n范围：${area.polygon.length} 个边界点\n已生成闭合演示路线，可沿区域边界执行清扫。',
                                    ),
                                    actions: [
                                      if (widget.session.canStartTask)
                                        FilledButton(
                                          key: Key(
                                            'run-custom-area-${area.id}',
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            widget.session.campusCoordinator
                                                .startCustomCleaning(area.id);
                                          },
                                          child: const Text('开始清扫'),
                                        ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('关闭'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                          final zone = areas[index - customAreas.length];
                          return ListTile(
                            key: Key('cleaning-area-${zone.id}'),
                            title: Text(zone.name),
                            subtitle: Text(
                              CleaningAreaCategory.forZone(zone).label,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            enabled: widget.session.canStartTask,
                            onTap: () => Navigator.of(context).pop(zone.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
