import 'package:projeto_estacionamento/core/conexao/banco_mysql.dart';
import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';
import 'package:projeto_estacionamento/features/vagas/models/resumo_vagas.dart';
import 'package:projeto_estacionamento/features/vagas/models/vaga.dart';

/// Consultas SQL da tbl_vaga (igual ao vagaRepository.js do web).
///
/// O mobile é só para usuário comum: aqui só tem leitura. Cadastrar vaga e
/// mudar ocupação continuam sendo coisa do web/sensores.
class VagaRepository {
  VagaRepository([ExecutorSql? banco]) : _banco = banco ?? BancoMySql.instancia;

  final ExecutorSql _banco;

  static const _colunas = 'id, codigo_vaga, vaga_especial, ocupada';

  /// Todas as vagas, ou só as livres/ocupadas se [ocupada] for informado.
  Future<List<Vaga>> listar({bool? ocupada}) async {
    final linhas = ocupada == null
        ? await _banco.consultar('SELECT $_colunas FROM tbl_vaga ORDER BY id')
        : await _banco.consultar(
            'SELECT $_colunas FROM tbl_vaga WHERE ocupada = :ocupada ORDER BY id',
            {'ocupada': ocupada},
          );
    return linhas.map(Vaga.daLinha).toList();
  }

  Future<Vaga?> buscarPorId(int id) async {
    final linhas = await _banco.consultar(
      'SELECT $_colunas FROM tbl_vaga WHERE id = :id',
      {'id': id},
    );
    return linhas.isEmpty ? null : Vaga.daLinha(linhas.first);
  }

  /// Total / ocupadas / livres (rota /vagas/total do web).
  Future<ResumoVagas> resumo() async {
    final linhas = await _banco.consultar(
      'SELECT COUNT(*) AS total, '
      'COALESCE(SUM(CASE WHEN ocupada = 1 THEN 1 ELSE 0 END), 0) AS ocupadas, '
      'COALESCE(SUM(CASE WHEN ocupada = 0 THEN 1 ELSE 0 END), 0) AS livres '
      "FROM tbl_vaga WHERE codigo_vaga IS NOT NULL AND codigo_vaga <> ''",
    );
    return linhas.isEmpty
        ? const ResumoVagas(total: 0, ocupadas: 0, livres: 0)
        : ResumoVagas.daLinha(linhas.first);
  }
}
