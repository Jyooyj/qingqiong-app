# 清穹 App 3号模块交接说明

## 1. 已完成模块

### 语音命令解析器

文件位置：

- 规则文档：`voice_commands.md`
- 纯 Dart 实现：`standalone/voice_command_parser.dart`
- 独立 demo：`standalone/voice_command_parser_demo.dart`
- 测试用例文档：`test_cases.md`

当前支持 7 个标准命令：

- `start`：开始清扫
- `pause`：暂停任务
- `resume`：继续任务
- `stop`：普通停止任务
- `charge`：返回充电
- `emergencyStop`：紧急停止
- `reset`：解除急停并复位

命令优先级为：

`emergencyStop > reset > stop > pause > resume > charge > start`

解析器支持从语音文本中提取标准区域 `A区`、`B区`、`C区`，兼容区域字母大小写以及字母与“区”之间的空格。未指定区域时不会自行添加默认区域；同时出现多个不同区域或出现不支持区域时，整条命令会被拒绝。

解析器会优先拦截否定句、询问句、说明句、空输入、无关语句及其他无效表达。被拦截的输入返回 `recognized=false`，不会产生可执行的标准命令，也不得调用 `RobotController`。

普通停止与紧急停止的区别：

- `stop` 用于正常结束任务，例如“停止任务”“结束清扫”，不表示当前存在紧急危险。
- `emergencyStop` 用于需要立即停止的安全场景，例如“紧急停止”“立即停止任务”，优先级最高。
- 同一句同时命中普通停止和紧急停止时，只返回 `emergencyStop`。
- 否定或询问表达会先被安全拦截，不进入停止命令匹配。

`standalone/voice_command_parser_demo.dart` 当前包含 **59 条** demo 测试。当前仅完成静态验收，没有运行 Dart 编译、分析或 demo，实际运行通过数为 **0**，不得声称该模块测试已经通过。

### 故障提示服务

文件位置：

- 规则文档：`warning_rules.md`
- 纯 Dart 实现：`standalone/warning_service.dart`
- 独立 demo：`standalone/warning_service_demo.dart`
- 测试用例文档：`test_cases.md`

已实现的标准故障：

- `WARN-001`：普通低电量
- `WARN-002`：严重低电量
- `WARN-003`：设备离线
- `WARN-004`：紧急停止
- `WARN-005`：设备故障
- `WARN-006`：定位失败
- `WARN-007`：路径受阻
- `WARN-008`：任务执行失败
- `DATA-001`：电量数据异常

故障主提示优先级为：

`WARN-004 > WARN-003 > WARN-005 > DATA-001 > WARN-002 > WARN-006 > WARN-007 > WARN-001 > WARN-008 > customWarning`

`customWarning` 是无标准编号的最低优先级普通提示，不得与 `WARN-008`“任务执行失败”混淆，也不加入活动标准故障编号列表。

任务安全动作使用 `TaskSafetyAction`：

- `none`：不要求暂停或停止
- `pause`：请求暂停任务，路径受阻使用此动作
- `stop`：请求停止任务，紧急停止、设备故障和定位失败使用此动作

多个故障同时存在时，任务安全动作按 `stop > pause > none` 合并。

服务返回 7 个明确的控制权限字段：

- `canStart`
- `canPause`
- `canResume`
- `canStop`
- `canCharge`
- `canEmergencyStop`
- `canReset`

`primaryWarningCode` 只返回当前最高优先级标准故障；`activeWarningCodes` 按完整优先级保留全部活动标准故障，并以不可修改列表对外提供。非法电量或明确的传感器错误返回 `DATA-001`，不得把非法电量截断成 0 或 100 后继续判断。

`standalone/warning_service_demo.dart` 当前包含 **32 条** demo 测试。当前仅完成静态验收，没有运行 Dart 编译、分析或 demo，实际运行通过数为 **0**，不得声称该模块测试已经通过。

## 2. 交给1号的文件

未来迁移到 Flutter 项目时建议按以下位置放置：

- `voice_commands.md` → `docs/voice_commands.md`
- `warning_rules.md` → `docs/warning_rules.md`
- `test_cases.md` → `docs/test_cases.md`
- `standalone/voice_command_parser.dart` → `lib/utils/voice_command_parser.dart`
- `standalone/warning_service.dart` → `lib/services/warning_service.dart`

