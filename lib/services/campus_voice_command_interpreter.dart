import '../utils/voice_command_parser.dart';
import 'campus_zone_resolver.dart';

class CampusVoiceInterpretation {
  final bool recognized;
  final bool shouldExecute;
  final String? command;
  final String? zoneId;
  final String? zoneName;
  final String? matchedAlias;
  final bool ambiguous;
  final String message;
  final String originalText;
  final VoiceCommandResult? legacyParseResult;
  final CampusZoneResolution zoneResolution;

  const CampusVoiceInterpretation({
    required this.recognized,
    required this.shouldExecute,
    required this.command,
    required this.zoneId,
    required this.zoneName,
    required this.matchedAlias,
    required this.ambiguous,
    required this.message,
    required this.originalText,
    required this.legacyParseResult,
    required this.zoneResolution,
  });
}

class CampusVoiceCommandInterpreter {
  static const String ambiguousZoneMessage = '一次只能指定一个校园地点';
  static const String _parserPlaceholderArea = 'A区';

  final CampusZoneResolver _zoneResolver;
  final VoiceCommandParser _voiceCommandParser;

  CampusVoiceCommandInterpreter(
    CampusZoneResolver zoneResolver, {
    VoiceCommandParser? voiceCommandParser,
  }) : _zoneResolver = zoneResolver,
       _voiceCommandParser = voiceCommandParser ?? VoiceCommandParser();

  CampusVoiceInterpretation interpret(String text) {
    final zoneResolution = _zoneResolver.resolve(text);

    if (zoneResolution.ambiguous) {
      return CampusVoiceInterpretation(
        recognized: false,
        shouldExecute: false,
        command: null,
        zoneId: null,
        zoneName: null,
        matchedAlias: null,
        ambiguous: true,
        message: ambiguousZoneMessage,
        originalText: text,
        legacyParseResult: null,
        zoneResolution: zoneResolution,
      );
    }

    if (!zoneResolution.resolved) {
      final legacyResult = _voiceCommandParser.parse(text);
      return _fromLegacyResult(
        text: text,
        legacyResult: legacyResult,
        zoneResolution: zoneResolution,
      );
    }

    final parserText = _buildParserText(text, zoneResolution.matchedAlias!);
    final legacyResult = _voiceCommandParser.parse(parserText);

    return CampusVoiceInterpretation(
      recognized: legacyResult.recognized,
      shouldExecute: legacyResult.shouldExecute,
      command: legacyResult.command,
      zoneId: zoneResolution.zoneId,
      zoneName: zoneResolution.zoneName,
      matchedAlias: zoneResolution.matchedAlias,
      ambiguous: false,
      message: legacyResult.message,
      originalText: text,
      legacyParseResult: legacyResult,
      zoneResolution: zoneResolution,
    );
  }

  CampusVoiceInterpretation _fromLegacyResult({
    required String text,
    required VoiceCommandResult legacyResult,
    required CampusZoneResolution zoneResolution,
  }) {
    return CampusVoiceInterpretation(
      recognized: legacyResult.recognized,
      shouldExecute: legacyResult.shouldExecute,
      command: legacyResult.command,
      zoneId: null,
      zoneName: null,
      matchedAlias: null,
      ambiguous: false,
      message: legacyResult.message,
      originalText: text,
      legacyParseResult: legacyResult,
      zoneResolution: zoneResolution,
    );
  }

  String _buildParserText(String text, String matchedAlias) {
    final normalizedText = _removeSpaces(text);
    final normalizedAlias = _removeSpaces(matchedAlias);
    final textWithPlaceholder = normalizedText.replaceAll(
      normalizedAlias,
      _parserPlaceholderArea,
    );

    return textWithPlaceholder
        .replaceAll('$_parserPlaceholderArea附近', _parserPlaceholderArea)
        .replaceAll('$_parserPlaceholderArea周边', _parserPlaceholderArea);
  }

  String _removeSpaces(String text) {
    return text.replaceAll(RegExp(r'[\s\u3000]+'), '');
  }
}
