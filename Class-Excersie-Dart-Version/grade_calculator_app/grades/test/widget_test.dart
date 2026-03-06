import 'package:flutter_test/flutter_test.dart';
import 'package:grades/main.dart';

void main() {
  testWidgets('GradeGenie app launches with welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GradeGenieApp());

    // Verify the welcome screen renders
    expect(find.text('GradeGenie'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Grading made'), findsOneWidget);
  });
}
