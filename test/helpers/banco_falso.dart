import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';

/// Banco de mentira para testes: guarda os comandos recebidos e responde
/// com o que a função [responder] devolver.
class BancoFalso implements ExecutorSql {
  BancoFalso({this.aoConsultar, this.aoExecutar});

  List<LinhaSql> Function(String sql, Map<String, Object?> parametros)? aoConsultar;
  ResultadoExecucao Function(String sql, Map<String, Object?> parametros)? aoExecutar;

  final List<(String, Map<String, Object?>)> comandos = [];

  @override
  Future<List<LinhaSql>> consultar(String sql, [Map<String, Object?> parametros = const {}]) async {
    comandos.add((sql, parametros));
    return aoConsultar?.call(sql, parametros) ?? [];
  }

  @override
  Future<ResultadoExecucao> executar(String sql, [Map<String, Object?> parametros = const {}]) async {
    comandos.add((sql, parametros));
    return aoExecutar?.call(sql, parametros) ?? const ResultadoExecucao(linhasAfetadas: 0);
  }
}
