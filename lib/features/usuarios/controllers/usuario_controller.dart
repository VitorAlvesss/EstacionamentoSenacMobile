import 'dart:isolate';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';

import 'package:projeto_estacionamento/core/erros/backend_exception.dart';
import 'package:projeto_estacionamento/core/utils/validadores.dart';
import 'package:projeto_estacionamento/features/usuarios/models/usuario.dart';
import 'package:projeto_estacionamento/features/usuarios/repositories/usuario_repository.dart';
import 'package:projeto_estacionamento/features/usuarios/repositories/armazenamento_sessao.dart';

/// Compara a senha digitada com o hash do banco.
typedef VerificadorSenha = Future<bool> Function(String senha, String hash);

/// Gera o hash bcrypt de uma senha nova (cadastro).
typedef GeradorHash = Future<String> Function(String senha);

/// Backend do LOGIN e do CADASTRO. É isso que as telas chamam.
///
/// ```dart
/// try {
///   await UsuarioController.instancia.entrar(login: email, senha: senha);
///   // ir para a Home
/// } on BackendException catch (erro) {
///   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro.mensagem)));
/// }
/// ```
///
/// Segue as mesmas regras do login do web:
/// - aceita e-mail ou telefone;
/// - senha conferida com bcrypt (mesmos hashes que o web grava);
/// - mesma mensagem para "e-mail não existe" e "senha errada";
/// - conta desativada não entra.
class UsuarioController {
  UsuarioController({
    UsuarioRepository? repository,
    ArmazenamentoSessao? armazenamento,
    VerificadorSenha? verificadorSenha,
    GeradorHash? geradorHash,
    DateTime Function()? relogio,
    this.maxTentativas = 5,
    this.tempoBloqueio = const Duration(seconds: 30),
  })  : _repository = repository ?? UsuarioRepository(),
        _armazenamento = armazenamento ?? ArmazenamentoSessaoLocal(),
        _verificarSenha = verificadorSenha ?? _verificarComBcrypt,
        _gerarHash = geradorHash ?? _gerarHashBcrypt,
        _agora = relogio ?? DateTime.now;

  /// Instância única usada pelo app inteiro.
  static final UsuarioController instancia = UsuarioController();

  /// Custo do bcrypt das senhas novas: o mesmo `CUSTO_BCRYPT` (12) do módulo
  /// de login do web. O web confere qualquer custo, então os dois lados
  /// aceitam as senhas um do outro.
  static const custoBcrypt = 12;

  final UsuarioRepository _repository;
  final ArmazenamentoSessao _armazenamento;
  final VerificadorSenha _verificarSenha;
  final GeradorHash _gerarHash;
  final DateTime Function() _agora;

  /// Erros seguidos antes de bloquear novas tentativas por [tempoBloqueio].
  final int maxTentativas;
  final Duration tempoBloqueio;

  int _falhasSeguidas = 0;
  DateTime? _bloqueadoAte;

  final ValueNotifier<Usuario?> _usuarioLogado = ValueNotifier(null);

  /// Usuário logado, "escutável". Na tela:
  ///   ValueListenableBuilder(valueListenable: UsuarioController.instancia.usuarioLogado, ...)
  ValueListenable<Usuario?> get usuarioLogado => _usuarioLogado;

  Usuario? get usuarioAtual => _usuarioLogado.value;
  bool get estaLogado => usuarioAtual != null;

  /// Faz o login. Devolve o usuário ou lança [BackendException].
  Future<Usuario> entrar({required String login, required String senha}) async {
    final erroLogin = Validadores.login(login) ?? Validadores.senhaLogin(senha);
    if (erroLogin != null) {
      throw BackendException(CodigoErro.dadosInvalidos, mensagem: erroLogin);
    }
    _verificarBloqueio();

    final encontrado = await _repository.buscarPorLogin(Validadores.normalizarLogin(login));

    // Sempre roda o bcrypt (mesmo sem usuário) para o tempo de resposta não
    // entregar quais e-mails existem.
    final senhaCorreta = await _verificarSenha(senha, encontrado?.senhaHash ?? _hashFalso);

    if (encontrado == null || !senhaCorreta) {
      _registrarFalha();
      throw BackendException(CodigoErro.credenciaisInvalidas);
    }

    final usuario = encontrado.usuario;
    if (!usuario.ativo) throw BackendException(CodigoErro.usuarioDesativado);

    _falhasSeguidas = 0;
    _bloqueadoAte = null;
    await _iniciarSessao(usuario);
    return usuario;
  }

