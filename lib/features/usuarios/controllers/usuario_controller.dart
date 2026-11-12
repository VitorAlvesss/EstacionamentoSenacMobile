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

/// Backend do LOGIN. É isso que a tela de login chama.
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
    DateTime Function()? relogio,
    this.maxTentativas = 5,
    this.tempoBloqueio = const Duration(seconds: 30),
  })  : _repository = repository ?? UsuarioRepository(),
        _armazenamento = armazenamento ?? ArmazenamentoSessaoLocal(),
        _verificarSenha = verificadorSenha ?? _verificarComBcrypt,
        _agora = relogio ?? DateTime.now;

  /// Instância única usada pelo app inteiro.
  static final UsuarioController instancia = UsuarioController();

  final UsuarioRepository _repository;
  final ArmazenamentoSessao _armazenamento;
  final VerificadorSenha _verificarSenha;
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

  /// Hash bcrypt (custo 12, igual ao web) de um texto aleatório que ninguém sabe.
  static const _hashFalso = r'$2a$12$Sqnp5li57JILGXYzULnpee.cJKRDD2zIXhRes4UdvMcGuXOztBAOG';

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
