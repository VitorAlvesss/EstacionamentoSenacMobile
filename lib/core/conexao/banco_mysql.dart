import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:mysql_client_plus/exception.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';

import 'package:projeto_estacionamento/core/config/banco_config.dart';
import 'package:projeto_estacionamento/core/erros/backend_exception.dart';
import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';

/// Conexão com o MySQL (é o "db.js" do mobile).
///
/// - Usa um pool pequeno de conexões, aberto só na primeira consulta.
/// - Se o celular perder a rede ou o servidor derrubar a conexão, o pool é
///   recriado sozinho e a consulta é tentada de novo uma vez.
/// - Todo erro sai como [BackendException] com mensagem amigável.
class BancoMySql implements ExecutorSql {
  BancoMySql(this.config);

  /// Instância única usada pelo app inteiro.
  static final BancoMySql instancia = BancoMySql(BancoConfig.doAmbiente());

  final BancoConfig config;
  MySQLConnectionPool? _pool;

  // Códigos de erro do servidor MySQL que tratamos de forma especial.
  static const _erroAcessoNegado = 1045;
  static const _erroBancoNaoExiste = 1049;
  static const _erroRegistroDuplicado = 1062;

  @override
  Future<List<LinhaSql>> consultar(String sql, [Map<String, Object?> parametros = const {}]) {
    // SELECT pode ser repetido sem efeito colateral, então tentamos de novo
    // mesmo se a primeira tentativa travar no meio.
    return _rodar(sql, parametros, podeRepetir: true, (resultado) {
      return [for (final linha in resultado.rows) linha.assoc()];
    });
  }

  @override
  Future<ResultadoExecucao> executar(String sql, [Map<String, Object?> parametros = const {}]) {
    // INSERT/UPDATE só é repetido se tivermos certeza de que não chegou ao
    // servidor (conexão já estava fechada) — evita gravar duas vezes.
    return _rodar(sql, parametros, podeRepetir: false, (resultado) {
      return ResultadoExecucao(
        linhasAfetadas: resultado.affectedRows.toInt(),
        idInserido: resultado.lastInsertID.toInt(),
      );
    });
  }

  /// Confere se o app consegue falar com o banco (bom para uma tela de diagnóstico).
  Future<void> testarConexao() => consultar('SELECT 1 AS ok');

  /// Fecha todas as conexões (ex.: quando o app for encerrado).
  Future<void> fechar() async {
    final pool = _pool;
    _pool = null;
    if (pool != null) await _fecharSemErro(pool);
  }

  // ---------------------------------------------------------------------------

  Future<T> _rodar<T>(
    String sql,
    Map<String, Object?> parametros,
    T Function(IResultSet resultado) converter, {
    required bool podeRepetir,
  }) async {
    if (!config.valida) {
      throw BackendException(
        CodigoErro.configuracaoAusente,
        mensagem: 'Configuração do banco incompleta (faltando: '
            '${config.camposFaltando.join(', ')}). Rode o app com '
            '--dart-define-from-file=config/banco.json',
      );
    }

    for (var tentativa = 1;; tentativa++) {
      try {
        final resultado = await _pegarPool()
            .execute(sql, parametros.isEmpty ? null : parametros)
            .timeout(config.tempoLimite);
        return converter(resultado);
      } catch (erro) {
        final conexaoQuebrada = _conexaoQuebrada(erro);
        if (conexaoQuebrada) _descartarPool();

        // "connection closed" / "pool is closed": o comando nem foi enviado.
        final naoChegouAoServidor = erro is MySQLClientException &&
            erro.message.toLowerCase().contains('closed');
        final repetir = tentativa == 1 &&
            conexaoQuebrada &&
            (podeRepetir || naoChegouAoServidor);

        if (repetir) {
          dev.log('Conexão perdida, tentando de novo…', name: 'backend');
          continue;
        }
        throw _traduzirErro(erro);
      }
    }
  }

  MySQLConnectionPool _pegarPool() {
    return _pool ??= MySQLConnectionPool(
      host: config.host,
      port: config.porta,
      userName: config.usuario,
      password: config.senha,
      databaseName: config.banco,
      maxConnections: config.maxConexoes,
      secure: config.ssl,
      onBadCertificate: config.aceitarCertificadoInvalido ? (_) => true : null,
      timeoutMs: config.tempoLimite.inMilliseconds,
    );
  }

  /// Joga o pool fora (as conexões podem estar travadas) — o próximo uso cria outro.
  void _descartarPool() {
    final pool = _pool;
    _pool = null;
    if (pool != null) unawaited(_fecharSemErro(pool));
  }

  static Future<void> _fecharSemErro(MySQLConnectionPool pool) async {
    try {
      await pool.close();
    } catch (_) {
      // conexão já estava morta; nada a fazer
    }
  }

  static bool _conexaoQuebrada(Object erro) {
    if (erro is SocketException || erro is TimeoutException || erro is TlsException) {
      return true;
    }
    if (erro is MySQLClientException && erro is! MySQLProtocolException) {
      final mensagem = erro.message.toLowerCase();
      return mensagem.contains('closed') || mensagem.contains('connection');
    }
    return false;
  }

  static BackendException _traduzirErro(Object erro) {
    dev.log('Erro no banco', name: 'backend', error: erro);

    if (erro is BackendException) return erro;

    if (erro is SocketException || erro is TimeoutException || erro is TlsException) {
      return BackendException(CodigoErro.semConexao, causa: erro);
    }

    if (erro is MySQLServerException) {
      switch (erro.errorCode) {
        case _erroRegistroDuplicado:
          return BackendException(CodigoErro.registroDuplicado, causa: erro);
        case _erroAcessoNegado:
        case _erroBancoNaoExiste:
          return BackendException(CodigoErro.bancoIndisponivel,
              mensagem: 'O banco recusou o acesso. Confira usuário, senha e nome '
                  'do banco em config/banco.json',
              causa: erro);
      }
      return BackendException(CodigoErro.bancoIndisponivel, causa: erro);
    }

    if (_conexaoQuebrada(erro)) {
      return BackendException(CodigoErro.semConexao, causa: erro);
    }

    return BackendException(CodigoErro.erroInterno, causa: erro);
  }
}
