// 清穹 App 的纯 Dart 中文语音命令解析器。
//
// 本文件不依赖 Flutter、第三方插件或 RobotController。解析器只返回
// 识别结果，实际机器人状态修改必须由调用方统一交给 RobotController。

class VoiceCommandResult {
  final bool recognized;
  final String? command;
  final String? area;
  final String originalText;
  final String message;

  const VoiceCommandResult({
    required this.recognized,
    required this.command,
    required this.area,
    required this.originalText,
    required this.message,
  });

  /// 解析器本身不执行操作；该属性只表示调用方是否获得了可提交命令。
  bool get shouldExecute => recognized && command != null;

  @override
  String toString() {
    return 'VoiceCommandResult('
        'recognized: $recognized, '
        'command: $command, '
        'area: $area, '
        'originalText: "$originalText", '
        'message: "$message"'
        ')';
  }
}

class VoiceCommandParser {
  static const String invalidMessage = '未识别到有效控制指令';
  static const String unclearInstructionMessage = '该语句不是明确的控制指令';
  static const String unsupportedAreaMessage = '不支持的清扫区域';
  static const String multipleAreasMessage = '一次只能指定一个清扫区域';

  /// 命令规则的顺序就是唯一优先级来源。
  static final List<_CommandRule> _orderedRules = <_CommandRule>[
    _CommandRule('emergencyStop', <RegExp>[
      RegExp(r'^紧急停止(?:[abc]区(?:清扫)?)?$'),
      RegExp(r'^立即停止(?:当前)?(?:[abc]区)?(?:清扫)?(?:任务)?$'),
      RegExp(r'^(?:马上急停|启动急停|紧急制动|危险快停下|马上停下)$'),
    ]),
    _CommandRule('reset', <RegExp>[RegExp(r'^(?:解除急停|解除紧急状态|执行复位|确认复位)$')]),
    _CommandRule('stop', <RegExp>[
      RegExp(r'^(?:停止任务|停止清扫|结束清扫|终止任务|结束任务)(?:[abc]区)?$'),
      RegExp(r'^结束[abc]区清扫$'),
    ]),
    _CommandRule('pause', <RegExp>[
      RegExp(r'^(?:暂停一下|暂停任务|暂停清扫|先停一下|任务暂停)(?:[abc]区)?$'),
      RegExp(r'^暂停[abc]区的清扫任务$'),
    ]),
    _CommandRule('resume', <RegExp>[
      RegExp(r'^(?:继续清扫|继续任务|恢复清扫|恢复任务|接着清扫|继续工作)(?:[abc]区)?$'),
    ]),
    _CommandRule('charge', <RegExp>[
      RegExp(r'^(?:返回充电桩|回去充电|开始充电|返回充电|去充电|回充|回充电桩)$'),
    ]),
    _CommandRule('start', <RegExp>[
      RegExp(r'^(?:开始清扫|开始任务|启动清扫|执行清扫任务|开始工作|去清扫)(?:[abc]区)?$'),
      RegExp(r'^(?:执行[abc]区清扫|清扫[abc]区)$'),
    ]),
  ];

  /// 由有序规则表派生，不维护第二套优先级定义。
  static final List<String> commandPriority = List<String>.unmodifiable(
    _orderedRules.map((rule) => rule.command),
  );

  static final List<RegExp> _unsafeStatementPatterns = <RegExp>[
    RegExp(r'(?:不要|别|不用|禁止|不必|无需|不可|不能|不准)'),
    RegExp(
      r'(?:吗|呢|如何|怎么|怎样|能否|可否|是否|可以|能不能|可不可以|'
      r'为什么|什么意思|什么是|在哪里|在哪|按钮|含义|怎么说|请问|[？?])',
    ),
  ];

  static final RegExp _clauseSeparator = RegExp(r'(?:然后|之后|后|并且|并|[，,。；;！!])');

  static final RegExp _controlConnector = RegExp(r'(?:然后|之后|后|并且|并)');

  static final RegExp _punctuation = RegExp(r'[，,。；;！!、]');

  static final RegExp _politePrefix = RegExp(r'^(?:(?:请帮我|请|帮我|麻烦你|麻烦|现在))+');

  /// 解析一条中文语音识别文本。
  ///
  /// 安全拦截和区域校验发生在命令匹配之前。解析器不会调用控制器，也
  /// 不会修改机器人状态。
  VoiceCommandResult parse(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return _invalid(text, message: invalidMessage);
    }

    if (_isUnsafeStatement(normalized)) {
      return _invalid(text, message: unclearInstructionMessage);
    }

    final areaResult = _extractArea(normalized);
    if (!areaResult.valid) {
      return _invalid(text, message: areaResult.message!);
    }

    final clauseResult = _extractClauses(normalized);
    if (!clauseResult.valid) {
      return _invalid(text, message: unclearInstructionMessage);
    }

    final command = _detectCommand(clauseResult.clauses);
    if (command == null) {
      return _invalid(text, area: areaResult.area, message: invalidMessage);
    }

