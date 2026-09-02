import 'campus_voice_command_interpreter.dart';

enum CampusVoiceActionType {
  startCleaning,
  pause,
  resume,
  stop,
  charge,
  emergencyStop,
  reset,
  none,
}

class CampusVoiceAction {
  final CampusVoiceActionType type;
  final bool executable;
  final String? zoneId;
  final String? zoneName;
  final String message;
  final String originalText;

  const CampusVoiceAction({
    required this.type,
    required this.executable,
    required this.zoneId,
    required this.zoneName,
    required this.message,
    required this.originalText,
  });
}

class CampusVoiceActionMapper {
  const CampusVoiceActionMapper();

  CampusVoiceAction map(CampusVoiceInterpretation interpretation) {
    if (!interpretation.recognized ||
        !interpretation.shouldExecute ||
        interpretation.ambiguous) {
      return _none(interpretation);
    }

    final type = switch (interpretation.command) {
      'start' => CampusVoiceActionType.startCleaning,
      'pause' => CampusVoiceActionType.pause,
      'resume' => CampusVoiceActionType.resume,
      'stop' => CampusVoiceActionType.stop,
      'charge' => CampusVoiceActionType.charge,
      'emergencyStop' => CampusVoiceActionType.emergencyStop,
      'reset' => CampusVoiceActionType.reset,
      _ => CampusVoiceActionType.none,
    };

    if (type == CampusVoiceActionType.none) {
      return _none(interpretation);
    }

    return CampusVoiceAction(
      type: type,
      executable: true,
      zoneId: interpretation.zoneId,
      zoneName: interpretation.zoneName,
      message: interpretation.message,
      originalText: interpretation.originalText,
    );
  }

  CampusVoiceAction _none(CampusVoiceInterpretation interpretation) {
    return CampusVoiceAction(
      type: CampusVoiceActionType.none,
      executable: false,
      zoneId: null,
      zoneName: null,
      message: interpretation.message,
      originalText: interpretation.originalText,
    );
  }
}
