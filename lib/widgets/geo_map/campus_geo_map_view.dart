import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'campus_geo_map_fallback.dart';
import 'geo_map_view_data.dart';
import '../../data/campus_geo/campus_buildings.dart';
import '../../models/campus_geo/campus_building.dart';
import '../../theme/app_design.dart';
export 'geo_map_view_data.dart';

/// Controlled geographic display. No task, voice, or safety dependencies.
/// Parent owns all semantic state. Lists should be replaced when changed.
class CampusGeoMapView extends StatefulWidget {
  const CampusGeoMapView({
    super.key,
    required this.zones,
    this.campusBuildings = CampusBuildings.all,
    this.selectedZoneId,
    this.robotPosition,
    this.plannedPath = const [],
    this.routeLabel = '规划路线',
    this.cleanedPath = const [],
    this.obstacles = const [],
    this.chargingStation,
    this.onZoneTap,
    this.initialCenter = campusCenter,
    this.initialZoom = 16,
    this.enableCoordinatePicker = false,
    this.showCoordinatePickerDetails = true,
    this.showCampusLabels = true,
    this.onCoordinatePicked,
    this.onFallback,
    this.tileProviderFactory,
    this.tileLoadTimeout = const Duration(seconds: 20),
  });
  // Approximate campus overview only; not a surveyed robot location.
  static const campusCenter = LatLng(30.88469, 121.89265);
  final List<CampusGeoZoneView> zones;

  /// Permanent wayfinding labels. Callers may provide a scoped list; the
  /// default is the trusted campus overview list.
  final List<CampusBuilding> campusBuildings;
  final String? selectedZoneId;
  final LatLng? robotPosition;
  final List<LatLng> plannedPath, cleanedPath;
  final String routeLabel;
  final List<CampusGeoMarkerView> obstacles;
  final CampusGeoMarkerView? chargingStation;
  final ValueChanged<String>? onZoneTap;
  final LatLng initialCenter;
  final double initialZoom;
  final bool enableCoordinatePicker;
  final bool showCoordinatePickerDetails;
  final bool showCampusLabels;
  final ValueChanged<LatLng>? onCoordinatePicked;
  final VoidCallback? onFallback;

  /// Fresh provider per retry; TileLayer owns/disposes it. Useful for tests.
  final TileProvider Function()? tileProviderFactory;
  final Duration tileLoadTimeout;
  @override
  State<CampusGeoMapView> createState() => _CampusGeoMapViewState();
}

class _CampusGeoMapViewState extends State<CampusGeoMapView> {
  final _controller = MapController();
  final LayerHitNotifier<String> _hits = ValueNotifier(null);
  Timer? _timeout;
  bool _ready = false, _tileError = false, _loaded = false;
  bool _timedOut = false, _statusQueued = false;
  final Map<TileImage, bool?> _tileStates = {};
  int _generation = 0;
  TileProvider? _provider;
  LatLng? _picked;
  bool get _picker => kDebugMode && widget.enableCoordinatePicker;
  List<CampusGeoZoneView> get _zones => widget.zones
      .where(
        (z) =>
            validGeoPoint(z.center) &&
            (z.polygon.isEmpty || z.polygon.length >= 3) &&
            z.polygon.every(validGeoPoint),
      )
      .toList();

  List<CampusBuilding> get _labelBuildings {
    if (widget.campusBuildings.isNotEmpty) {
      return widget.campusBuildings
          .where(
            (b) =>
                b.latitude != null &&
                b.longitude != null &&
                validGeoPoint(LatLng(b.latitude!, b.longitude!)),
          )
          .toList();
    }
    // Compatibility for small embedders/tests that only provide zones.
    return _zones
        .map(
          (zone) => CampusBuilding(
            id: zone.id,
            zoneId: zone.id,
            name: zone.name,
            latitude: zone.center.latitude,
            longitude: zone.center.longitude,
            labelOffset: _legacyLabelOffset(zone.id),
          ),
        )
        .toList();
  }

