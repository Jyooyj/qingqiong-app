# Campus Geo Engine Handoff

## 1. 基本信息

- Role: 2号 - Geo 数据与位置引擎
- Branch: `feature/campus-geo-engine`
- Baseline: `feature/campus-demo-integration`
- Coordinate format: standard latitude / longitude
- Map target: FlutterMap / OpenStreetMap
- Legacy normalized campus models are kept unchanged and run in parallel with the new Geo models.

---

## 2. Geo Models

目录：

`lib/models/campus_geo/`

当前包含：

- `CampusGeoPoint`
- `CampusGeoZone`
- `CampusGeoRoute`
- `CampusGeoObstacle`
- `CampusGeoChargingStation`

### CampusGeoPoint

字段：

- `latitude`
- `longitude`

同时提供 `isValid`，用于检查：

- latitude: `[-90, 90]`
- longitude: `[-180, 180]`

### CampusGeoZone

字段：

- `id`
- `name`
- `aliases`
- `center`
- `polygon`

### CampusGeoRoute

字段：

- `zoneId`
- `plannedPath`

---

## 3. CampusGeoMapData API

文件：

`lib/data/campus_geo/campus_geo_map_data.dart`

当前提供：

- `CampusGeoMapData.zones`
- `CampusGeoMapData.findZoneById(id)`
- `CampusGeoMapData.findZoneByAlias(text)`
- `CampusGeoMapData.routeForZone(zoneId)`
- `CampusGeoMapData.chargingStation`

---

## 4. Zone ID

统一使用以下 zoneId：

| zoneId | 中文名称 | 当前状态 |
|---|---|---|
| `lab_building` | 实验楼 | P0 已录入 |
| `canteen_1` | 第一食堂 | P0 已录入 |
| `canteen_2` | 第二食堂 | P1 已录入中心点|
| `teaching_1` | 第一教学楼 | P1 已录入中心点 |
| `teaching_2` | 第二教学楼 | P0 已录入 |
| `teaching_3` | 第三教学楼 | P1 已录入中心点|
| `dormitory` | 学生宿舍 | P0 已录入 |
| `library` | 图书馆 | P0 已录入 |
| `main_road` | 校园主干道 | P1 已录入中心点|

---

## 5. P0 Geo Data

### lab_building / 实验楼

Center:

- latitude: `30.883660`
- longitude: `121.891570`

Aliases:

- 实验楼
- 实验楼A
- 公共实验楼A

Polygon:

- `(30.883760, 121.891450)`
- `(30.883760, 121.891690)`
- `(30.883560, 121.891690)`
- `(30.883560, 121.891450)`

Data note:

- Center was checked against OpenStreetMap-based public map data.
- OSM way reference: `457387219`
- Current polygon is a Demo approximate rectangle around the center and still requires final calibration with the map coordinate picker.

---

### canteen_1 / 第一食堂

Center:

- latitude: `30.883980`
- longitude: `121.892430`

Aliases:

- 第一食堂
- 一餐
- 第一餐厅

Polygon:

- `(30.884080, 121.892300)`
- `(30.884080, 121.892560)`
- `(30.883880, 121.892560)`
- `(30.883880, 121.892300)`

Data note:

- Current center is a Demo approximate campus coordinate.
- Current polygon is a Demo approximate rectangle.
- Final same-map calibration is still required.

---

### teaching_2 / 第二教学楼

Center:

- latitude: `30.885420`
- longitude: `121.893520`

Aliases:

- 第二教学楼
- 二教

Polygon:

- `(30.885530, 121.893390)`
- `(30.885530, 121.893650)`
- `(30.885310, 121.893650)`
- `(30.885310, 121.893390)`

Data note:

- Current center is a Demo approximate campus coordinate.
- Current polygon is a Demo approximate rectangle.
- Final same-map calibration is still required.

---

### dormitory / 学生宿舍

Center:

- latitude: `30.882930`
- longitude: `121.893230`

Aliases:

- 学生宿舍
- 宿舍
- 宿舍区

Polygon:

- `(30.883100, 121.893020)`
- `(30.883100, 121.893440)`
- `(30.882760, 121.893440)`
- `(30.882760, 121.893020)`

Data note:

- Current center is a Demo approximate campus coordinate.
- Current polygon is a Demo approximate rectangle.
- Final same-map calibration is still required.

---

### library / 图书馆

Center:

- latitude: `30.885707`
- longitude: `121.892017`

Aliases:

- 图书馆
- 海大图书馆
- 上海海洋大学图书馆

Polygon:

- `(30.885820, 121.891880)`
- `(30.885820, 121.892150)`
- `(30.885590, 121.892150)`
- `(30.885590, 121.891880)`

Data note:

- Center was manually checked from the campus map during development.
- Public OSM-based reference is approximately `(30.88575, 121.89196)`.
- OSM way reference: `618745137`
- Current polygon is a Demo approximate rectangle and still requires final calibration.

---

## 6. P1 Current Data

### teaching_1 / 第一教学楼

Center:

