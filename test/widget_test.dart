import 'package:flutter_test/flutter_test.dart';
import 'package:robot_cleaner/main.dart';

void main() {
  testWidgets('QingQiong app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QingQiongApp());
    await tester.pumpAndSettle();

    expect(find.text('清穹无人清扫车'), findsOneWidget);
  });
}
