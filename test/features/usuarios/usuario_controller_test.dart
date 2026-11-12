import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_estacionamento/features/features.dart';
import 'package:projeto_estacionamento/features/usuarios/repositories/usuario_repository.dart';
import 'package:projeto_estacionamento/features/usuarios/repositories/armazenamento_sessao.dart';

import '../../helpers/banco_falso.dart';

// Linhas como o mysql_client_plus devolve (tudo texto).
Map<String, Object?> linhaUsuario({
  String id = '7',
  String email = 'maria@goiabinha.com',
  String? telefone = '11900000002',
  String cargo = 'usuario',
  String ativo = '1',
  String senha = 'HASH_CERTO',
}) =>
    {
      'id': id,
      'nome_usuario': 'Maria Silva',
      'email': email,
      'numero_usuario': telefone,
      'cargo': cargo,
      'ativo': ativo,
      'senha': senha,
    };

void main() {
  late BancoFalso banco;
  late ArmazenamentoSessaoMemoria armazenamento;
  late DateTime agora;
  late List<Map<String, Object?>> tabela;

  UsuarioController criarController() => UsuarioController(
        repository: UsuarioRepository(banco),
        armazenamento: armazenamento,
        relogio: () => agora,
        // Falso: só a senha "Senha123" bate com o hash "HASH_CERTO".
        verificadorSenha: (senha, hash) async => hash == 'HASH_CERTO' && senha == 'Senha123',
      );

  setUp(() {
    agora = DateTime(2026, 11, 12, 10);
    armazenamento = ArmazenamentoSessaoMemoria();
    tabela = [linhaUsuario()];
    banco = BancoFalso(
      aoConsultar: (sql, p) {
        if (p.containsKey('login')) {
          return tabela
              .where((l) => l['email'] == p['login'] || l['numero_usuario'] == p['login'])
              .take(1)
              .toList();
        }
        if (p.containsKey('id')) {
          return tabela.where((l) => l['id'] == '${p['id']}').toList();
        }
        return [];
      },
    );
  });

  group('entrar', () {
    test('login com e-mail certo devolve o usuário e salva a sessão', () async {
      final auth = criarController();
      final usuario = await auth.entrar(login: '  Maria@Goiabinha.com ', senha: 'Senha123');

      expect(usuario.id, 7);
      expect(usuario.nome, 'Maria Silva');
      expect(auth.usuarioAtual, usuario);
      expect(auth.usuarioLogado.value, usuario);
      expect(await armazenamento.ler(), usuario);
      // e-mail foi normalizado antes de ir ao banco
      expect(banco.comandos.single.$2['login'], 'maria@goiabinha.com');
    });

    test('login com telefone formatado funciona (máscara é removida)', () async {
      final usuario = await criarController().entrar(login: '(11) 90000-0002', senha: 'Senha123');
      expect(usuario.telefone, '11900000002');
      expect(banco.comandos.single.$2['login'], '11900000002');
    });

    test('senha errada e e-mail inexistente dão a MESMA mensagem', () async {
      final auth = criarController();
      final erroSenha = await _capturar(() => auth.entrar(login: 'maria@goiabinha.com', senha: 'errada1'));
      final erroEmail = await _capturar(() => auth.entrar(login: 'ninguem@x.com', senha: 'Senha123'));

      expect(erroSenha.codigo, CodigoErro.credenciaisInvalidas);
      expect(erroEmail.codigo, CodigoErro.credenciaisInvalidas);
      expect(erroSenha.mensagem, erroEmail.mensagem);
      expect(auth.estaLogado, isFalse);
    });

    test('conta desativada não entra', () async {
      tabela = [linhaUsuario(ativo: '0')];
      final erro = await _capturar(() => criarController().entrar(login: 'maria@goiabinha.com', senha: 'Senha123'));
      expect(erro.codigo, CodigoErro.usuarioDesativado);
    });

    test('campos vazios/inválidos nem chegam ao banco', () async {
      final auth = criarController();
      expect((await _capturar(() => auth.entrar(login: '', senha: 'x'))).codigo, CodigoErro.dadosInvalidos);
      expect((await _capturar(() => auth.entrar(login: 'a@b.com', senha: ''))).codigo, CodigoErro.dadosInvalidos);
      expect((await _capturar(() => auth.entrar(login: '123', senha: 'x'))).codigo, CodigoErro.dadosInvalidos);
      expect(banco.comandos, isEmpty);
    });

    test('bloqueia depois de 5 erros seguidos e libera depois de 30s', () async {
      final auth = criarController();
      for (var i = 0; i < 5; i++) {
        await _capturar(() => auth.entrar(login: 'maria@goiabinha.com', senha: 'errada$i'));
      }
      final bloqueado = await _capturar(() => auth.entrar(login: 'maria@goiabinha.com', senha: 'Senha123'));
      expect(bloqueado.codigo, CodigoErro.muitasTentativas);
      expect(bloqueado.mensagem, contains('30 segundos'));

      agora = agora.add(const Duration(seconds: 31));
      final usuario = await auth.entrar(login: 'maria@goiabinha.com', senha: 'Senha123');
      expect(usuario.id, 7);
    });

    test('acerto zera o contador de erros', () async {
      final auth = criarController();
      for (var i = 0; i < 4; i++) {
        await _capturar(() => auth.entrar(login: 'maria@goiabinha.com', senha: 'errada'));
      }
      await auth.entrar(login: 'maria@goiabinha.com', senha: 'Senha123');
      for (var i = 0; i < 4; i++) {
        await _capturar(() => auth.entrar(login: 'maria@goiabinha.com', senha: 'errada'));
      }
      expect((await auth.entrar(login: 'maria@goiabinha.com', senha: 'Senha123')).id, 7);
    });
  });

  group('sessão', () {
    test('restaurarSessao confere no banco e devolve o usuário', () async {
      await armazenamento.salvar(Usuario.daLinha(linhaUsuario()));
      final auth = criarController();
      final usuario = await auth.restaurarSessao();
      expect(usuario?.id, 7);
      expect(auth.estaLogado, isTrue);
    });

    test('restaurarSessao derruba a sessão se a conta foi desativada', () async {
      await armazenamento.salvar(Usuario.daLinha(linhaUsuario()));
      tabela = [linhaUsuario(ativo: '0')];
      final auth = criarController();
      expect(await auth.restaurarSessao(), isNull);
      expect(await armazenamento.ler(), isNull);
    });

    test('restaurarSessao sem internet mantém o usuário salvo', () async {
      final salvo = Usuario.daLinha(linhaUsuario());
      await armazenamento.salvar(salvo);
      banco.aoConsultar = (_, _) => throw BackendException(CodigoErro.semConexao);
      final auth = criarController();
      expect(await auth.restaurarSessao(), salvo);
      expect(auth.estaLogado, isTrue);
    });

    test('sair limpa tudo', () async {
      final auth = criarController();
      await auth.entrar(login: 'maria@goiabinha.com', senha: 'Senha123');
      await auth.sair();
      expect(auth.estaLogado, isFalse);
      expect(await armazenamento.ler(), isNull);
    });

    test('exigirLogin', () async {
      final auth = criarController();
      expect(() => auth.exigirLogin(), throwsA(_codigo(CodigoErro.naoAutenticado)));
      await auth.entrar(login: 'maria@goiabinha.com', senha: 'Senha123');
      expect(auth.exigirLogin().id, 7);
    });
  });

  group('bcrypt real (compatível com o web)', () {
    test(r'aceita hash $2a$/$2b$ custo 12 gerado pelo Node', () async {
      // Gerado com bcryptjs (Node), mesmo algoritmo do backend web.
      const hash2a = r'$2a$12$IPnS6MD6PUVCBVosiOov1efmLLQtRJusHlJ9eLsHRaiIL84F/Zv7.';
      final hash2b = hash2a.replaceFirst(r'$2a$', r'$2b$');

      final auth = UsuarioController(repository: UsuarioRepository(banco), armazenamento: armazenamento);
      for (final hash in [hash2a, hash2b]) {
        tabela = [linhaUsuario(senha: hash)];
        await auth.sair();
        expect((await auth.entrar(login: 'maria@goiabinha.com', senha: 'Senha123')).id, 7);
        await expectLater(
          auth.entrar(login: 'maria@goiabinha.com', senha: 'senha123'),
          throwsA(_codigo(CodigoErro.credenciaisInvalidas)),
        );
      }
    });

    test('senha gravada sem criptografia é recusada', () async {
      tabela = [linhaUsuario(senha: '123')];
      final auth = UsuarioController(repository: UsuarioRepository(banco), armazenamento: armazenamento);
      await expectLater(
        auth.entrar(login: 'maria@goiabinha.com', senha: '123'),
        throwsA(_codigo(CodigoErro.credenciaisInvalidas)),
      );
    });

    test('hashpw do pacote também confere', () {
      final hash = BCrypt.hashpw('abc12345', BCrypt.gensalt(logRounds: 4));
      expect(BCrypt.checkpw('abc12345', hash), isTrue);
    });
  });
}

Future<BackendException> _capturar(Future<Object?> Function() acao) async {
  try {
    await acao();
  } on BackendException catch (e) {
    return e;
  }
  fail('Era esperado BackendException');
}

Matcher _codigo(CodigoErro codigo) =>
    isA<BackendException>().having((e) => e.codigo, 'codigo', codigo);
