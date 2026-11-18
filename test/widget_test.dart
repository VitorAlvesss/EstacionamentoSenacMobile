import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_estacionamento/main.dart';

void main() {
  testWidgets('Fluxo: calcula e avança para o pagamento', (tester) async {
    await tester.pumpWidget(const AppEstacionamento());
    expect(find.text('R\$ 10,00'), findsWidgets);

    await tester.tap(find.text('Avançar para Pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Efetuar Pagamento'), findsWidgets);
  });
}