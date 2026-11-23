import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:projeto_estacionamento/pages/login_page.dart';

// Testes das telas sem banco: só validação dos campos e navegação.
// (as regras do backend são testadas em test/features)
void main() {
  Future<void> abrirLogin(WidgetTester tester) async {
    // Tamanho de um celular comum (360 x 800).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
  }

  testWidgets('login vazio mostra os avisos dos campos', (tester) async {
    await abrirLogin(tester);

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe o e-mail ou telefone'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });

  testWidgets('login com telefone curto avisa antes de ir ao banco', (tester) async {
    await abrirLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, '1234');
    await tester.enterText(find.byType(TextFormField).last, 'qualquer');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail ou telefone válido'), findsOneWidget);
  });

  testWidgets('"Cadastre-se" abre o cadastro, que valida os campos', (tester) async {
    await abrirLogin(tester);

    await tester.tap(find.text('Cadastre-se'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastro'), findsOneWidget);

    // O formulário rola: garante que o botão está na tela antes de tocar.
    Future<void> tocarCadastrar() async {
      await tester.ensureVisible(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();
    }

    await tocarCadastrar();

    expect(find.text('Informe o nome'), findsOneWidget);
    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe o telefone'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);

    // Senha curta e telefone sem DDD usam as mesmas regras do backend.
    await tester.enterText(find.byType(TextFormField).at(2), '9999');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tocarCadastrar();
    expect(find.text('Informe um telefone válido com DDD'), findsOneWidget);
    expect(find.text('A senha deve ter pelo menos 6 caracteres'), findsOneWidget);

    // Voltar retorna ao login.
    await tester.ensureVisible(find.byTooltip('Voltar'));
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
  });
}