以下两个 demo 文件暂时保留，后续改造成 Flutter 单元测试或集成测试文件，不要直接删除：

- `standalone/voice_command_parser_demo.dart`
- `standalone/warning_service_demo.dart`

迁移时应保留现有纯逻辑模块与 Flutter、插件、页面和机器人控制层之间的边界，避免把语音识别、UI 或机器人状态修改逻辑写入解析器和故障提示服务。

## 3. 1号需要完成的接入工作

- 在 Flutter 项目中统一添加 `speech_to_text` 插件。
- 添加 Android 麦克风权限，并处理运行时权限申请。
- 创建语音识别服务，负责启动、停止识别以及错误和权限状态处理。
- 将语音识别得到的文字传入 `VoiceCommandParser`。
- 仅在解析结果允许执行时，将唯一标准命令交给 2 号提供的 `RobotController`。
- 将 `WarningService` 的主提示、活动故障、严重程度和安全动作显示在页面中。
- 根据 `canStart`、`canPause`、`canResume`、`canStop`、`canCharge`、`canEmergencyStop`、`canReset` 控制各按钮状态。
- 根据 `TaskSafetyAction` 通过统一控制层请求暂停或停止，不得由故障提示服务直接操作机器人。
- 不得让语音模块自行修改机器人状态，也不得绕过 `RobotController` 直接执行控制。
- 处理插件不可用、麦克风权限被拒绝、识别超时、空识别结果和控制器拒绝命令等接入异常。

## 4. 2号需要配合的接口

2 号需要通过统一的 `RobotController` 提供以下方法：

- `startCleaning()`
- `pauseCleaning()`
- `resumeCleaning()`
- `stopCleaning()`
- `returnToCharge()`
- `emergencyStop()`
- `resetEmergency()`

页面按钮和语音命令必须调用同一套 `RobotController` 逻辑，不能分别维护两套控制实现。控制器应统一进行在线状态、急停状态、设备故障、任务状态和控制权限校验，并向调用方返回明确的成功或失败结果。故障提示服务返回的权限和安全动作仅用于决定是否可以提交请求，不代表实际机器人操作已经成功。

## 5. 尚未完成的验证

- `dart format` 未执行。
- `dart analyze` 未执行。
- 两个纯 Dart demo 均未运行。
- 实际运行通过数为 **0**。
- 接入 Flutter 后必须重新编译并执行静态分析、单元测试、集成测试和必要的设备验证。
- 在完成实际验证前，不得声称语音命令解析器、故障提示服务或整个 3 号模块测试已经通过。
- `test_cases.md` 中的测试结果仍应保持“待执行”，直到对应测试被真实执行并记录结果。

## 6. 接入后的验证命令

Flutter 项目接入后执行：

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

如果迁移后仍保留纯 Dart demo，还需执行：

```bash
dart format standalone
dart analyze standalone
dart run standalone/voice_command_parser_demo.dart
dart run standalone/warning_service_demo.dart
```

命令必须在已经安装并正确配置 Flutter/Dart SDK 的环境中执行。执行失败时应记录实际输出，不得把未执行、编译失败或中途终止记为通过。

## 7. 协作注意事项

- 不直接在 `main` 分支开发。
- 3 号使用 `feature/voice-warning` 分支提交模块变更。
- 3 号不自行修改 `main.dart`。
- 3 号不自行修改 `pubspec.yaml` 和 `pubspec.lock`。
- 3 号不自行修改 `AndroidManifest.xml`。
- 新依赖和 Android 权限由 1 号统一添加和维护。
- 合并前必须运行 `analyze` 和 `test`，并处理所有阻断问题。
- Codex 只修改用户明确指定的文件，不扩大修改范围。
- 不上传 APK、`build` 目录、密钥、Token、签名文件或其他敏感信息。
- 合并前确认按钮和语音均通过同一个 `RobotController`，解析器和故障服务不得直接修改机器人状态。
- 两个 demo 在改造成正式测试前必须保留，删除或迁移需由 1 号统一确认。
