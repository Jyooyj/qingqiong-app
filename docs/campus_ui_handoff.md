# 校园地图 UI 交接

分支：feature/campus-map-ui。基于产品整合版 bacf1f0 开发。交付 commit 可在本分支 Git 历史中查询。

## 查看方式

运行 flutter run -d chrome，进入底部地图页，点击“查看校园地图”。
当前页面是可点击的校园示意预览，选择地点仅预览路线，不会创建任务或驱动机器人。旧任务地图保留。

## 数据来源

复用 origin/feature/campus-map-engine 的 8147bc7585c693478e482ad4bcf4da4cf4f695d1 中 CampusPoint、CampusZone、CampusRoute、CampusObstacle、CampusChargingStation 和 CampusMapData；仅格式化。
未合并整个旧分支，未引入位置服务、未修改 TaskController、RobotController 或 main.dart。

坐标均为 0..1；UI 约定左上为原点，x 向右、y 向下。未核实为实测校园地理坐标。部分区域边界重叠，地图点击采用后绘制区域优先；地点按钮可以明确选择全部区域。

## 公开组件

导入 package:robot_cleaner/widgets/campus/campus_map_view.dart。

CampusMapView 参数：

| 参数 | 类型 | 默认值 |
|---|---|---|
| zones | List<CampusZone> | 必填 |
| selectedZoneId | String? | null |
| robotPosition | CampusPoint? | null，不显示机器人 |
| plannedPath | List<CampusPoint> | 空列表 |
| cleanedPath | List<CampusPoint> | 空列表 |
| obstacles | List<CampusObstacle> | 空列表 |
| chargingStation | CampusChargingStation? | null |
| onZoneTap | ValueChanged<String>? | null，禁用选择 |

```dart
CampusMapView(
  zones: CampusMapData.zones,
  selectedZoneId: selectedZoneId,
  robotPosition: mapState.robotPosition,
  plannedPath: mapState.plannedPath,
  cleanedPath: mapState.cleanedPath,
  obstacles: mapState.obstacles,
  chargingStation: mapState.chargingStation,
  onZoneTap: (zoneId) => setState(() => selectedZoneId = zoneId),
)
```

组件完全由参数驱动，不直接读写任何控制器，不包含计时器或位置动画。选择回调不自行改变 selectedZoneId；父组件更新参数才切换高亮。相同数据保持位置和轨迹不动。

## 待 3 号集成

用统一的目标 zoneId 接语音结果与地图选中状态；从位置服务传入地图状态。障碍标记应只传入实际有效障碍，CampusObstacle 当前没有 warningCode。预览开关仅显示样例，不触发 WARN-007。暂停、急停及 reset 仍由控制层执行。

本轮已提供任务卡展示接口，尚未接入真实任务数据、真实校园底图、语音联动或任务历史校园名称，未完成最终比赛闭环。预览不会假装任务正在运行。

## 验证

flutter analyze 通过，flutter test 250 项通过。新增测试覆盖外部选中状态、点击回调、位置更新和冻结、障碍与充电点、入口返回，以及 360×800、390×844、430×932、1366×768 无布局异常。2026-09-07 用户确认已完成 360×800、390×844、430×932、1366×768 四种尺寸的浏览器人工检查，显示与点击均正常。四尺寸截图尚未全部归档到仓库。


## 第二轮界面完善

- 主干道地图标签缩写为“主干道”，单行展示；完整名称保留在地点选择按钮。
- 机器人与充电桩屏幕距离小于 30 像素时，在充电桩锚点显示组合标记，两个图标并列。仅表示位置靠近，不表示正在充电；原始坐标未被修改。
- 建筑类别配色、屋顶线条与道路虚线全部限制在输入区域内，不新增虚构地理数据。
- CampusMapView 新增可选 taskData 和 onPause / onResume / onEmergencyStop / onReset 参数；任务卡显示在图例下方。

任务数据导入：package:robot_cleaner/widgets/campus/current_task_map_card.dart。
CampusTaskViewData 包含 targetZoneName(String?)、status(CampusTaskStatus)、progress(double? 百分比 0..100)、cleanedArea(double? 平方米)、elapsed(Duration?)、battery(double? 百分比 0..100)、message(String?)。
状态枚举：preview / pending / running / paused / fault / emergency / completed。
缺失、非有限数或超出有效范围的数据显示“—”；不伪造运行进度或电量。

CurrentTaskMapCard 可独立使用。preview 状态隐藏操作按钮，其他状态显示按钮；空回调禁用按钮。控制层必须传入经过 Safety 判断允许的回调，组件不实现或绕过安全判断。点击按钮不改变卡片状态；只有外部数据更新才重绘状态。

第二轮 flutter analyze 无问题，flutter test 250 项全部通过，含任务数据格式、未知值处理、回调、禁用操作、组合标记和四种尺寸布局检查。第一轮预览已由用户确认地点切换、高亮、路线、障碍可见；第二轮已由用户确认全部四种尺寸显示与点击正常。


## 交付文件

- lib/pages/map_page.dart：原地图页增加校园预览入口。
- lib/widgets/campus/campus_map_view.dart：受外部数据控制的校园地图。
- lib/widgets/campus/campus_demo_page.dart：独立交互预览。
- lib/widgets/campus/current_task_map_card.dart：任务展示模型与操作回调。
- lib/models/campus/campus_point.dart、campus_zone.dart、campus_route.dart、campus_map_objects.dart：复用 2 号模型。
- lib/data/campus/campus_map_data.dart：复用 2 号校园数据。
- test/widgets/campus_map_view_test.dart、campus_task_card_test.dart：新增 14 项 UI 测试。
- docs/campus_ui_handoff.md：本交接说明。

集成时先接 2 号引擎，再接本 UI。上述共享模型与数据来自 2 号旧提交，若 2 号已有更新，应保留其最新定义并适配 UI，不要覆盖新的数据修正。
