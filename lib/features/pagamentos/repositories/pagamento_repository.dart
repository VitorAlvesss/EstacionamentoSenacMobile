import 'package:projeto_estacionamento/core/database/database.dart';
import 'package:flutter/foundation.dart';

class PagamentoRepository {

  // Inserir pagamento no MySQL
  Future<bool> salvarPagamento(Map<String, dynamic> dados) async {
    try {
      final conn = await AppDatabase().connection;
 
      await conn.execute(
        'INSERT INTO pagamentos (valor, metodo, data_pagamento) '
        'VALUES (:valor, :metodo, NOW())',
        {'valor': dados['valor'], 'metodo': dados['metodo']},
      );
      
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar pagamento: $e');
      return false;
    }
  }
}