import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';
import 'package:projeto_estacionamento/core/utils/conversao.dart';

/// Coluna `vaga_especial` ENUM('deficiente','idoso'); NULL = vaga comum.
enum TipoVaga {
  padrao(null, 'PADRÃO'),
  deficiente('deficiente', 'DEFICIENTE'),
  idoso('idoso', 'IDOSO');

  /// Valor gravado no banco.
  final String? valorBanco;

  /// Texto pronto para a tela (igual ao web).
  final String rotulo;

  const TipoVaga(this.valorBanco, this.rotulo);

  static TipoVaga doBanco(String? valor) => switch (valor?.trim().toLowerCase()) {
        'deficiente' => TipoVaga.deficiente,
        'idoso' => TipoVaga.idoso,
        _ => TipoVaga.padrao,
      };

  bool get especial => this != TipoVaga.padrao;
}

/// Uma vaga do estacionamento (tbl_vaga) — cada "bolinha" da tela.
class Vaga {
  final int id;
  final String codigo;
  final TipoVaga tipo;
  final bool ocupada;

  const Vaga({
    required this.id,
    required this.codigo,
    this.tipo = TipoVaga.padrao,
    this.ocupada = false,
  });

  bool get livre => !ocupada;

  /// "LIVRE" / "OCUPADA", igual ao web.
  String get statusTexto => ocupada ? 'OCUPADA' : 'LIVRE';

  factory Vaga.daLinha(LinhaSql linha) {
    return Vaga(
      id: lerInt(linha['id']),
      codigo: lerTextoOuNulo(linha['codigo_vaga']) ?? '',
      tipo: TipoVaga.doBanco(lerTextoOuNulo(linha['vaga_especial'])),
      ocupada: lerBool(linha['ocupada']),
    );
  }

  Vaga copiarCom({String? codigo, TipoVaga? tipo, bool? ocupada}) => Vaga(
        id: id,
        codigo: codigo ?? this.codigo,
        tipo: tipo ?? this.tipo,
        ocupada: ocupada ?? this.ocupada,
      );

  Map<String, Object?> paraJson() => {
        'id': id,
        'codigo_vaga': codigo,
        'vaga_especial': tipo.valorBanco,
        'ocupada': ocupada,
      };

  @override
  bool operator ==(Object other) =>
      other is Vaga &&
      other.id == id &&
      other.codigo == codigo &&
      other.tipo == tipo &&
      other.ocupada == ocupada;

  @override
  int get hashCode => Object.hash(id, codigo, tipo, ocupada);

  @override
  String toString() => 'Vaga($id, $codigo, ${tipo.name}, $statusTexto)';
}
