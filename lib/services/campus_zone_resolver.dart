class CampusZoneAliasEntry {
  final String id;
  final String name;
  final List<String> aliases;

  const CampusZoneAliasEntry({
    required this.id,
    required this.name,
    required this.aliases,
  });
}

class CampusZoneResolution {
  final bool resolved;
  final bool ambiguous;
  final String? zoneId;
  final String? zoneName;
  final String? matchedAlias;
  final List<String> candidateZoneIds;

  CampusZoneResolution({
    required this.resolved,
    required this.ambiguous,
    required this.zoneId,
    required this.zoneName,
    required this.matchedAlias,
    required List<String> candidateZoneIds,
  }) : candidateZoneIds = List<String>.unmodifiable(candidateZoneIds);
}

class CampusZoneResolver {
  final List<CampusZoneAliasEntry> _entries;

  CampusZoneResolver(List<CampusZoneAliasEntry> entries)
    : _entries = List<CampusZoneAliasEntry>.unmodifiable(entries);

  CampusZoneResolution resolve(String text) {
    final normalizedText = _normalize(text);
    final matchesByZoneId = <String, _ZoneMatch>{};

    for (final entry in _entries) {
      for (final alias in <String>[entry.name, ...entry.aliases]) {
        final normalizedAlias = _normalize(alias);
        if (normalizedAlias.isEmpty ||
            !normalizedText.contains(normalizedAlias)) {
          continue;
        }

        final currentMatch = matchesByZoneId[entry.id];
        if (currentMatch == null ||
            normalizedAlias.length > currentMatch.normalizedAliasLength) {
          matchesByZoneId[entry.id] = _ZoneMatch(
            entry: entry,
            alias: alias,
            normalizedAliasLength: normalizedAlias.length,
          );
        }
      }
    }

    if (matchesByZoneId.isEmpty) {
      return CampusZoneResolution(
        resolved: false,
        ambiguous: false,
        zoneId: null,
        zoneName: null,
        matchedAlias: null,
        candidateZoneIds: const <String>[],
      );
    }

    if (matchesByZoneId.length > 1) {
      return CampusZoneResolution(
        resolved: false,
        ambiguous: true,
        zoneId: null,
        zoneName: null,
        matchedAlias: null,
        candidateZoneIds: matchesByZoneId.keys.toList(growable: false),
      );
    }

    final match = matchesByZoneId.values.single;
    return CampusZoneResolution(
      resolved: true,
      ambiguous: false,
      zoneId: match.entry.id,
      zoneName: match.entry.name,
      matchedAlias: match.alias,
      candidateZoneIds: <String>[match.entry.id],
    );
  }

  static String _normalize(String text) {
    return text.replaceAll(RegExp(r'[\s\u3000]+'), '');
  }
}

class _ZoneMatch {
  final CampusZoneAliasEntry entry;
  final String alias;
  final int normalizedAliasLength;

  const _ZoneMatch({
    required this.entry,
    required this.alias,
    required this.normalizedAliasLength,
  });
}
