import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/services/warning_service.dart';

class _WarningCase {
  final String name;
  final RobotWarningState state;
  final String? primaryWarningCode;
  final List<String> activeWarningCodes;
  final String? message;
  final String? severity;
  final bool hasWarning;
  final bool batteryValid;
  final TaskSafetyAction safetyAction;
  final bool canStart;
  final bool canPause;
  final bool canResume;
  final bool canStop;
  final bool canCharge;
  final bool canEmergencyStop;
  final bool canReset;
  final bool requireReset;

  const _WarningCase({
    required this.name,
    required this.state,
    required this.primaryWarningCode,
    required this.activeWarningCodes,
    required this.message,
    required this.severity,
    required this.hasWarning,
    this.batteryValid = true,
    this.safetyAction = TaskSafetyAction.none,
    this.canStart = true,
    this.canPause = true,
    this.canResume = true,
    this.canStop = true,
    this.canCharge = true,
    this.canEmergencyStop = true,
    this.canReset = false,
    this.requireReset = false,
  });
}

void main() {
  final service = WarningService();
  final cases = <_WarningCase>[
    const _WarningCase(
      name: '正常状态无故障且全部常规控制可用',
      state: RobotWarningState(battery: 80),
      primaryWarningCode: null,
      activeWarningCodes: <String>[],
      message: null,
      severity: null,
      hasWarning: false,
    ),
    const _WarningCase(
      name: '电量 19% 触发普通低电量 WARN-001',
      state: RobotWarningState(battery: 19),
      primaryWarningCode: 'WARN-001',
      activeWarningCodes: <String>['WARN-001'],
      message: '电量不足，建议返回充电',
      severity: 'medium',
      hasWarning: true,
    ),
    const _WarningCase(
      name: '电量 9% 触发严重低电量 WARN-002 并禁止开始',
      state: RobotWarningState(battery: 9),
      primaryWarningCode: 'WARN-002',
      activeWarningCodes: <String>['WARN-002'],
      message: '电量过低，禁止开始任务',
      severity: 'high',
      hasWarning: true,
      canStart: false,
    ),
    const _WarningCase(
      name: '设备离线触发 WARN-003 并禁用全部控制',
      state: RobotWarningState(online: false),
      primaryWarningCode: 'WARN-003',
      activeWarningCodes: <String>['WARN-003'],
      message: '机器人离线，请检查设备连接',
      severity: 'high',
      hasWarning: true,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canEmergencyStop: false,
    ),
    const _WarningCase(
      name: '紧急状态触发 WARN-004、stop 动作并要求复位',
      state: RobotWarningState(emergency: true),
      primaryWarningCode: 'WARN-004',
      activeWarningCodes: <String>['WARN-004'],
      message: '紧急停止已触发，请确认环境安全后复位',
      severity: 'high',
      hasWarning: true,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canReset: true,
      requireReset: true,
    ),
    const _WarningCase(
      name: '设备故障触发 WARN-005 和 stop 动作',
      state: RobotWarningState(deviceError: true),
      primaryWarningCode: 'WARN-005',
      activeWarningCodes: <String>['WARN-005'],
      message: '设备故障，请检查机器人',
      severity: 'high',
      hasWarning: true,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
      canCharge: false,
    ),
    const _WarningCase(
      name: '定位失败触发 WARN-006 和 stop 动作',
      state: RobotWarningState(locationFailed: true),
      primaryWarningCode: 'WARN-006',
      activeWarningCodes: <String>['WARN-006'],
      message: '定位失败，请检查定位模块',
      severity: 'medium',
      hasWarning: true,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '路径阻塞触发 WARN-007 和 pause 动作',
      state: RobotWarningState(pathBlocked: true),
      primaryWarningCode: 'WARN-007',
      activeWarningCodes: <String>['WARN-007'],
      message: '前方路径受阻，请重新规划任务',
      severity: 'medium',
      hasWarning: true,
      safetyAction: TaskSafetyAction.pause,
      canStart: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '任务失败触发低优先级 WARN-008',
      state: RobotWarningState(taskFailed: true),
      primaryWarningCode: 'WARN-008',
      activeWarningCodes: <String>['WARN-008'],
      message: '任务执行失败，请重新尝试',
      severity: 'low',
      hasWarning: true,
    ),
    const _WarningCase(
      name: '离线优先于普通低电量并保留两个活动代码',
      state: RobotWarningState(online: false, battery: 19),
      primaryWarningCode: 'WARN-003',
      activeWarningCodes: <String>['WARN-003', 'WARN-001'],
      message: '机器人离线，请检查设备连接',
      severity: 'high',
      hasWarning: true,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canEmergencyStop: false,
    ),
    const _WarningCase(
      name: '急停优先于设备故障且允许在线复位',
      state: RobotWarningState(emergency: true, deviceError: true),
      primaryWarningCode: 'WARN-004',
      activeWarningCodes: <String>['WARN-004', 'WARN-005'],
      message: '紧急停止已触发，请确认环境安全后复位',
      severity: 'high',
      hasWarning: true,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canReset: true,
      requireReset: true,
    ),
    const _WarningCase(
      name: '定位失败与路径阻塞组合时 stop 高于 pause',
      state: RobotWarningState(locationFailed: true, pathBlocked: true),
      primaryWarningCode: 'WARN-006',
      activeWarningCodes: <String>['WARN-006', 'WARN-007'],
      message: '定位失败，请检查定位模块',
      severity: 'medium',
      hasWarning: true,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '急停离线低电量组合保留优先级且离线禁止复位',
      state: RobotWarningState(online: false, battery: 19, emergency: true),
      primaryWarningCode: 'WARN-004',
      activeWarningCodes: <String>['WARN-004', 'WARN-003', 'WARN-001'],
      message: '紧急停止已触发，请确认环境安全后复位',
      severity: 'high',
      hasWarning: true,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canEmergencyStop: false,
      canReset: false,
      requireReset: true,
    ),
    const _WarningCase(
      name: '电量下边界 0% 是有效严重低电量',
      state: RobotWarningState(battery: 0),
      primaryWarningCode: 'WARN-002',
      activeWarningCodes: <String>['WARN-002'],
      message: '电量过低，禁止开始任务',
      severity: 'high',
      hasWarning: true,
      canStart: false,
    ),
    const _WarningCase(
      name: '电量上边界 100% 有效且无低电量警告',
      state: RobotWarningState(battery: 100),
      primaryWarningCode: null,
      activeWarningCodes: <String>[],
      message: null,
      severity: null,
      hasWarning: false,
    ),
    const _WarningCase(
      name: '非法电量 -1 触发 DATA-001 且禁止开始和继续',
      state: RobotWarningState(battery: -1),
      primaryWarningCode: 'DATA-001',
      activeWarningCodes: <String>['DATA-001'],
      message: '电量数据异常，请检查传感器',
      severity: 'high',
      hasWarning: true,
      batteryValid: false,
      canStart: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '非法电量 101 触发 DATA-001 且不得截断',
      state: RobotWarningState(battery: 101),
      primaryWarningCode: 'DATA-001',
      activeWarningCodes: <String>['DATA-001'],
      message: '电量数据异常，请检查传感器',
      severity: 'high',
      hasWarning: true,
      batteryValid: false,
      canStart: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '仅 customWarning 时显示最低优先级普通提示',
      state: RobotWarningState(customWarning: '请检查清扫刷'),
      primaryWarningCode: null,
      activeWarningCodes: <String>[],
      message: '请检查清扫刷',
      severity: 'low',
      hasWarning: true,
    ),
    const _WarningCase(
      name: '空白 customWarning 被忽略',
      state: RobotWarningState(customWarning: '   '),
      primaryWarningCode: null,
      activeWarningCodes: <String>[],
      message: null,
      severity: null,
      hasWarning: false,
    ),
    const _WarningCase(
      name: '任务失败标准警告优先于 customWarning',
      state: RobotWarningState(taskFailed: true, customWarning: '请检查清扫刷'),
      primaryWarningCode: 'WARN-008',
      activeWarningCodes: <String>['WARN-008'],
      message: '任务执行失败，请重新尝试',
      severity: 'low',
      hasWarning: true,
    ),
    const _WarningCase(
      name: '严重低电量优先于定位失败但安全动作为 stop',
      state: RobotWarningState(battery: 9, locationFailed: true),
      primaryWarningCode: 'WARN-002',
      activeWarningCodes: <String>['WARN-002', 'WARN-006'],
      message: '电量过低，禁止开始任务',
      severity: 'high',
      hasWarning: true,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '电量边界 10% 触发 WARN-001',
      state: RobotWarningState(battery: 10),
      primaryWarningCode: 'WARN-001',
      activeWarningCodes: <String>['WARN-001'],
      message: '电量不足，建议返回充电',
      severity: 'medium',
      hasWarning: true,
    ),
    const _WarningCase(
      name: '电量边界 20% 不触发低电量警告',
      state: RobotWarningState(battery: 20),
      primaryWarningCode: null,
      activeWarningCodes: <String>[],
      message: null,
      severity: null,
      hasWarning: false,
    ),
    const _WarningCase(
      name: '极端非法电量 -999 触发 DATA-001',
      state: RobotWarningState(battery: -999),
      primaryWarningCode: 'DATA-001',
      activeWarningCodes: <String>['DATA-001'],
      message: '电量数据异常，请检查传感器',
      severity: 'high',
      hasWarning: true,
      batteryValid: false,
      canStart: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '极端非法电量 999 触发 DATA-001',
      state: RobotWarningState(battery: 999),
      primaryWarningCode: 'DATA-001',
      activeWarningCodes: <String>['DATA-001'],
      message: '电量数据异常，请检查传感器',
      severity: 'high',
      hasWarning: true,
      batteryValid: false,
      canStart: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '普通低电量优先于任务失败并保留两个代码',
      state: RobotWarningState(battery: 19, taskFailed: true),
      primaryWarningCode: 'WARN-001',
      activeWarningCodes: <String>['WARN-001', 'WARN-008'],
      message: '电量不足，建议返回充电',
      severity: 'medium',
      hasWarning: true,
    ),
    const _WarningCase(
      name: '紧急停止标准警告覆盖 customWarning',
      state: RobotWarningState(emergency: true, customWarning: '请检查清扫刷'),
      primaryWarningCode: 'WARN-004',
      activeWarningCodes: <String>['WARN-004'],
      message: '紧急停止已触发，请确认环境安全后复位',
      severity: 'high',
      hasWarning: true,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canReset: true,
      requireReset: true,
    ),
    const _WarningCase(
      name: '离线标准警告覆盖 customWarning',
      state: RobotWarningState(online: false, customWarning: '请检查清扫刷'),
      primaryWarningCode: 'WARN-003',
      activeWarningCodes: <String>['WARN-003'],
      message: '机器人离线，请检查设备连接',
      severity: 'high',
      hasWarning: true,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canEmergencyStop: false,
    ),
    const _WarningCase(
      name: '普通低电量标准警告覆盖 customWarning',
      state: RobotWarningState(battery: 19, customWarning: '请检查清扫刷'),
      primaryWarningCode: 'WARN-001',
      activeWarningCodes: <String>['WARN-001'],
      message: '电量不足，建议返回充电',
      severity: 'medium',
      hasWarning: true,
    ),
    const _WarningCase(
      name: '离线优先于严重低电量且全部控制禁用',
      state: RobotWarningState(online: false, battery: 9),
      primaryWarningCode: 'WARN-003',
      activeWarningCodes: <String>['WARN-003', 'WARN-002'],
      message: '机器人离线，请检查设备连接',
      severity: 'high',
      hasWarning: true,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canEmergencyStop: false,
    ),
    const _WarningCase(
      name: '传感器异常与 19% 电量同时保留 DATA-001 和 WARN-001',
      state: RobotWarningState(battery: 19, batterySensorError: true),
      primaryWarningCode: 'DATA-001',
      activeWarningCodes: <String>['DATA-001', 'WARN-001'],
      message: '电量数据异常，请检查传感器',
      severity: 'high',
      hasWarning: true,
      batteryValid: false,
      canStart: false,
      canResume: false,
    ),
    const _WarningCase(
      name: '急停优先于非法电量并保留 DATA-001',
      state: RobotWarningState(battery: 101, emergency: true),
      primaryWarningCode: 'WARN-004',
      activeWarningCodes: <String>['WARN-004', 'DATA-001'],
      message: '紧急停止已触发，请确认环境安全后复位',
      severity: 'high',
      hasWarning: true,
      batteryValid: false,
      safetyAction: TaskSafetyAction.stop,
      canStart: false,
      canPause: false,
      canResume: false,
      canStop: false,
      canCharge: false,
      canReset: true,
      requireReset: true,
    ),
  ];

  group('WarningService', () {
    setUpAll(() {
      expect(WarningService.warningPriority, <String>[
        'WARN-004',
        'WARN-003',
        'WARN-005',
        'DATA-001',
        'WARN-002',
        'WARN-006',
        'WARN-007',
        'WARN-001',
        'WARN-008',
      ], reason: '标准故障匹配和主提示必须使用同一优先级顺序');
      expect(
        WarningService.completeWarningPriority,
        <String>[
          'WARN-004',
          'WARN-003',
          'WARN-005',
          'DATA-001',
          'WARN-002',
          'WARN-006',
          'WARN-007',
          'WARN-001',
          'WARN-008',
          'customWarning',
        ],
        reason: 'customWarning 必须保持最低展示优先级',
      );
    });

    for (var index = 0; index < cases.length; index += 1) {
      final testCase = cases[index];
      final caseId = 'WR-${(index + 1).toString().padLeft(3, '0')}';

      test('$caseId ${testCase.name}', () {
        final result = service.evaluate(testCase.state);

        expect(result.primaryWarningCode, testCase.primaryWarningCode);
        expect(result.activeWarningCodes, testCase.activeWarningCodes);
        expect(result.message, testCase.message);
        expect(result.severity, testCase.severity);
        expect(result.hasWarning, testCase.hasWarning);
        expect(result.batteryValid, testCase.batteryValid);
        expect(result.safetyAction, testCase.safetyAction);
        expect(result.canStart, testCase.canStart);
        expect(result.canPause, testCase.canPause);
        expect(result.canResume, testCase.canResume);
        expect(result.canStop, testCase.canStop);
        expect(result.canCharge, testCase.canCharge);
        expect(result.canEmergencyStop, testCase.canEmergencyStop);
        expect(result.canReset, testCase.canReset);
        expect(result.requireReset, testCase.requireReset);
        expect(result.warningCode, result.primaryWarningCode);
      });
    }
  });
}
