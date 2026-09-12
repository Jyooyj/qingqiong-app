import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/campus_geo/campus_geo_point.dart';
import '../../models/campus_geo/custom_cleaning_area.dart';
import '../../repositories/custom_cleaning_area_store.dart';
import 'custom_area_map_page.dart';

class NewCustomAreaPage extends StatefulWidget {
  const NewCustomAreaPage({
    super.key,
    required this.store,
    this.tileProviderFactory,
  });
  final CustomCleaningAreaStore store;
  final TileProvider Function()? tileProviderFactory;

  @override
  State<NewCustomAreaPage> createState() => _NewCustomAreaPageState();
}

class _NewCustomAreaPageState extends State<NewCustomAreaPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  CustomAreaType _type = CustomAreaType.road;
  List<CampusGeoPoint> _polygon = [];
  bool _missingRange = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('新建自定义区域')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('custom-area-name'),
                controller: _name,
                maxLength: 60,
                decoration: const InputDecoration(labelText: '区域名称'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入区域名称' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CustomAreaType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: '区域类型'),
                items: [
                  for (final type in CustomAreaType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (type) {
                  if (type != null) setState(() => _type = type);
                },
              ),
              const SizedBox(height: 24),
              const Text('选择范围'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('pick-custom-range'),
                icon: const Icon(Icons.map_outlined),
                label: const Text('去地图选择区域'),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  final polygon = await Navigator.of(context)
                      .push<List<CampusGeoPoint>>(
                        MaterialPageRoute(
                          builder: (_) => CustomAreaMapPage(
                            initialPolygon: _polygon,
                            tileProviderFactory: widget.tileProviderFactory,
                          ),
                        ),
                      );
                  if (polygon != null && mounted) {
                    setState(() {
                      _polygon = polygon;
                      _missingRange = false;
                    });
                  }
                },
              ),
              if (_polygon.isNotEmpty) Text('已选择 ${_polygon.length} 个边界点'),
              if (_missingRange)
                Text(
                  '请先在地图上选择有效范围',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 20),
              const Text('区域和沿边界生成的闭合演示路线保存在本次会话中，保存后即可选择执行清扫。'),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('save-custom-area'),
                onPressed: () {
                  final valid = _form.currentState!.validate();
                  final missing =
                      CustomCleaningArea.polygonError(_polygon) != null;
                  setState(() => _missingRange = missing);
                  if (!valid || missing) return;
                  final area = widget.store.save(
                    name: _name.text,
                    type: _type,
                    polygon: _polygon,
                  );
                  Navigator.of(context).pop(area.id);
                },
                child: const Text('保存区域'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