  CampusLabelOffset _legacyLabelOffset(String id) => switch (id) {
    'lab_building' || 'teaching_2' => const CampusLabelOffset(dy: -18),
    'canteen_1' => const CampusLabelOffset(dx: 28, dy: -18),
    'dormitory' => const CampusLabelOffset(dy: 18),
    'library' => const CampusLabelOffset(dx: -28, dy: -18),
    'teaching_1' => const CampusLabelOffset(dx: 28, dy: 18),
    _ => const CampusLabelOffset(),
  };

  IconData _buildingIcon(CampusBuilding building) {
    final id = building.zoneId ?? building.id;
    if (id.contains('teaching') ||
        id.contains('school') ||
        id.contains('college')) {
      return Icons.school_outlined;
    }
    if (id.contains('canteen')) return Icons.restaurant_outlined;
    if (id.contains('library')) return Icons.local_library_outlined;
    if (id.contains('dorm')) return Icons.home_outlined;
    if (id.contains('lab')) return Icons.science_outlined;
    return Icons.location_city_outlined;
  }

  bool _isBuildingSelected(CampusBuilding building) =>
      widget.selectedZoneId != null &&
      (building.zoneId == widget.selectedZoneId ||
          building.id == widget.selectedZoneId);

  double _labelWidth(CampusBuilding building) =>
      math.max(104.0, building.name.runes.length * 11.0 + 29);

  Alignment _labelAlignment(CampusLabelOffset offset, double width) =>
      Alignment(
        (-2 * offset.dx / width).clamp(-1.0, 1.0),
        (2 * offset.dy / 24).clamp(-1.0, 1.0),
      );

  @override
  void initState() {
    super.initState();
    _provider = widget.tileProviderFactory?.call();
    _armTimeout();
  }

