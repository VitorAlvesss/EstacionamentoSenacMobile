import 'package:projeto_estacionamento/core/database/database.dart';

class UsuarioRepository {
  final AppDatabase _appDB = AppDatabase();

  Future<int> updateUsuario(
    int id,
    String? nome,
    String? email,
    String? telefone,
    String? senha,
  ) async {
    List<String> dadosNovos = [];
    Map<String, dynamic> queryParams = {};

    queryParams['id'] = id;

    if (nome != null) {
      dadosNovos.add('nome = :nome');
      queryParams['nome'] = nome;
    }

    if (email != null) {
      dadosNovos.add('email = :email');
      queryParams['email'] = email;
    }

    if (telefone != null) {
      dadosNovos.add('telefone = :telefone');
      queryParams['telefone'] = telefone;
    }

    if (senha != null) {
      dadosNovos.add('senha = :senha');
      queryParams['senha'] = senha;
    }

    if (dadosNovos.isEmpty) {
      return 0;
    }

    String sql =
        "UPDATE tbl_usuarios SET ${dadosNovos.join(', ')} WHERE id = :id";

    final conn = await _appDB.connection;
    var res = await conn.execute(sql, queryParams);

    return res.affectedRows.toInt();
  }
}
