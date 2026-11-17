import 'package:projeto_estacionamento/core/database/database.dart';
 
class PagamentoRepository {

  // Inserir pagamento no MySQL
  Future<bool> salvarPagamento(Map<String, dynamic> dados) async {
    try {
      final conn = await AppDatabase().connection;
 
      await conn.execute(
        'INSERT INTO pagamentos (valor, metodo, data_pagamento)'
        'VALUES (?, ?, NOW())',
        [dados['valor'], dados['metodo']],
      );
 
      return true;
    } catch (e) {
      return false;
    }
  }


  //select tabela pagamento (BANCO)
  Future<List<Map<String, Object>>> selectPagamento() async {
    try {
      final conn = await AppDatabase().connection;
      final resultado = await conn.execute(
        'SELECT * FROM pagamentos',
      );

      return resultado.rows
        .map((linha) => Map<String,Object>.from(linha.assoc()))
        .toList();
    } catch (e) {
      return [];
    }
  }
}