  /// Cadastra um usuário comum (é o `criar` / POST /usuarios do web).
  ///
  /// Devolve o usuário criado, mas NÃO faz login — igual ao web, que manda
  /// para a tela de login depois do cadastro. Lança [BackendException]:
  /// - [CodigoErro.dadosInvalidos] com a mensagem do campo errado;
  /// - [CodigoErro.emailEmUso] / [CodigoErro.telefoneEmUso].
  ///
  /// O telefone é opcional aqui (como no web); a tela pode exigi-lo usando
  /// `validator: Validadores.telefone`. Ele é gravado só com os dígitos, que é
  /// o formato que o login por telefone procura.
  Future<Usuario> cadastrar({
    required String nome,
    required String email,
    String? telefone,
    required String senha,
  }) async {
    final telefoneDigitado = telefone?.trim() ?? '';
    final temTelefone = telefoneDigitado.isNotEmpty;
    final erroCampo = Validadores.nome(nome) ??
        Validadores.email(email) ??
        (temTelefone ? Validadores.telefone(telefoneDigitado) : null) ??
        Validadores.senhaCadastro(senha);
    if (erroCampo != null) {
      throw BackendException(CodigoErro.dadosInvalidos, mensagem: erroCampo);
    }

    final nomeLimpo = Validadores.normalizarNome(nome);
    final emailLimpo = Validadores.normalizarEmail(email);
    final telefoneLimpo = temTelefone ? Validadores.somenteDigitos(telefoneDigitado) : null;

    // Confere antes de gastar tempo com o bcrypt.
    await _recusarSeEmUso(emailLimpo, telefoneLimpo);

    final senhaHash = await _gerarHash(senha);

    final int id;
    try {
      id = await _repository.inserir(
        nome: nomeLimpo,
        email: emailLimpo,
        telefone: telefoneLimpo,
        senhaHash: senhaHash,
      );
    } on BackendException catch (erro) {
      // Alguém cadastrou o mesmo e-mail/telefone entre a conferência e o
      // INSERT: o UNIQUE do banco barrou. Descobre qual foi para avisar certo.
      if (erro.codigo != CodigoErro.registroDuplicado) rethrow;
      await _recusarSeEmUso(emailLimpo, telefoneLimpo);
      rethrow;
    }

    return Usuario(id: id, nome: nomeLimpo, email: emailLimpo, telefone: telefoneLimpo);
  }

  /// Chame ao abrir o app: se o usuário já tinha logado, devolve ele
  /// (e confere no banco se a conta continua ativa). Senão devolve null.
  Future<Usuario?> restaurarSessao() async {
    final salvo = await _armazenamento.ler();
    if (salvo == null) return null;

    try {
      final atualizado = await _repository.buscarPorId(salvo.id);
      if (atualizado == null || !atualizado.ativo) {
        await sair();
        return null;
      }
      await _iniciarSessao(atualizado);
      return atualizado;
    } on BackendException catch (erro) {
      // Sem internet: mantém a sessão salva; o banco será conferido depois.
      if (erro.codigo == CodigoErro.semConexao) {
        _usuarioLogado.value = salvo;
        return salvo;
      }
      rethrow;
    }
  }

  /// Busca de novo os dados do usuário logado (ex.: depois de editar perfil).
  Future<Usuario> recarregarUsuario() async {
    final atual = exigirLogin();
    final atualizado = await _repository.buscarPorId(atual.id);
    if (atualizado == null || !atualizado.ativo) {
      await sair();
      throw BackendException(CodigoErro.usuarioDesativado);
    }
    await _iniciarSessao(atualizado);
    return atualizado;
  }

  Future<void> sair() async {
    _usuarioLogado.value = null;
    await _armazenamento.limpar();
  }

  /// Garante que tem alguém logado (os próximos controllers — veículo, pagamento,
  /// perfil — usam isso para agir sempre sobre o PRÓPRIO usuário).
  Usuario exigirLogin() {
    final usuario = usuarioAtual;
    if (usuario == null) throw BackendException(CodigoErro.naoAutenticado);
    return usuario;
  }

  // ---------------------------------------------------------------------------

  Future<void> _recusarSeEmUso(String email, String? telefone) async {
    final emUso = await _repository.verificarDadosEmUso(email: email, telefone: telefone);
    if (emUso.email) throw BackendException(CodigoErro.emailEmUso);
    if (emUso.telefone) throw BackendException(CodigoErro.telefoneEmUso);
  }

  Future<void> _iniciarSessao(Usuario usuario) async {
    _usuarioLogado.value = usuario;
    await _armazenamento.salvar(usuario);
  }

  void _verificarBloqueio() {
    final ate = _bloqueadoAte;
    if (ate == null) return;
    final restante = ate.difference(_agora());
    if (restante <= Duration.zero) {
      _bloqueadoAte = null;
      _falhasSeguidas = 0;
      return;
    }
    final segundos = (restante.inMilliseconds / 1000).ceil();
    throw BackendException(
      CodigoErro.muitasTentativas,
      mensagem: 'Muitas tentativas. Aguarde $segundos segundos e tente novamente',
    );
  }

  void _registrarFalha() {
    _falhasSeguidas++;
    if (_falhasSeguidas >= maxTentativas) {
      _bloqueadoAte = _agora().add(tempoBloqueio);
    }
  }

  /// Hash bcrypt (custo 12, o mesmo de [custoBcrypt]) de um texto aleatório
  /// que ninguém sabe.
  static const _hashFalso = r'$2a$12$Sqnp5li57JILGXYzULnpee.cJKRDD2zIXhRes4UdvMcGuXOztBAOG';

  /// Também em outra thread: custo 12 leva cerca de 1 s no celular.
  static Future<String> _gerarHashBcrypt(String senha) {
    return Isolate.run(() => BCrypt.hashpw(senha, BCrypt.gensalt(logRounds: custoBcrypt)));
  }

  /// bcrypt é pesado de propósito: roda em outra thread para a tela não travar.
  static Future<bool> _verificarComBcrypt(String senha, String hash) async {
    if (!hash.startsWith(r'$2')) return false; // senha antiga sem criptografia: recusa
    try {
      return await Isolate.run(() => BCrypt.checkpw(senha, hash));
    } catch (_) {
      return false; // hash malformado
    }
  }
}
