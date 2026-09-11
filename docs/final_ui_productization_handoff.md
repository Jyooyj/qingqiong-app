# 1号比赛版 UI 整改交接

## 版本与工作位置

公共基线：feature/geo-map-demo-integration，9f2fdbecb4e0893deb5f7617f776e3afb32cedf2。
工作分支：feature/final-ui-productization。2026-09-12 用户授权提交并推送本轮 UI 修改。
独立目录：/Users/zenghao/Documents/ChatGPT/清穹机器人/final-ui-productization。
原仓库的 INTERNET 权限修改与 coverage 未动。

## 已完成

- MapPage 直接展示 CampusGeoPreviewPage，底部地图入口不再默认显示旧 A/B/C 示意图。旧 CleaningMapView 代码和独立测试保留。
- 标题改为“上海海洋大学 · 校园智能清扫地图”，删除开发说明与废弃演示位置按钮。
- 地图状态卡读取 coordinator.currentTask、selectedZone 和 geoProgress；不创建额外计时器或任务进度。
- 地图标签用屏幕坐标进行碰撞处理：缩放级别低于17时弱化未选中点，放大后优先显示不重叠名称，选中标签保留完整名称，机器人最后绘制。没有调整 LatLng。
- 底图失败提示统一为“底图加载失败，请检查网络后重试”，重试及本地覆盖层保留。
- 任务卡与详情状态统一中文，补模式、换行布局、空状态；表单打开时隐藏 FAB；增加已暂停与已停止筛选。
- 首页异常模拟与自然语言控制文案、我的交互模式及演示模式整理；演示模式开启时使用主题色，禁用行为未改。
- 全局 Card 圆角16及标题对齐统一，告警页只清理开发提示，不改生命周期。
- Android 应用名称为“清穹”，保留主 Manifest INTERNET 权限；applicationId 未改。

## 公开 UI 接口

MapPage 保留原构造参数，兼容 AppShell；旧平面坐标不再渲染为默认地图。
CampusGeoPreviewPage 新增 pathBlocked（默认 false），只接收已有告警状态并在机器人位置显示告警图标，不操作任务暂停。
taskStatusLabel(String) 只负责显示映射，原状态字符串和回调语义保持不变。
CampusGeoMapView 原外部 zones/marker/path API 保留，可供2号完整 POI 适配后使用。

## 与2号、3号的边界

2号完整 POI/校园任务展示字段在当前基线尚未提供。本轮仍消费 CampusGeoMapData.zones，不复制建筑清单、不补造坐标。首页、任务表单的旧 A/B/C 兼容显示需合并2号数据映射后消除；不能宣称这项全局验收已通过。
地图 currentTask 名称来自现有 coordinator，后续使用2号稳定校园展示字段做最小适配。
“模拟路径阻塞”开关仍仅切换本地视觉覆盖层；3号需将回调接到既有 WARN-007/Safety 链。已有 AppShell.highlightedWarningCode 可直接映射为真实地图告警标记。
自然语言按钮仅更名，输入面板/解析/完成后再启动等业务回归归3号。本轮不修改 VoiceControlService 或 ProductSession。
经纬度/路线的演示性质没有被改成实测数据；面向用户不再展示开发说明，技术边界在此保留。

## 验证

- 修改 Dart 文件已 format。
- flutter analyze --no-pub：No issues found。
- flutter test --no-pub：382 passed。
- 新增三尺寸（360×800、390×844、430×932）五页 widget 布局检查，未检测到 overflow；同时验证状态卡共享进度、暂停显示、空任务及FAB隐藏、坐标不变。
- 原 WARN-007 集成显示断言已迁移到 geo-obstacle-WARN-007，安全断言未删除。
- git diff --check 通过；controllers/services/data/models 无修改。
- 为避开本机分析器处理中文路径异常，检查在 /private/tmp/qingqiong-final-ui 的同内容副本执行。
- 尚未进行真机视觉检查或打本轮新 APK。网络瓦片真实可用性仍需真机验收。

## 修改文件

- android/app/src/main/AndroidManifest.xml
- lib/main.dart
- lib/pages/map_page.dart
- lib/pages/tasks_page.dart
- lib/widgets/alerts/alert_detail_panel.dart
- lib/widgets/control_panel.dart
- lib/widgets/demo_fault_panel.dart
- lib/widgets/geo_map/campus_geo_map_view.dart
- lib/widgets/geo_map/campus_geo_preview_page.dart
- lib/widgets/profile/demo_mode_card.dart
- lib/widgets/profile/voice_settings_tile.dart
- lib/widgets/tasks/new_task_form.dart
- lib/widgets/tasks/task_card.dart
- lib/widgets/tasks/task_detail_view.dart
- lib/widgets/tasks/task_filter_bar.dart
- lib/widgets/tasks/task_view_data.dart
- test/alerts/alerts_page_test.dart
- test/navigation/app_shell_test.dart
- test/product_v1_integration_test.dart
- test/profile/profile_page_test.dart
- test/tasks/tasks_page_test.dart
- test/widgets/campus_geo_map_view_test.dart
- test/widgets/campus_map_navigation_test.dart
- test/widgets/final_ui_productization_test.dart（新增）
- docs/final_ui_productization_handoff.md（本说明）

## Git 状态

以下为验证完成、提交之前保存的文件清单：

```text
 M android/app/src/main/AndroidManifest.xml
 M lib/main.dart
 M lib/pages/map_page.dart
 M lib/pages/tasks_page.dart
 M lib/widgets/alerts/alert_detail_panel.dart
 M lib/widgets/control_panel.dart
 M lib/widgets/demo_fault_panel.dart
 M lib/widgets/geo_map/campus_geo_map_view.dart
 M lib/widgets/geo_map/campus_geo_preview_page.dart
 M lib/widgets/profile/demo_mode_card.dart
 M lib/widgets/profile/voice_settings_tile.dart
 M lib/widgets/tasks/new_task_form.dart
 M lib/widgets/tasks/task_card.dart
 M lib/widgets/tasks/task_detail_view.dart
 M lib/widgets/tasks/task_filter_bar.dart
 M lib/widgets/tasks/task_view_data.dart
 M test/alerts/alerts_page_test.dart
 M test/navigation/app_shell_test.dart
 M test/product_v1_integration_test.dart
 M test/profile/profile_page_test.dart
 M test/tasks/tasks_page_test.dart
 M test/widgets/campus_geo_map_view_test.dart
 M test/widgets/campus_map_navigation_test.dart
?? test/widgets/final_ui_productization_test.dart
```
