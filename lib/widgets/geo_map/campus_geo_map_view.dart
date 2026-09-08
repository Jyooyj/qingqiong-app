import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'campus_geo_map_fallback.dart';
import 'geo_map_view_data.dart';
export 'geo_map_view_data.dart';

/// Controlled geographic display. No task, voice, or safety dependencies.
/// Parent owns all semantic state. Lists should be replaced when changed.
class CampusGeoMapView extends StatefulWidget {
  const CampusGeoMapView({
    super.key,
    required this.zones,
    this.selectedZoneId,
    this.robotPosition,
    this.plannedPath = const [],
    this.cleanedPath = const [],
    this.obstacles = const [],
    this.chargingStation,
    this.onZoneTap,
    this.initialCenter = campusCenter,
    this.initialZoom = 16,
    this.enableCoordinatePicker = false,
    this.onCoordinatePicked,
    this.onFallback,
    this.tileProviderFactory,
    this.tileLoadTimeout = const Duration(seconds: 20),
  });
  // Approximate campus overview only; not a surveyed robot location.
  static const campusCenter = LatLng(30.88469, 121.89265);
  final List<CampusGeoZoneView> zones;
  final String? selectedZoneId;
  final LatLng? robotPosition;
  final List<LatLng> plannedPath, cleanedPath;
  final List<CampusGeoMarkerView> obstacles;
  final CampusGeoMarkerView? chargingStation;
  final ValueChanged<String>? onZoneTap;
  final LatLng initialCenter;
  final double initialZoom;
  final bool enableCoordinatePicker;
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
  int _generation = 0;
  TileProvider? _provider;
  LatLng? _picked;
  bool get _picker => kDebugMode && widget.enableCoordinatePicker;
  List<CampusGeoZoneView> get _zones => widget.zones
      .where(
        (z) =>
            validGeoPoint(z.center) &&
            z.polygon.length >= 3 &&
            z.polygon.every(validGeoPoint),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _provider = widget.tileProviderFactory?.call();
    _armTimeout();
  }

  void _armTimeout() {
    _timeout?.cancel();
    _timeout = Timer(widget.tileLoadTimeout, () {
      if (mounted && !_loaded) setState(() => _tileError = true);
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
  void _tileFinished(bool failed, int generation) {
    if (!mounted || generation != _generation) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      if (failed && !_tileError) setState(() => _tileError = true);
      if (!failed && !_loaded) {
        _timeout?.cancel();
        setState(() => _loaded = true);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _retry() {
    setState(() {
      _generation++;
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
                      },
                      onTap: (_, point) {
                        final hit = _hits.value?.hitValues.firstOrNull;
                        if (hit != null) {
                          widget.onZoneTap?.call(hit);
                          return;
                        }
                        if (_picker) {
                          setState(() => _picked = point);
                          widget.onCoordinatePicked?.call(point);
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
                        errorTileCallback: (_, error, stack) =>
                            _tileFinished(true, generation),
                        tileBuilder: (context, child, tile) => _TileObserver(
                          tile: tile,
                          onFinished: (failed) =>
                              _tileFinished(failed, generation),
                          child: child,
                        ),
                      ),
                      PolygonLayer<String>(
                        hitNotifier: _hits,
                        polygons: [
                          for (final zone in zones)
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
                      MarkerLayer(
                        markers: [
                          for (final zone in zones)
                            Marker(
                              point: zone.center,
                              width: 92,
                              height: 32,
                              child: Semantics(
                                button: true,
                                selected: zone.id == widget.selectedZoneId,
                                child: GestureDetector(
                                  key: Key('geo-zone-${zone.id}'),
                                  onTap: () => widget.onZoneTap?.call(zone.id),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: zone.id == widget.selectedZoneId
                                          ? const Color(0xff087d62)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      zone.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: zone.id == widget.selectedZoneId
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
                              Colors.purple,
                              '拾取坐标',
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
        const Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            Text('┄ 规划路线', style: TextStyle(color: Colors.blue)),
            Text('━ 已清扫轨迹', style: TextStyle(color: Color(0xff07835e))),
            Text('▲ 障碍', style: TextStyle(color: Colors.deepOrange)),
            Text('机器人位置由外部数据提供', style: TextStyle(fontSize: 12)),
          ],
        ),
        if (_picker)
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
    required this.child,
  });
  final TileImage tile;
  final ValueChanged<bool> onFinished;
  final Widget child;
  @override
  State<_TileObserver> createState() => _TileObserverState();
}

class _TileObserverState extends State<_TileObserver> {
  bool _reported = false;
  void _check() {
    if (!_reported && widget.tile.loadFinishedAt != null) {
      _reported = true;
      widget.onFinished(widget.tile.loadError);
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
      _reported = false;
      widget.tile.addListener(_check);
      _check();
    }
  }

  @override
  void dispose() {
    widget.tile.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
