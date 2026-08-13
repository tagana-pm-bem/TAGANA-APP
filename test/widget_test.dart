import 'package:flutter_test/flutter_test.dart';

import 'package:tagana_app/app.dart';

void main() {
  testWidgets('TAGANA app starts', (tester) async {
    await tester.pumpWidget(const TaganaApp());

    expect(find.text('Splash'), findsOneWidget);
  });
}