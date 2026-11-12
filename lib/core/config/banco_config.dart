/// Configuração de acesso ao MySQL.
///
/// Os valores vêm do `--dart-define-from-file=config/banco.json` (mesmos nomes
/// do `.env` do projeto web), então a senha do banco nunca fica escrita no
/// código nem vai para o GitHub.
///
/// Como rodar:
///   flutter run --dart-define-from-file=config/banco.json
class BancoConfig {
  final String host;
  final int porta;
  final String usuario;
  final String senha;
  final String banco;

  /// Usa conexão criptografada (SSL/TLS). Deixe `true` em banco na nuvem.
  final bool ssl;

  /// Aceita certificado SSL autoassinado (igual ao `rejectUnauthorized: false`
  /// do db.js do web). Só ligue se o banco usar certificado próprio.
  final bool aceitarCertificadoInvalido;

  /// Máximo de conexões abertas ao mesmo tempo pelo app.
  final int maxConexoes;

  /// Tempo máximo de espera por uma consulta antes de desistir.
  final Duration tempoLimite;

  const BancoConfig({
    required this.host,
    required this.usuario,
    required this.senha,
    required this.banco,
    this.porta = 3306,
    this.ssl = true,
    this.aceitarCertificadoInvalido = false,
    this.maxConexoes = 3,
    this.tempoLimite = const Duration(seconds: 15),
  });

  /// Lê a configuração passada no `flutter run`/`flutter build`.
  factory BancoConfig.doAmbiente() {
    return const BancoConfig(
      host: String.fromEnvironment('DB_HOST'),
      porta: int.fromEnvironment('DB_PORT', defaultValue: 3306),
      usuario: String.fromEnvironment('DB_USER'),
      senha: String.fromEnvironment('DB_PASSWORD'),
      banco: String.fromEnvironment('DB_NAME', defaultValue: 'estacionamentoSenac'),
      ssl: bool.fromEnvironment('DB_SSL', defaultValue: true),
      aceitarCertificadoInvalido: bool.fromEnvironment('DB_SSL_ACEITAR_CERT_INVALIDO'),
    );
  }

  /// Lista o que está faltando para conseguir conectar (vazia = tudo certo).
  List<String> get camposFaltando => [
        if (host.trim().isEmpty) 'DB_HOST',
        if (usuario.trim().isEmpty) 'DB_USER',
        if (banco.trim().isEmpty) 'DB_NAME',
      ];

  bool get valida => camposFaltando.isEmpty;

  @override
  String toString() =>
      'BancoConfig($usuario@$host:$porta/$banco, ssl: $ssl)'; // nunca mostra a senha
}
