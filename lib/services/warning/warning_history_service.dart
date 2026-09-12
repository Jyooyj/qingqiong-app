import '../warning_service.dart';
import 'warning_record.dart';

typedef WarningClock = DateTime Function();

class WarningHistoryService {
  WarningHistoryService({WarningClock? clock}) : _clock = clock ?? DateTime.now;

  final WarningClock _clock;
  final List<WarningRecord> _records = <WarningRecord>[];
  final Map<String, String> _activeRecordIdsByCode = <String, String>{};
  int _sequence = 0;

  List<WarningRecord> get allRecords =>
      List<WarningRecord>.unmodifiable(_records);

  List<WarningRecord> get currentWarnings => List<WarningRecord>.unmodifiable(
    _activeRecordIdsByCode.values.map(_recordById),
  );

  List<WarningRecord> get historyWarnings => List<WarningRecord>.unmodifiable(
    _records.where(
      (record) => !_activeRecordIdsByCode.containsValue(record.id),
    ),
  );

  List<WarningRecord> get unhandledWarnings => List<WarningRecord>.unmodifiable(
    _records.where(
      (record) => record.handleStatus == WarningHandleStatus.unhandled,
    ),
  );

  List<WarningRecord> get handledWarnings => List<WarningRecord>.unmodifiable(
    _records.where((record) => record.isHandled),
  );

  /// 将一次纯 [WarningResult] 快照同步为当前告警和历史告警。
  ///
  /// 同一 code 连续存在时不会重复建档；告警消失后再次出现会生成新记录。
  List<WarningRecord> synchronize(
    WarningResult result, {
    String? taskId,
    DateTime? occurredAt,
  }) {
    final activeCodes = _activeCodes(result);
    final clearedIds = _activeRecordIdsByCode.entries
        .where((entry) => !activeCodes.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    for (final id in clearedIds) {
      resolveWarning(id, reevaluated: result);
    }

    for (final code in activeCodes) {
      if (_activeRecordIdsByCode.containsKey(code)) {
        continue;
      }
      // Archiving must not depend on the presentation catalog being complete.
      final definition =
          _definitions[code] ??
          _WarningDefinition(
            title: result.message ?? '安全提示',
            level: switch (result.severity) {
              'high' => WarningLevel.high,
              'medium' => WarningLevel.medium,
              _ => WarningLevel.low,
            },
            message: result.message ?? '安全提示',
            recommendation: '请检查设备状态',
          );
      final timestamp = occurredAt ?? _clock();
      final record = WarningRecord(
        id: '$code-${timestamp.microsecondsSinceEpoch}-${_sequence++}',
        code: code,
        title: definition.title,
        level: definition.level,
        occurredAt: timestamp,
        message: code == result.primaryWarningCode && result.message != null
            ? result.message!
            : definition.message,
        recommendation: definition.recommendation,
        taskId: taskId,
        handleStatus: WarningHandleStatus.unhandled,
      );
      _records.add(record);
      _activeRecordIdsByCode[code] = record.id;
    }

    return currentWarnings;
  }

  WarningRecord acknowledgeWarning(String id) {
    final index = _indexOf(id);
    final record = _records[index];
    if (record.handleStatus == WarningHandleStatus.resolved) {
      return record;
    }
    final updated = record.copyWith(
      handleStatus: WarningHandleStatus.acknowledged,
    );
    _records[index] = updated;
    return updated;
  }

  /// 只有重新评估后安全条件已经消失，告警才允许标记为 resolved。
  ///
  /// 该方法不调用 RobotController，也不会解除急停锁存。
  bool resolveWarning(
    String id, {
    required WarningResult reevaluated,
    DateTime? resolvedAt,
  }) {
    final index = _indexOf(id);
    final record = _records[index];
    final conditionStillActive = _activeCodes(
      reevaluated,
    ).contains(record.code);
    final resetStillRequired =
        record.code == 'WARN-004' && reevaluated.requireReset;
    if (conditionStillActive || resetStillRequired) {
      return false;
    }

    _records[index] = record.copyWith(
      handleStatus: WarningHandleStatus.resolved,
      resolvedAt: resolvedAt ?? _clock(),
    );
    if (_activeRecordIdsByCode[record.code] == id) {
      _activeRecordIdsByCode.remove(record.code);
    }
    return true;
  }

  WarningRecord recordById(String id) => _recordById(id);

  Set<String> _activeCodes(WarningResult result) => {
    ...result.activeWarningCodes,
    if (result.hasWarning && result.activeWarningCodes.isEmpty)
      result.primaryWarningCode ?? 'customWarning',
  };

  int _indexOf(String id) {
    final index = _records.indexWhere((record) => record.id == id);
    if (index < 0) {
      throw ArgumentError.value(id, 'id', '未知告警记录');
    }
    return index;
  }

  WarningRecord _recordById(String id) => _records[_indexOf(id)];
}

class _WarningDefinition {
  const _WarningDefinition({
    required this.title,
    required this.level,
    required this.message,
    required this.recommendation,
  });

  final String title;
  final WarningLevel level;
  final String message;
  final String recommendation;
}

const Map<String, _WarningDefinition> _definitions =
    <String, _WarningDefinition>{
      'WARN-001': _WarningDefinition(
        title: '电量不足',
        level: WarningLevel.medium,
        message: '电量不足，建议返回充电',
        recommendation: '当前任务结束后尽快返回充电桩',
      ),
      'WARN-002': _WarningDefinition(
        title: '严重低电量',
        level: WarningLevel.high,
        message: '电量过低，禁止开始任务',
        recommendation: '禁止启动新清扫，并安排返回充电桩',
      ),
      'WARN-003': _WarningDefinition(
        title: '设备离线',
        level: WarningLevel.high,
        message: '机器人离线，请检查设备连接',
        recommendation: '检查网络与设备连接，恢复在线后重新评估',
      ),
      'WARN-004': _WarningDefinition(
        title: '紧急停止',
        level: WarningLevel.high,
        message: '紧急停止已触发，请确认环境安全后复位',
        recommendation: '确认现场安全后通过 RobotController.reset() 解除锁存',
      ),
      'WARN-005': _WarningDefinition(
        title: '设备故障',
        level: WarningLevel.high,
        message: '设备故障，请检查机器人',
        recommendation: '停止任务并检查设备，排除故障后重新评估',
      ),
      'WARN-006': _WarningDefinition(
        title: '定位失败',
        level: WarningLevel.medium,
        message: '定位失败，请检查定位模块',
        recommendation: '停止任务并恢复定位能力',
      ),
      'WARN-007': _WarningDefinition(
        title: '路径阻塞',
        level: WarningLevel.medium,
        message: '前方路径受阻，请重新规划任务',
        recommendation: '清除障碍并重新评估路径后再继续',
      ),
      'WARN-008': _WarningDefinition(
        title: '任务失败',
        level: WarningLevel.low,
        message: '任务执行失败，请重新尝试',
        recommendation: '检查失败原因后重新创建或执行任务',
      ),
      'DATA-001': _WarningDefinition(
        title: '数据异常',
        level: WarningLevel.high,
        message: '电量数据异常，请检查传感器',
        recommendation: '检查传感器，在数据恢复可信前禁止不安全操作',
      ),
    };
