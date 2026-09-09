import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/pages/map_page.dart';
import 'package:robot_cleaner/widgets/geo_map/campus_geo_preview_page.dart';

void main() {
  testWidgets('single campus entry opens geographic map and returns', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    expect(find.byKey(const Key('open-campus-map')), findsNothing);
    expect(find.text('查看校园地图'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-geo-map')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(CampusGeoPreviewPage), findsOneWidget);
    expect(find.text('校园地图'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(CampusGeoPreviewPage), findsNothing);
    expect(find.text('查看校园地图'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
