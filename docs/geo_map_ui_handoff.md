# 真实地理地图 UI 交接

分支：feature/geo-map-ui
基线：feature/campus-demo-integration，c6c4541a2688839f2c781cbe5a38b34ec028fb34。
开发范围：完整 UI、临时测试数据和预览入口；未连接业务控制层。按队长要求仅本地提交，未 push。

## 打开预览

在项目根目录运行：

```sh
flutter pub get
flutter run -d chrome
```

底部“地图” → “查看真实地理地图”。选择临时区域可高亮并自动聚焦；“演示位置前进一步”由父页面替换位置与轨迹参数，不创建任务、不使用定时器。障碍开关检查显示与隐藏。开发版可开启坐标拾取，点击地图空白处并复制“纬度, 经度”。release 构建不显示拾取面板，也不会触发拾取回调。

旧 CampusMapView 和校园业务页面保留。底图失败面板提供重试与可选 onFallback；预览页通过返回原地图页作为备用入口。地图视野、图层和页面不因瓦片错误销毁。

## 依赖

- flutter_map 8.3.2
- latlong2 0.10.1
- url_launcher 6.3.2（打开 OSM 版权署名链接）

使用 https://tile.openstreetmap.org/{z}/{x}/{y}.png，保留可点击版权署名，原生端应用标识 org.qingqiong.robot_cleaner；Web 使用浏览器 User-Agent/Referer。没有批量预下载或离线抓取功能。公用瓦片服务没有可用性保证；正式部署应评估服务容量与网络条件。

参考：https://docs.fleaflet.dev/ ，https://operations.osmfoundation.org/policies/tiles/ 。

## 公开 API

导入 package:robot_cleaner/widgets/geo_map/campus_geo_map_view.dart。

| 参数 | 类型与默认值 |
|---|---|
| zones | List<CampusGeoZoneView>，必填 |
| selectedZoneId | String?，默认 null |
| robotPosition | LatLng?，默认 null |
| plannedPath / cleanedPath | List<LatLng>，默认空列表 |
| obstacles | List<CampusGeoMarkerView>，默认空列表 |
| chargingStation | CampusGeoMarkerView?，默认 null |
| onZoneTap | ValueChanged<String>? |
| initialCenter | LatLng，默认 30.88469, 121.89265（校园附近概览） |
| initialZoom | double，默认16 |
| enableCoordinatePicker | bool，默认false，且仅debug模式生效 |
| onCoordinatePicked | ValueChanged<LatLng>? |
| onFallback | VoidCallback?，由宿主决定备用地图入口 |
| tileLoadTimeout | Duration，默认20秒，当前视野无成功瓦片时提示不可用 |
| tileProviderFactory | TileProvider Function()?，主要用于注入无网络测试瓦片；每次重试需返回新实例，由 TileLayer 管理生命周期 |

CampusGeoZoneView：id / name / center(LatLng) / polygon(List<LatLng>)。
CampusGeoMarkerView：id / label / position(LatLng)。
这些是 UI 展示合同，不是 2 号的正式 Geo 引擎模型，避免新增重复 CampusGeoPoint 定义。

## 接入 2 号数据

```dart
LatLng point(CampusGeoPoint p) => LatLng(p.latitude, p.longitude);

CampusGeoMapView(
  zones: engineZones.map((z) => CampusGeoZoneView(
    id: z.id,
    name: z.name,
    center: point(z.center),
    polygon: z.polygon.map(point).toList(),
  )).toList(),
  selectedZoneId: selectedZoneId,
  robotPosition: point(robotGeoPosition),
  plannedPath: plannedGeoPath.map(point).toList(),
  cleanedPath: cleanedGeoPath.map(point).toList(),
  obstacles: engineObstacles.map((o) => CampusGeoMarkerView(
    id: o.id, label: '障碍', position: point(o.position),
  )).toList(),
  chargingStation: CampusGeoMarkerView(
    id: station.id, label: station.name, position: point(station.position),
  ),
  onZoneTap: selectZone,
)
```

上例变量由宿主提供，属性名按 2 号最终 API 对齐。经纬度顺序始终 latitude, longitude。不得传入旧 0..1 坐标或直接混入 GCJ-02。无效位置隐藏，无效区域跳过，含无效点的整条轨迹不绘制，避免断点被错误连成路线。

组件内部仅维护地图视野、加载提示和开发用拾取点；选区、机器人位置和轨迹始终由父组件传入。点击 Polygon 或区域标签仅回传 zoneId，不自行更新选区。selectedZoneId 改变时聚焦对应区域；只更新 robotPosition 不会重置用户视野。初次加载也支持已选区域。更新列表请传新列表。