- latitude: `30.884460`
- longitude: `121.893870`

Aliases:

- 第一教学楼
- 一教

Data note:

- Center was checked against OpenStreetMap-based public map data.
- OSM way reference: `457387218`
- Polygon has not yet been added because P0 locations were prioritized.

---

### canteen_2 / 第二食堂

Center:

- latitude: `30.884760`
- longitude: `121.894120`

Aliases:

- 第二食堂
- 二餐
- 第二餐厅

Data note:

- Current center is a Demo approximate campus coordinate.
- This point has not been independently verified against the final map.
- Polygon has not yet been added.
- Final same-map calibration is still required.

---

### teaching_3 / 第三教学楼

Center:

- latitude: `30.885860`
- longitude: `121.894180`

Aliases:

- 第三教学楼
- 三教

Data note:

- Current center is a Demo approximate campus coordinate.
- This point has not been independently verified against the final map.
- Polygon has not yet been added.
- Final same-map calibration is still required.

---

### main_road / 校园主干道

Center:

- latitude: `30.884500`
- longitude: `121.892900`

Aliases:

- 校园主干道
- 主干道
- 校园道路

Data note:

- Current center is a Demo approximate representative point for the campus main road.
- This is not a surveyed road centerline coordinate.
- Polygon / road geometry has not yet been added.
- Final same-map calibration is still required.
---

## 7. Charging Station

Current Demo charging station:

- id: `charging_1`
- name: `校园充电点`
- latitude: `30.884300`
- longitude: `121.892050`

Important:

This is currently a Demo starting point used by the route and location simulation. It should not be treated as a surveyed or verified physical robot charging-station location.

---

## 8. Demo Routes

Four priority Demo routes are currently provided:

- charging station -> `lab_building`
- charging station -> `canteen_1`
- charging station -> `teaching_2`
- charging station -> `dormitory`

Each route:

- is non-empty;
- starts at `CampusGeoMapData.chargingStation.position`;
- ends at the target zone center;
- uses standard latitude / longitude points.

Important calibration note:

The current intermediate route points are Demo approximate route nodes. They have not yet been manually verified point-by-point against the final map for road alignment or building crossing.

Before final production/demo calibration, these routes should be checked with the same map coordinate picker used by the UI side and adjusted to follow actual campus roads.

---

## 9. GeoLocationAdapter

目录：

`lib/adapters/geo_location/`

包含：

- `geo_location_adapter.dart`
- `demo_geo_location_adapter.dart`

Main API:

- `currentPosition`
- `watchRobotPosition()`
- `loadPath(path)`
- `start()`
- `pause()`
- `resume()`
- `stop()`
- `reset()`
- `dispose()`

`DemoGeoLocationAdapter` moves the robot through `plannedPath` using a fixed time interval.

Current behavior:

- `loadPath()` loads a new route and resets position to the first point.
- `start()` starts movement.
- `pause()` freezes movement.
- `resume()` continues movement.
- `stop()` stops movement.
- `reset()` returns to the first point and does not automatically restart.
- `dispose()` cancels the timer and closes the position stream.

---

## 10. Tests

Geo tests:

`test/campus_geo/`

包含：

- `campus_geo_point_test.dart`
- `campus_geo_map_data_test.dart`
- `demo_geo_location_adapter_test.dart`

Covered checks include:

- `findZoneById('lab_building')` -> 实验楼
- alias `一餐` -> `canteen_1`
- alias `二教` -> `teaching_2`
- latitude / longitude validity
- all P0 polygons are non-empty
- four main routes are non-empty
- routes start at charging station
- routes end at target zone center
- adapter start behavior
- adapter pause behavior
- adapter resume behavior
- adapter reset behavior

Validation completed before handoff:

- `flutter test --no-pub test/campus_geo` -> PASS
- `flutter test --no-pub` -> PASS
- `flutter analyze --no-pub` -> No issues found

---

## 11. Integration Notes for 1号 / 3号

1. Use `zoneId` as the stable identifier. Do not use Chinese display names as business identifiers.

2. UI map coordinates and Geo engine coordinates must use the same latitude / longitude coordinate system.

3. Do not directly mix GCJ-02 coordinates from AMap with the current OSM / FlutterMap latitude-longitude data.

4. UI can obtain zones from:

   `CampusGeoMapData.zones`

5. Target lookup can use:

   `CampusGeoMapData.findZoneById(id)`

   or:

   `CampusGeoMapData.findZoneByAlias(text)`

6. Route lookup can use:

   `CampusGeoMapData.routeForZone(zoneId)`

7. Robot movement simulation can load `plannedPath` into `DemoGeoLocationAdapter`.

8. Current P0 polygons and Demo routes still require final visual calibration on the same map before they are treated as production-quality geographic data.

---

## 12. Current Commit History

- `7ed3910` - `feat: add campus geo models`
- `1d85f0f` - `feat: add campus geo map data`
- `296f674` - `feat: add demo geo location adapter`

Final handoff/document commit SHA will be recorded after this document is committed.