import 'package:mysql_client_plus/mysql_client_plus.dart';

class CarroCrud {
  // Abre a conexão com o MySQL
  Future<MySQLConnection> conectar() async {
    final conn = await MySQLConnection.createConnection(
      host: "",
      port: 20494,
      userName: "",
      password: "",
      databaseName: "estacionamentoSenac",
    );

    await conn.connect();
    return conn;
  }

  // CREATE - Cadastrar veículo
  Future<int> cadastrarCarro({
    required int? idUsuario,
    required String placa,
    required String marca,
    required String modelo,
    required String cor,
    required String tipoVeiculo,
  }) async {
    final conn = await conectar();

    try {
      final resultado = await conn.execute(
        '''
      INSERT INTO tbl_carro
      (placa, marca, modelo, cor, tipo_veiculo, id_usuario)
      VALUES
      (:placa, :marca, :modelo, :cor, :tipoVeiculo, :idUsuario)
      ''',
        {
          'placa': placa,
          'marca': marca,
          'modelo': modelo,
          'cor': cor,
          'tipoVeiculo': tipoVeiculo,
          'idUsuario': idUsuario,
        },
      );

      return resultado.affectedRows.toInt();
    } finally {
      await conn.close();
    }
  }

  // READ - Listar veículos
  Future<List<Map<String, dynamic>>> listarCarros(int idusuario) async {
    final conn = await conectar();

    try {

      final resultado = await conn.execute('''
      SELECT id, placa, marca, modelo, cor, tipo_veiculo
      FROM tbl_carro
      WHERE id = : idusuario
      ''',
      {'id_usuario' : idusuario});

      return resultado.rows.map((row) => row.assoc()).toList();
    } finally {
      await conn.close();
    }
  }

  // READ - Buscar veículo pelo ID
  Future<Map<String, dynamic>?> buscarCarro(int id) async {
    final conn = await conectar();

    try {
      final resultado = await conn.execute(
        '''
        SELECT id, placa, marca, modelo, cor, tipo_veiculo
        FROM tbl_carro
        WHERE id = :id
        ''',
        {'id': id},
      );

      if (resultado.rows.isEmpty) {
        return null;
      }

      return resultado.rows.first.assoc();
    } finally {
      await conn.close();
    }
  }

  // UPDATE - Atualizar veículo
  Future<int> atualizarCarro({
    required int id,
    required String placa,
    required String marca,
    required String modelo,
    required String cor,
    required String tipoVeiculo,
  }) async {
    final conn = await conectar();

    try {
      final resultado = await conn.execute(
        '''
        UPDATE tbl_carro
        SET
          placa = :placa,
          marca = :marca,
          modelo = :modelo,
          cor = :cor,
          tipo_veiculo = :tipoVeiculo
        WHERE id = :id
        ''',
        {
          'id': id,
          'placa': placa,
          'marca': marca,
          'modelo': modelo,
          'cor': cor,
          'tipoVeiculo': tipoVeiculo,
        },
      );

      return resultado.affectedRows.toInt();
    } finally {
      await conn.close();
    }
  }

  // DELETE - Excluir veículo
  Future<int> excluirCarro(int id) async {
    final conn = await conectar();

    try {
      final resultado = await conn.execute(
        '''
        DELETE FROM tbl_carro
        WHERE id = :id
        ''',
        {'id': id},
      );

      return resultado.affectedRows.toInt();
    } finally {
      await conn.close();
    }
  }
}