    return VoiceCommandResult(
      recognized: true,
      command: command,
      area: areaResult.area,
      originalText: text,
      message: '已识别指令：$command',
    );
  }

  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _isUnsafeStatement(String normalized) {
    return _unsafeStatementPatterns.any(
      (pattern) => pattern.hasMatch(normalized),
    );
  }

  _AreaExtraction _extractArea(String normalized) {
    final areas = <String>[];

    for (var index = 0; index < normalized.length; index += 1) {
      if (normalized[index] != '区') {
        continue;
      }
      if (_isOrdinaryAreaWord(normalized, index)) {
        continue;
      }
      if (index == 0) {
        return const _AreaExtraction.invalid(unsupportedAreaMessage);
      }

      final letter = normalized[index - 1].toUpperCase();
      if (letter != 'A' && letter != 'B' && letter != 'C') {
        return const _AreaExtraction.invalid(unsupportedAreaMessage);
      }

      if (index >= 2 && _isAsciiLetterOrDigit(normalized[index - 2])) {
        return const _AreaExtraction.invalid(unsupportedAreaMessage);
      }
      areas.add('$letter区');
    }

    final distinctAreas = areas.toSet();
    if (distinctAreas.length > 1) {
      return const _AreaExtraction.invalid(multipleAreasMessage);
    }
    if (distinctAreas.isEmpty) {
      return const _AreaExtraction.valid(null);
    }
    return _AreaExtraction.valid(distinctAreas.first);
  }

  bool _isOrdinaryAreaWord(String normalized, int areaCharacterIndex) {
    final isPartOfAreaWord =
        areaCharacterIndex + 1 < normalized.length &&
        normalized[areaCharacterIndex + 1] == '域';
    final isPartOfResidentialWord =
        areaCharacterIndex > 0 && normalized[areaCharacterIndex - 1] == '小';
    return isPartOfAreaWord || isPartOfResidentialWord;
  }

  bool _isAsciiLetterOrDigit(String character) {
    return RegExp(r'^[a-z0-9]$', caseSensitive: false).hasMatch(character);
  }

  _ClauseExtraction _extractClauses(String normalized) {
    final connectors = _controlConnector.allMatches(normalized).toList();
    if (connectors.isNotEmpty) {
      var previousEnd = 0;
      for (final connector in connectors) {
        final contentBeforeConnector = _prepareClause(
          normalized
              .substring(previousEnd, connector.start)
              .replaceAll(_punctuation, ''),
        );
        if (contentBeforeConnector.isEmpty) {
          return const _ClauseExtraction.invalid();
        }
        previousEnd = connector.end;
      }

      final contentAfterLastConnector = _prepareClause(
        normalized.substring(previousEnd).replaceAll(_punctuation, ''),
      );
      if (contentAfterLastConnector.isEmpty) {
        return const _ClauseExtraction.invalid();
      }
    }

    final clauses = <String>[];
    var previousEnd = 0;
    for (final separator in _clauseSeparator.allMatches(normalized)) {
      final clause = _prepareClause(
        normalized.substring(previousEnd, separator.start),
      );
      if (clause.isNotEmpty) {
        clauses.add(clause);
      }
      previousEnd = separator.end;
    }
    final finalClause = _prepareClause(normalized.substring(previousEnd));
    if (finalClause.isNotEmpty) {
      clauses.add(finalClause);
    }

    if (clauses.isEmpty) {
      return const _ClauseExtraction.invalid();
    }
    return _ClauseExtraction.valid(clauses);
  }

  String _prepareClause(String clause) {
    return clause.replaceFirst(_politePrefix, '');
  }

  String? _detectCommand(List<String> clauses) {
    int? selectedPriority;
    String? selectedCommand;

    for (final clause in clauses) {
      int? matchedPriority;
      for (var index = 0; index < _orderedRules.length; index += 1) {
        final rule = _orderedRules[index];
        if (rule.matchesEntireClause(clause)) {
          matchedPriority = index;
          break;
        }
      }
      if (matchedPriority == null) {
        return null;
      }
      if (selectedPriority == null || matchedPriority < selectedPriority) {
        selectedPriority = matchedPriority;
        selectedCommand = _orderedRules[matchedPriority].command;
      }
    }
    return selectedCommand;
  }

  VoiceCommandResult _invalid(
    String originalText, {
    String? area,
    required String message,
  }) {
    return VoiceCommandResult(
      recognized: false,
      command: null,
      area: area,
      originalText: originalText,
      message: message,
    );
  }
}

class _CommandRule {
  final String command;
  final List<RegExp> patterns;

  const _CommandRule(this.command, this.patterns);

  bool matchesEntireClause(String clause) {
    return patterns.any((pattern) => pattern.hasMatch(clause));
  }
}

class _AreaExtraction {
  final bool valid;
  final String? area;
  final String? message;

  const _AreaExtraction.valid(this.area) : valid = true, message = null;

  const _AreaExtraction.invalid(this.message) : valid = false, area = null;
}

class _ClauseExtraction {
  final bool valid;
  final List<String> clauses;

  const _ClauseExtraction.valid(this.clauses) : valid = true;

  const _ClauseExtraction.invalid() : valid = false, clauses = const <String>[];
}
