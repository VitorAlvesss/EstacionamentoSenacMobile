// Conversores das colunas do MySQL para tipos do Dart.
//
// O mysql_client_plus devolve quase tudo como texto ('1', '5.00',
// '2026-11-12 14:30:00'). Estas funções aceitam texto OU o tipo já convertido,
// então funcionam tanto com o banco real quanto com dados de teste.

int lerInt(Object? valor) {
  final convertido = lerIntOuNulo(valor);
  if (convertido == null) {
    throw FormatException('Valor inteiro inválido: $valor');
  }
  return convertido;
}

int? lerIntOuNulo(Object? valor) {
  if (valor == null) return null;
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  if (valor is BigInt) return valor.toInt();
  return int.tryParse(valor.toString().trim());
}

double? lerDecimalOuNulo(Object? valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString().trim().replaceAll(',', '.'));
}

/// BOOLEAN no MySQL é TINYINT(1): chega como '0'/'1'.
bool lerBool(Object? valor) {
  if (valor == null) return false;
  if (valor is bool) return valor;
  if (valor is num) return valor != 0;
  final texto = valor.toString().trim().toLowerCase();
  return texto == '1' || texto == 'true';
}

String? lerTextoOuNulo(Object? valor) {
  if (valor == null) return null;
  final texto = valor.toString();
  return texto.isEmpty ? null : texto;
}

/// DATETIME do MySQL ('2026-11-12 14:30:00') em horário local.
DateTime? lerDataHoraOuNulo(Object? valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;
  return DateTime.tryParse(valor.toString().trim());
}
