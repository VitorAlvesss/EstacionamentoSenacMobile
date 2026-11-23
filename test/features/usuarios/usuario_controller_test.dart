import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';
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

  late List<String> senhasComHashGerado;

  UsuarioController criarController() => UsuarioController(
        repository: UsuarioRepository(banco),
        armazenamento: armazenamento,
        relogio: () => agora,
        // Falsos (rápidos): o "hash" de uma senha nova é "HASH:<senha>", e a
        // senha "Senha123" também bate com o hash "HASH_CERTO" da Maria.
        geradorHash: (senha) async {
          senhasComHashGerado.add(senha);
          return 'HASH:$senha';
        },
        verificadorSenha: (senha, hash) async =>
            hash == 'HASH:$senha' || (hash == 'HASH_CERTO' && senha == 'Senha123'),
      );

  setUp(() {
    agora = DateTime(2026, 11, 12, 10);
    armazenamento = ArmazenamentoSessaoMemoria();
    tabela = [linhaUsuario()];
    senhasComHashGerado = [];
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
        if (sql.contains('email_em_uso')) {
          final email = tabela.any((l) => l['email'] == p['email']);
          final telefone = p['telefone'] != null && tabela.any((l) => l['numero_usuario'] == p['telefone']);
          return [
            {'email_em_uso': email ? '1' : '0', 'telefone_em_uso': telefone ? '1' : '0'},
          ];
        }
        return [];
      },
      aoExecutar: (sql, p) {
        if (sql.startsWith('INSERT INTO tbl_usuario')) {
          final id = '${tabela.length + 7}';
          tabela.add({
            'id': id,
            'nome_usuario': p['nome'],
            'email': p['email'],
            'numero_usuario': p['telefone'],
            'cargo': 'usuario', // DEFAULT da tabela
            'ativo': '1', // DEFAULT da tabela
            'senha': p['senha'],
          });
          return ResultadoExecucao(linhasAfetadas: 1, idInserido: int.parse(id));
        }
        return const ResultadoExecucao(linhasAfetadas: 0);
      },
    );
  });

  group('cadastrar', () {
    test('grava os dados limpos, com hash da senha, e não faz login', () async {
      final auth = criarController();
      final usuario = await auth.cadastrar(
        nome: '  Ana   Souza ',
        email: ' Ana@Goiabinha.com ',
        telefone: '(11) 98888-7777',
        senha: 'segredo1',
      );

      expect(usuario.id, 8);
      expect(usuario.nome, 'Ana Souza');
      expect(usuario.email, 'ana@goiabinha.com');
      expect(usuario.telefone, '11988887777');
      expect(usuario.cargo, Cargo.usuario);
      expect(auth.estaLogado, isFalse); // igual ao web: cadastro manda para o login
      expect(await armazenamento.ler(), isNull);

      final (sql, parametros) = banco.comandos.last;
      expect(sql, startsWith('INSERT INTO tbl_usuario'));
      expect(sql, isNot(contains('cargo'))); // o app nunca escolhe o cargo
      expect(parametros, {
        'nome': 'Ana Souza',
        'email': 'ana@goiabinha.com',
        'telefone': '11988887777',
        'senha': 'HASH:segredo1', // nunca a senha pura
      });
    });

    test('depois do cadastro dá para entrar por e-mail e por telefone', () async {
      final auth = criarController();
      await auth.cadastrar(
        nome: 'Ana Souza',
        email: 'ana@goiabinha.com',
        telefone: '(11) 98888-7777',
        senha: 'segredo1',
      );

      expect((await auth.entrar(login: 'ana@goiabinha.com', senha: 'segredo1')).nome, 'Ana Souza');
      await auth.sair();
      expect((await auth.entrar(login: '11 98888-7777', senha: 'segredo1')).id, 8);
    });

    test('e-mail já cadastrado é recusado antes de gerar o hash', () async {
      final erro = await _capturar(() => criarController().cadastrar(
            nome: 'Outra Maria',
            email: 'MARIA@goiabinha.com',
            telefone: '11977776666',
            senha: 'segredo1',
          ));
      expect(erro.codigo, CodigoErro.emailEmUso);
      expect(erro.mensagem, 'Este e-mail já está em uso');
      expect(senhasComHashGerado, isEmpty);
      expect(banco.comandos.where((c) => c.$1.startsWith('INSERT')), isEmpty);
    });

    test('telefone já cadastrado é recusado', () async {
      final erro = await _capturar(() => criarController().cadastrar(
            nome: 'Ana Souza',
            email: 'ana@goiabinha.com',
            telefone: '(11) 90000-0002', // o da Maria
            senha: 'segredo1',
          ));
      expect(erro.codigo, CodigoErro.telefoneEmUso);
      expect(banco.comandos.where((c) => c.$1.startsWith('INSERT')), isEmpty);
    });

    test('telefone é opcional no backend (como no web): vai NULL', () async {
      for (final telefone in [null, '', '   ']) {
        tabela = [linhaUsuario()];
        final usuario = await criarController().cadastrar(
          nome: 'Ana Souza',
          email: 'ana@goiabinha.com',
          telefone: telefone,
          senha: 'segredo1',
        );
        expect(usuario.telefone, isNull);
        expect(banco.comandos.last.$2['telefone'], isNull);
      }
    });

    test('campos inválidos nem chegam ao banco', () async {
      final auth = criarController();
      Future<CodigoErro> tentar({
        String nome = 'Ana Souza',
        String email = 'ana@goiabinha.com',
        String? telefone = '11988887777',
        String senha = 'segredo1',
      }) async =>
          (await _capturar(() => auth.cadastrar(nome: nome, email: email, telefone: telefone, senha: senha)))
              .codigo;

      expect(await tentar(nome: '   '), CodigoErro.dadosInvalidos);
      expect(await tentar(nome: 'A' * 121), CodigoErro.dadosInvalidos);
      expect(await tentar(email: 'ana@'), CodigoErro.dadosInvalidos);
      expect(await tentar(telefone: '1234'), CodigoErro.dadosInvalidos);
      expect(await tentar(senha: '12345'), CodigoErro.dadosInvalidos);
      expect(await tentar(senha: 'a' * 73), CodigoErro.dadosInvalidos);
      expect(banco.comandos, isEmpty);
      expect(senhasComHashGerado, isEmpty);
    });

    test('se outra pessoa cadastrar o mesmo e-mail no mesmo instante, avisa e-mail em uso', () async {
      final inserirNormal = banco.aoExecutar!;
      banco.aoExecutar = (sql, p) {
        // Entre a conferência e o INSERT, alguém gravou o mesmo e-mail…
        inserirNormal(sql, p);
        // …e o UNIQUE do banco barra o nosso INSERT.
        throw BackendException(CodigoErro.registroDuplicado);
      };

      final erro = await _capturar(() => criarController().cadastrar(
            nome: 'Ana Souza',
            email: 'ana@goiabinha.com',
            telefone: '11988887777',
            senha: 'segredo1',
          ));
      expect(erro.codigo, CodigoErro.emailEmUso);
    });

    test('erro de conexão no INSERT chega como semConexao', () async {
      banco.aoExecutar = (_, _) => throw BackendException(CodigoErro.semConexao);
      final erro = await _capturar(() => criarController().cadastrar(
            nome: 'Ana Souza',
            email: 'ana@goiabinha.com',
            senha: 'segredo1',
          ));
      expect(erro.codigo, CodigoErro.semConexao);
    });
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

    test('cadastro grava hash bcrypt custo 12 e o login real aceita', () async {
      final auth = UsuarioController(repository: UsuarioRepository(banco), armazenamento: armazenamento);
      await auth.cadastrar(nome: 'Ana Souza', email: 'ana@goiabinha.com', senha: 'segredo1');

      final hash = tabela.last['senha']! as String;
      expect(hash, startsWith(r'$2a$12$')); // formato que o bcryptjs do web confere
      expect(BCrypt.checkpw('segredo1', hash), isTrue);
      expect((await auth.entrar(login: 'ana@goiabinha.com', senha: 'segredo1')).id, 8);
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
