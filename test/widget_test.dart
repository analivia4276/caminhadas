import 'package:flutter_test/flutter_test.dart';
import 'package:caminhadas/main.dart';

void main() {
  testWidgets('Aplicativo inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const CaminhadasApp());

    expect(find.text('Caminhadas'), findsOneWidget);
  });
}