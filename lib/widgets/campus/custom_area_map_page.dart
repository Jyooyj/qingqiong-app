import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/campus_geo/campus_geo_point.dart';
import '../../models/campus_geo/custom_cleaning_area.dart';
import '../geo_map/campus_geo_map_view.dart';

class CustomAreaMapPage extends StatefulWidget {
  const CustomAreaMapPage({
    super.key,
    this.initialPolygon = const [],
    this.tileProviderFactory,
  });
  final List<CampusGeoPoint> initialPolygon;
  final TileProvider Function()? tileProviderFactory;

  @override
  State<CustomAreaMapPage> createState() => _CustomAreaMapPageState();
}

class _CustomAreaMapPageState extends State<CustomAreaMapPage> {
  late final List<CampusGeoPoint> _points = [...widget.initialPolygon];
  late final TileProvider? _tiles = widget.tileProviderFactory?.call();
  bool _tileError = false;

  @override
  Widget build(BuildContext context) {
    final error = CustomCleaningArea.polygonError(_points);
    final points = _points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('地图选择范围')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('沿区域边界依次点击至少 3 个点，拖动或缩放地图调整视野。'),
            ),
            if (_tileError)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('部分底图加载失败，请返回后联网重试。'),
              ),
            Expanded(
              child: FlutterMap(
                key: const Key('custom-area-map'),
                options: MapOptions(
                  initialCenter: points.isEmpty
                      ? CampusGeoMapView.campusCenter
                      : points.first,
                  initialZoom: 17,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: (_, point) {
                    setState(
                      () => _points.add(
                        CampusGeoPoint(
                          latitude: point.latitude,
                          longitude: point.longitude,
                        ),
                      ),
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'org.qingqiong.robot_cleaner',
                    tileProvider: _tiles,
                    maxNativeZoom: 19,
                    errorTileCallback: (_, _, _) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_tileError) {
                          setState(() => _tileError = true);
                        }
                      });
                    },
                  ),
                  if (points.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: points,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .18),
                          borderColor: Theme.of(context).colorScheme.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  if (points.length == 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < points.length; i++)
                        Marker(
                          point: points[i],
                          width: 26,
                          height: 26,
                          child: IgnorePointer(
                            child: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Material(
                      color: Colors.white,
                      child: TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                        child: const Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(error ?? '已选择 ${_points.length} 个点，范围已闭合'),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _points.isEmpty
                            ? null
                            : () => setState(() => _points.removeLast()),
                        child: const Text('撤销'),
                      ),
                      TextButton(
                        onPressed: _points.isEmpty
                            ? null
                            : () => setState(_points.clear),
                        child: const Text('清空'),
                      ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('confirm-custom-range'),
                        onPressed: error != null
                            ? null
                            : () => Navigator.of(
                                context,
                              ).pop(List<CampusGeoPoint>.of(_points)),
                        child: const Text('确认范围'),
                      ),
                    ],
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
