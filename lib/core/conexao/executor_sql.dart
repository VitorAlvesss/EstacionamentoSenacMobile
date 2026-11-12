/// Uma linha retornada pelo SELECT: nome da coluna -> valor.
typedef LinhaSql = Map<String, Object?>;

/// Resultado de INSERT / UPDATE / DELETE.
class ResultadoExecucao {
  final int linhasAfetadas;
  final int idInserido;

  const ResultadoExecucao({required this.linhasAfetadas, this.idInserido = 0});
}

/// Contrato que os repositories usam para falar com o banco.
///
/// O app usa a implementação real ([BancoMySql]); os testes usam uma falsa,
/// assim dá para testar tudo sem precisar de um MySQL ligado.
///
/// Parâmetros SEMPRE por nome (`:id`), nunca concatenando texto no SQL —
/// o driver escapa os valores e isso evita SQL Injection.
abstract interface class ExecutorSql {
  /// Para SELECT.
  Future<List<LinhaSql>> consultar(String sql, [Map<String, Object?> parametros]);

  /// Para INSERT / UPDATE / DELETE.
  Future<ResultadoExecucao> executar(String sql, [Map<String, Object?> parametros]);
}