  void _armTimeout() {
    _timeout?.cancel();
    _timedOut = false;
    _timeout = Timer(widget.tileLoadTimeout, () {
      if (mounted) {
        _timedOut = true;
        _refreshTileStatus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CampusGeoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedZoneId != oldWidget.selectedZoneId) _scheduleFocus();
    if (!_picker) _picked = null;
  }

  void _scheduleFocus() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_ready) return;
    final selected = _zones
        .where((z) => z.id == widget.selectedZoneId)
        .firstOrNull;
    if (selected != null) _controller.move(selected.center, 17);
  });

  // Keep labels close to their zone center while spreading the nearby labels
  // enough that the six campus points remain legible at the overview zoom.
  // The geographic anchor is still the zone center; alignment only changes
  // where the label box is drawn around that anchor.
  bool _visibleTile(TileImage tile) {
    if (!_ready) return false;
    final c = tile.coordinates;
    if (c.z != _controller.camera.zoom.round().clamp(0, 19)) return false;
    final n = math.pow(2, c.z);
    double latitude(num y) {
      final v = math.pi * (1 - 2 * y / n);
      return math.atan((math.exp(v) - math.exp(-v)) / 2) * 180 / math.pi;
    }

    final bounds = LatLngBounds(
      LatLng(latitude(c.y + 1), c.x / n * 360 - 180),
      LatLng(latitude(c.y), (c.x + 1) / n * 360 - 180),
    );
    return _controller.camera.visibleBounds.isOverlapping(bounds);
  }

  void _tileChanged(
    TileImage tile,
    bool? failed,
    int generation, {
    bool removed = false,
  }) {
    if (!mounted || generation != _generation) return;
    if (removed) {
      _tileStates.remove(tile);
    } else {
      _tileStates[tile] = failed;
    }
    _refreshTileStatus();
  }

  void _refreshTileStatus() {
    if (!mounted || _statusQueued) return;
    _statusQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _statusQueued = false;
      if (!mounted || !_ready) return;
      final visible = _tileStates.entries
          .where((e) => _visibleTile(e.key))
          .map((e) => e.value)
          .toList();
      final loaded = visible.contains(false);
      final failed = visible.contains(true);
      // No successful tile does not imply offline while requests are pending.
      final allFailed = visible.isNotEmpty && visible.every((v) => v == true);
      final error = loaded ? failed : allFailed || _timedOut;
      if (_loaded != loaded || _tileError != error) {
        setState(() {
          _loaded = loaded;
          _tileError = error;
        });
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _retry() {
    setState(() {
      _generation++;
      _tileStates.clear();
      _tileError = false;
      _loaded = false;
      _provider = widget.tileProviderFactory?.call();
    });
    _armTimeout();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _hits.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zones = _zones;
    final generation = _generation;
    final robot = widget.robotPosition;
    final charger = widget.chargingStation;
    final coLocated =
        robot != null &&
        charger != null &&
        validGeoPoint(robot) &&
        validGeoPoint(charger.position) &&
        const Distance().as(LengthUnit.Meter, robot, charger.position) < 2;
    final nearbyObstacles = widget.obstacles
        .where(
          (o) =>
              robot != null &&
              validGeoPoint(robot) &&
              validGeoPoint(o.position) &&
              const Distance().as(LengthUnit.Meter, robot, o.position) < 2,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            height: box.maxWidth < 600 ? 420 : 540,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    key: const Key('geo-map'),
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: validGeoPoint(widget.initialCenter)
                          ? widget.initialCenter
                          : CampusGeoMapView.campusCenter,
                      initialZoom: widget.initialZoom.isFinite
                          ? widget.initialZoom.clamp(3, 19)
                          : 16,
                      minZoom: 3,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () {
                        _ready = true;
                        _scheduleFocus();
                        _refreshTileStatus();
                      },
                      onPositionChanged: (_, _) {
                        _armTimeout();
                        _refreshTileStatus();
                      },
                      onTap: (_, point) {
                        if (_picker) {
                          setState(() => _picked = point);
                          widget.onCoordinatePicked?.call(point);
                          return;
                        }
                        final hit = _hits.value?.hitValues.firstOrNull;
                        if (hit != null) {
                          widget.onZoneTap?.call(hit);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey('geo-tiles-$_generation'),
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'org.qingqiong.robot_cleaner',
                        tileProvider: _provider,
                        maxNativeZoom: 19,
                        tileDisplay: const TileDisplay.instantaneous(),
                        errorTileCallback: (tile, error, stack) =>
                            _tileChanged(tile, true, generation),
                        tileBuilder: (context, child, tile) => _TileObserver(
                          tile: tile,
                          onFinished: (failed) =>
                              _tileChanged(tile, failed, generation),
                          onRemoved: () => _tileChanged(
                            tile,
                            null,
                            generation,
                            removed: true,
                          ),
                          child: child,
                        ),
                      ),
                      PolygonLayer<String>(
                        hitNotifier: _hits,
                        polygons: [
                          for (final zone in zones.where(
                            (z) => z.polygon.length >= 3,
                          ))
                            Polygon<String>(
                              points: zone.polygon,
                              hitValue: zone.id,
                              color: zone.id == widget.selectedZoneId
                                  ? const Color(0x6630aa85)
                                  : const Color(0x18226c9c),
                              borderColor: zone.id == widget.selectedZoneId
                                  ? const Color(0xff087d62)
                                  : const Color(0xff4981a0),
                              borderStrokeWidth:
                                  zone.id == widget.selectedZoneId ? 3 : 1,
                            ),
                        ],
                      ),
                      // The base campus label layer is always rendered from
                      // the supplied zones, independently of task overlays.
                      MarkerLayer(
                        key: const Key('geo-campus-label-layer'),
                        markers: [
                          if (widget.showCampusLabels)
                            for (final building in _labelBuildings)
                              Marker(
                                key: Key('geo-building-marker-${building.id}'),
                                point: LatLng(
                                  building.latitude!,
                                  building.longitude!,
                                ),
                                width: _labelWidth(building),
                                height: 24,
                                alignment: _labelAlignment(
                                  building.labelOffset,
                                  _labelWidth(building),
                                ),
                                child: Semantics(
                                  button: true,
                                  selected: _isBuildingSelected(building),
                                  child: GestureDetector(
                                    key: Key('geo-zone-${building.id}'),
                                    onTap: () => widget.onZoneTap?.call(
                                      building.zoneId ?? building.id,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _isBuildingSelected(building)
                                            ? AppDesign.primarySoft
                                            : Colors.white.withValues(
                                                alpha: .9,
                                              ),
                                        border: Border.all(
                                          color: _isBuildingSelected(building)
                                              ? AppDesign.primary
                                              : const Color(0x80D9E0E4),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x0C000000),
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 3,
                                            ),
                                            child: Icon(
                                              _buildingIcon(building),
                                              size: 12,
                                              color:
                                                  _isBuildingSelected(building)
                                                  ? AppDesign.primary
                                                  : AppDesign.textSecondary,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              building.name,
                                              softWrap: false,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.2,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    _isBuildingSelected(
                                                      building,
                                                    )
                                                    ? AppDesign.primary
                                                    : AppDesign.text,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                      // Routes are drawn above permanent labels while all
                      // dynamic markers remain above both layers.
                      IgnorePointer(
                        child: PolylineLayer(
                          polylines: [
                            if (widget.plannedPath.length >= 2 &&
                                widget.plannedPath.every(validGeoPoint))
                              Polyline(
                                points: widget.plannedPath,
                                color: Colors.blue,
                                strokeWidth: 4,
                                pattern: StrokePattern.dashed(segments: [8, 5]),
                              ),
                            if (widget.cleanedPath.length >= 2 &&
                                widget.cleanedPath.every(validGeoPoint))
                              Polyline(
                                points: widget.cleanedPath,
                                color: const Color(0xff07835e),
                                strokeWidth: 5,
                              ),
                          ],
                        ),
                      ),
                      // Dynamic markers remain a separate layer so warnings,
                      // the robot and charging station never control whether
                      // the permanent campus labels are visible.
                      MarkerLayer(
                        key: const Key('geo-dynamic-marker-layer'),
                        markers: [
                          if (charger != null &&
                              validGeoPoint(charger.position) &&
                              !coLocated)
                            _marker(
                              charger.position,
                              'geo-charger',
                              Icons.ev_station,
                              Colors.indigo,
                              charger.label,
                            ),
                          for (final obstacle in widget.obstacles.where(
                            (o) =>
                                validGeoPoint(o.position) &&
                                !nearbyObstacles.contains(o),
                          ))
                            _marker(
                              obstacle.position,
                              'geo-obstacle-${obstacle.id}',
                              Icons.warning_amber_rounded,
                              Colors.deepOrange,
                              obstacle.label,
                            ),
                          if (robot != null && validGeoPoint(robot))
                            coLocated || nearbyObstacles.isNotEmpty
                                ? Marker(
                                    point: robot,
                                    width:
                                        34.0 *
                                        (1 +
                                            (coLocated ? 1 : 0) +
                                            nearbyObstacles.length),
                                    height: 36,
                                    child: IgnorePointer(
                                      child: Semantics(
                                        label: '机器人与附近设备或障碍',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              if (coLocated)
                                                const Icon(
                                                  Icons.ev_station,
                                                  key: Key('geo-charger'),
                                                  color: Colors.indigo,
                                                ),
                                              for (final obstacle
                                                  in nearbyObstacles)
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  key: Key(
                                                    'geo-obstacle-${obstacle.id}',
                                                  ),
                                                  color: Colors.deepOrange,
                                                ),
                                              const Icon(
                                                Icons.smart_toy,
                                                key: Key('geo-robot'),
                                                color: Color(0xff184b6b),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : _marker(
                                    robot,
                                    'geo-robot',
                                    Icons.smart_toy,
                                    const Color(0xff184b6b),
                                    '机器人（外部位置）',
                                  ),
                          if (_picker && _picked != null)
                            _marker(
                              _picked!,
                              'geo-picked',
                              Icons.location_on,
                              Colors.blue,
                              '\u6821\u51c6\u70b9',
                            ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Material(
                          color: Colors.white,
                          child: TextButton(
                            onPressed: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                            ),
                            child: const Text(
                              '© OpenStreetMap contributors',
                              maxLines: 2,
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        _control('放大', Icons.add, () => _zoom(1)),
                        _control('缩小', Icons.remove, () => _zoom(-1)),
                        _control(
                          '回到校园',
                          Icons.school_outlined,
                          () => _controller.move(widget.initialCenter, 16),
                        ),
                      ],
                    ),
                  ),
                  if (_tileError)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 66,
                      child: CampusGeoMapFallback(
                        message: _loaded
                            ? '部分底图加载失败，已加载区域仍可使用。'
                            : '当前视野底图暂不可用，请检查网络或重试。位置与路线图层仍保留。',
                        onRetry: _retry,
                        onFallback: widget.onFallback,
                      ),
                    ),
                  if (!_loaded && !_tileError)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: IgnorePointer(child: Chip(label: Text('正在加载底图…'))),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            Text(
              '┄ ${widget.routeLabel}',
              style: const TextStyle(color: Colors.blue),
            ),
            const Text('━ 已清扫轨迹', style: TextStyle(color: Color(0xff07835e))),
            const Text('▲ 障碍', style: TextStyle(color: Colors.deepOrange)),
          ],
        ),
        if (_picker && widget.showCoordinatePickerDetails)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('开发用坐标拾取 · 点击地图空白处'),
                    if (_picked != null) ...[
                      SelectableText(
                        '纬度：${_picked!.latitude.toStringAsFixed(6)}\n经度：${_picked!.longitude.toStringAsFixed(6)}',
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${_picked!.latitude.toStringAsFixed(6)}, ${_picked!.longitude.toStringAsFixed(6)}',
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                              const SnackBar(content: Text('坐标已复制')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制坐标'),
                      ),
                    ] else
                      const Text('尚未拾取'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _zoom(double delta) {
    if (_ready) {
      _controller.move(
        _controller.camera.center,
        (_controller.camera.zoom + delta).clamp(3, 19),
      );
    }
  }

  Widget _control(String label, IconData icon, VoidCallback callback) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: IconButton(
            tooltip: label,
            onPressed: callback,
            icon: Icon(icon),
          ),
        ),
      );
  Marker _marker(
    LatLng point,
    String key,
    IconData icon,
    Color color,
    String label,
  ) => Marker(
    point: point,
    width: 34,
    height: 34,
    child: IgnorePointer(
      child: Semantics(
        label: label,
        child: Container(
          key: Key(key),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    ),
  );
}

class _TileObserver extends StatefulWidget {
  const _TileObserver({
    required this.tile,
    required this.onFinished,
    required this.onRemoved,
    required this.child,
  });
  final TileImage tile;
  final ValueChanged<bool?> onFinished;
  final VoidCallback onRemoved;
  final Widget child;
  @override
  State<_TileObserver> createState() => _TileObserverState();
}

class _TileObserverState extends State<_TileObserver> {
  bool _reported = false;
  bool? _lastState;
  void _check() {
    final failed = widget.tile.loadFinishedAt == null
        ? null
        : widget.tile.loadError;
    if (!_reported || failed != _lastState) {
      _reported = true;
      _lastState = failed;
      widget.onFinished(failed);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.tile.addListener(_check);
    _check();
  }

  @override
  void didUpdateWidget(covariant _TileObserver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tile != widget.tile) {
      oldWidget.tile.removeListener(_check);
      oldWidget.onRemoved();
      _reported = false;
      widget.tile.addListener(_check);
      _check();
    }
  }

  @override
  void dispose() {
    widget.tile.removeListener(_check);
    widget.onRemoved();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
