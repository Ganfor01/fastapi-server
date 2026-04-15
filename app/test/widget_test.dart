import 'package:flutter_test/flutter_test.dart';

import 'package:app_tareas/main.dart';

void main() {
  testWidgets('la app renderiza la pantalla principal', (WidgetTester tester) async {
    await tester.pumpWidget(const AppTareas());

    expect(find.text('Tu semana, ordenada sola.'), findsOneWidget);
    expect(find.text('Nuevo objetivo'), findsOneWidget);
  });
}
