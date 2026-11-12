import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_estacionamento/features/features.dart';
import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';
import 'package:projeto_estacionamento/features/vagas/repositories/vaga_repository.dart';

import '../../helpers/banco_falso.dart';

/// Simula a tbl_vaga em memória, respondendo aos SQL do VagaRepository.
class TabelaVagas {
  final List<Map<String, Object?>> linhas = [
    {'id': '1', 'codigo_vaga': 'A01', 'vaga_especial': null, 'ocupada': '0'},
    {'id': '2', 'codigo_vaga': 'A02', 'vaga_especial': 'deficiente', 'ocupada': '1'},
    {'id': '3', 'codigo_vaga': 'A03', 'vaga_especial': 'idoso', 'ocupada': '1'},
    {'id': '4', 'codigo_vaga': 'A04', 'vaga_especial': 'idoso', 'ocupada': '0'},
  ];

  List<LinhaSql> consultar(String sql, Map<String, Object?> p) {
    if (sql.contains('COUNT(*)')) {
      final ocupadas = linhas.where((l) => l['ocupada'] == '1').length;
      return [
        {'total': '${linhas.length}', 'ocupadas': '$ocupadas', 'livres': '${linhas.length - ocupadas}'}
      ];
    }
    if (p.containsKey('id')) return linhas.where((l) => l['id'] == '${p['id']}').toList();
    if (p.containsKey('ocupada')) {
      final valor = p['ocupada'] == true ? '1' : '0';
      return linhas.where((l) => l['ocupada'] == valor).toList();
    }
    return List.of(linhas);
  }
}

void main() {
  late TabelaVagas tabela;
  late BancoFalso banco;
  late VagaController controller;

  setUp(() {
    tabela = TabelaVagas();
    banco = BancoFalso(aoConsultar: tabela.consultar);
    controller = VagaController(repository: VagaRepository(banco));
  });

  group('consultas', () {
    test('listarTodas converte as linhas do MySQL', () async {
      final vagas = await controller.listarTodas();
      expect(vagas.map((v) => v.codigo), ['A01', 'A02', 'A03', 'A04']);
      expect(vagas[0].tipo, TipoVaga.padrao);
      expect(vagas[0].livre, isTrue);
      expect(vagas[1].tipo, TipoVaga.deficiente);
      expect(vagas[1].tipo.rotulo, 'DEFICIENTE');
      expect(vagas[2].statusTexto, 'OCUPADA');
    });

    test('listarLivres traz só as disponíveis (e filtra por tipo)', () async {
      expect((await controller.listarLivres()).map((v) => v.id), [1, 4]);
      expect((await controller.listarLivres(tipo: TipoVaga.idoso)).map((v) => v.id), [4]);
      expect(await controller.listarLivres(tipo: TipoVaga.deficiente), isEmpty);
      expect(banco.comandos.last.$2, {'ocupada': false});
    });

    test('resumo calcula a taxa de ocupação', () async {
      final r = await controller.resumo();
      expect((r.total, r.ocupadas, r.livres), (4, 2, 2));
      expect(r.taxaOcupacaoTexto, '50%');
      expect(r.ocupacaoTexto, '2 de 4 vagas');
      expect(r.lotado, isFalse);
      expect(const ResumoVagas(total: 0, ocupadas: 0, livres: 0).taxaOcupacao, 0);
      expect(const ResumoVagas(total: 3, ocupadas: 3, livres: 0).lotado, isTrue);
    });

    test('buscarPorId', () async {
      expect((await controller.buscarPorId(4)).codigo, 'A04');
      await expectLater(controller.buscarPorId(99), throwsA(_codigo(CodigoErro.vagaNaoEncontrada)));
    });

    test('o backend de vagas nunca consulta placas/carros', () async {
      await controller.listarTodas();
      await controller.listarLivres();
      await controller.resumo();
      await controller.buscarPorId(2);
      for (final (sql, _) in banco.comandos) {
        expect(sql, isNot(contains('tbl_carro')));
        expect(sql, isNot(contains('tbl_registro_ocupacao')));
        expect(sql, startsWith('SELECT')); // só leitura
      }
    });
  });

  group('observarVagas', () {
    test('emite na hora, só repete quando muda, e para ao cancelar', () {
      fakeAsync((tempo) {
        final recebidos = <List<Vaga>>[];
        final assinatura = controller
            .observarVagas(intervalo: const Duration(seconds: 5))
            .listen(recebidos.add);

        tempo.flushMicrotasks();
        expect(recebidos, hasLength(1));

        tempo.elapse(const Duration(seconds: 10)); // nada mudou
        expect(recebidos, hasLength(1));

        tabela.linhas[0]['ocupada'] = '1'; // sensor ocupou A01
        tempo.elapse(const Duration(seconds: 5));
        expect(recebidos, hasLength(2));
        expect(recebidos.last.first.ocupada, isTrue);

        assinatura.cancel();
        final consultasAntes = banco.comandos.length;
        tempo.elapse(const Duration(seconds: 30));
        expect(banco.comandos.length, consultasAntes);
      });
    });

    test('erro de rede vai para o stream e ele se recupera', () {
      fakeAsync((tempo) {
        final dados = <List<Vaga>>[];
        final erros = <Object>[];
        final assinatura = controller
            .observarVagas(intervalo: const Duration(seconds: 5))
            .listen(dados.add, onError: erros.add);
        tempo.flushMicrotasks();

        banco.aoConsultar = (_, _) => throw BackendException(CodigoErro.semConexao);
        tempo.elapse(const Duration(seconds: 5));
        expect(erros.single, _codigo(CodigoErro.semConexao));

        banco.aoConsultar = tabela.consultar;
        tempo.elapse(const Duration(seconds: 5));
        expect(dados, hasLength(2)); // mesmo sem mudança, emite para sair do erro
        assinatura.cancel();
      });
    });

    test('observarResumo', () {
      fakeAsync((tempo) {
        final recebidos = <ResumoVagas>[];
        final assinatura = controller
            .observarResumo(intervalo: const Duration(seconds: 5))
            .listen(recebidos.add);
        tempo.flushMicrotasks();
        tabela.linhas[3]['ocupada'] = '1';
        tempo.elapse(const Duration(seconds: 5));
        expect(recebidos.map((r) => r.livres), [2, 1]);
        assinatura.cancel();
      });
    });
  });

  group('Validadores', () {
    test('login', () {
      expect(Validadores.login('maria@goiabinha.com'), isNull);
      expect(Validadores.login('(11) 90000-0002'), isNull);
      expect(Validadores.login(''), isNotNull);
      expect(Validadores.login('maria@'), isNotNull);
      expect(Validadores.login('1234'), isNotNull);
    });
  });
}

Matcher _codigo(CodigoErro codigo) =>
    isA<BackendException>().having((e) => e.codigo, 'codigo', codigo);
