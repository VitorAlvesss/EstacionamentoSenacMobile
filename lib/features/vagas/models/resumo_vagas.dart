import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';
import 'package:projeto_estacionamento/core/utils/conversao.dart';

/// Contadores do topo da tela de vagas (rota /vagas/total do web).
class ResumoVagas {
  final int total;
  final int ocupadas;
  final int livres;

  const ResumoVagas({required this.total, required this.ocupadas, required this.livres});

  /// Taxa de ocupação de 0 a 100 (0 quando não há vagas).
  double get taxaOcupacao => total == 0 ? 0 : ocupadas * 100 / total;

  /// "75%" — pronto para a tela.
  String get taxaOcupacaoTexto => '${taxaOcupacao.round()}%';

  /// "3 de 4 vagas", igual ao web.
  String get ocupacaoTexto => '$ocupadas de $total vagas';

  bool get lotado => total > 0 && livres == 0;

  factory ResumoVagas.daLinha(LinhaSql linha) {
    return ResumoVagas(
      total: lerIntOuNulo(linha['total']) ?? 0,
      ocupadas: lerIntOuNulo(linha['ocupadas']) ?? 0,
      livres: lerIntOuNulo(linha['livres']) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ResumoVagas &&
      other.total == total &&
      other.ocupadas == ocupadas &&
      other.livres == livres;

  @override
  int get hashCode => Object.hash(total, ocupadas, livres);

  @override
  String toString() => 'ResumoVagas(total: $total, ocupadas: $ocupadas, livres: $livres)';
}
