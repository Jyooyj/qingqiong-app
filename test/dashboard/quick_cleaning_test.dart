import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/data/campus_geo/campus_cleaning_catalog.dart';
import 'package:robot_cleaner/pages/home_page.dart';
import 'package:robot_cleaner/services/product_session.dart';

void main() {
  for (final id in CampusCleaningCatalog.shortcutIds) {
    testWidgets('home shortcut starts coordinator task: $id', (tester) async {
      final session = ProductSession();
      await tester.pumpWidget(MaterialApp(home: HomePage(session: session)));
      final button = find.byKey(Key('quick-clean-$id'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(session.currentTask?.campusZoneId, id);
      expect(session.campusCoordinator.selectedZoneId, id);
      expect(session.campusCoordinator.geoPlannedPath, isNotEmpty);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(find.text('A区'), findsNothing);
      expect(find.text('B区'), findsNothing);
      expect(find.text('C区'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    });
  }

  testWidgets('full selector includes routed non-shortcut areas and filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = ProductSession();
    await tester.pumpWidget(MaterialApp(home: HomePage(session: session)));
    expect(find.text('快捷清扫'), findsOneWidget);
    expect(find.text('学生宿舍'), findsNothing);
    final more = find.byKey(const Key('more-cleaning-areas'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('选择清扫区域'), findsOneWidget);
    expect(find.byKey(const Key('cleaning-area-dormitory')), findsOneWidget);
    expect(find.text('图书馆'), findsNothing);
    expect(find.text('第一教学楼'), findsNothing);
    await tester.enterText(find.byType(TextField), '不存在的地点');
    await tester.pump();
    expect(find.text('暂无符合条件的可执行清扫区域'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '宿舍');
    await tester.pump();
    await tester.tap(find.byKey(const Key('cleaning-area-dormitory')));
    await tester.pumpAndSettle();
    expect(session.currentTask?.campusZoneId, 'dormitory');
    expect(find.text('选择清扫区域'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
}