## 临时数据限制

temporary_geo_data.dart 只提供校园附近三个临时区域和示意路线，用于完整 UI 验证。标签带“测试”，坐标、区域边界和路线没有正式校准，可能穿越建筑，不能当作正式路线交给机器人。校准数据由 2 号负责。中心点只用来找到上海海洋大学临港校区附近，参考 OSM 校园对象 https://www.openstreetmap.org/way/538422231 。

机器人与充电点距离小于2米时显示两个图标的组合标记，不表示设备正在充电。仅统计当前视野、当前缩放级别的瓦片。部分失败时提示“部分底图加载失败，已加载区域仍可使用”；全部失败或当前视野20秒没有成功瓦片时提示暂不可用。瓦片恢复、移出失败区域或重试后重新判断提示，不保留旧视野错误。未实现自动切换旧坐标地图，避免把不同坐标系错误混用。

## 验证

基线 flutter analyze --no-pub：PASS；基线测试367项全部通过。
当前 flutter analyze --no-pub：PASS；flutter test --no-pub：376项全部通过。
新增9项测试覆盖 Polygon 回调、受控选区、路线显示/清空、外部位置更新与不抢视野、缩放拖动、坐标拾取/复制/关闭、局部失败提示、移出失败视野自动清除提示、失败重试保留图层，以及360×800、390×844、430×932、1366×768。

测试注入本地图片，不访问公用瓦片服务器；真实网络显示另行浏览器验证。


## 浏览器验证和文件列表

Chrome 本地 debug Web 构建（flutter build web --debug --no-pub --no-web-resources-cdn）已加载真实校园底图，瓦片响应200，无页面JavaScript错误。四尺寸截图见 qa/screenshots/geo-map-ui/；截图包含真实底图、临时选区、规划路线、清扫轨迹和标记。临时位置前进与障碍开关已在浏览器操作。小屏页面允许纵向滚动；地图自身可缩放拖动。截图中的坐标仍是临时样例。

机器人与障碍/充电点相距小于2米时采用组合标记，保留各图标避免相互遮挡。没有改变输入坐标。

修改文件：
- pubspec.yaml / pubspec.lock：地图和署名链接依赖。
- .gitignore：排除自动生成的 Flutter 插件元数据。
- lib/pages/map_page.dart：真实地图预览入口。
- lib/widgets/geo_map/campus_geo_map_view.dart：外部驱动地图组件。
- lib/widgets/geo_map/geo_map_view_data.dart：UI展示合同。
- lib/widgets/geo_map/campus_geo_map_fallback.dart：失败提示和重试。
- lib/widgets/geo_map/campus_geo_preview_page.dart：完整UI预览，局部状态与手动位置步进。
- lib/widgets/geo_map/temporary_geo_data.dart：可替换的临时测试数据。
- test/widgets/campus_geo_map_view_test.dart：9项新增测试。
- docs/geo_map_ui_handoff.md：本说明。
- qa/screenshots/geo-map-ui/：四尺寸截图。

ProductSession、TaskController、RobotController、Voice、Safety、旧 CampusMapView 及旧校园数据无修改。2号交付正式Geo数据后，在宿主层映射至UI参数即可，不需要把临时样例合入正式数据引擎。

## 本轮验收与交付状态

2026-09-08 用户在 Chrome 确认：底图显示正常，未再出现此前的加载失败提示；选区切换、手动位置步进、障碍开关、缩放拖动及返回校园操作均正常。

一餐测试路线呈折线，是临时路径经过点依次连接的结果，已向用户说明。该验收只确认 UI 正常显示，不代表路线已沿实际道路校准。

代码提交：
- b039602bd67d0a9a624c09d8a50893b1d82227d0：完整真实地图 UI。
- 12b282876c48aeb5f1936018ddd8864c29173147：测试、截图与交接说明。
- 186cd781c40ccd79b774c4062ace000c8ccbb61b：当前视野底图状态修正；静态检查及376项测试通过。

上述提交应按分支整体交付，最后一个修复提交不包含此前全部功能。本文后续文档提交仅补充用户验收记录，未改动运行代码。

1号本轮 UI 工作已完成，可交队长审阅。仍待团队完成：2号提供校准区域、道路路径和统一经纬度数据；集成方在宿主层接入业务状态。暂停、急停与语音联动属于集成验收，本次独立 UI 预览不执行这些业务。

保持本地分支，按队长要求未 push。现有未跟踪 coverage/ 是测试产物，未纳入交付。
