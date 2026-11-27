import 'package:mysql_client_plus/mysql_client_plus.dart';
import 'package:bcrypt/bcrypt.dart';

class UsuarioCrud {
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

  // CREATE - Cadastrar usuário
  Future<int> cadastrarUsuario({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    // Transforma a senha em hash
    final senhaHash = BCrypt.hashpw(senha, BCrypt.gensalt());

    final conn = await conectar();

    try {
      final resultado = await conn.execute(
        '''
        INSERT INTO tbl_usuario
        (nome_usuario, email, numero_usuario, senha)
        VALUES (:nome, :email, :telefone, :senha)
        ''',
        {
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'senha': senhaHash,
        },
      );

      return resultado.lastInsertID .toInt();
    } finally {
      await conn.close();
    }
  }

  // READ - Listar todos os usuários
  Future<List<Map<String, dynamic>>> listarUsuarios() async {
    final conn = await conectar();

    try {
      final resultado = await conn.execute('''
        SELECT id, nome_usuario, email, numero_usuario
        FROM tbl_usuario
      ''');

      return resultado.rows.map((row) => row.assoc()).toList();
    } finally {
      await conn.close();
    }
  }

  // READ - Buscar usuário pelo ID
  Future<Map<String, dynamic>?> buscarUsuario(int id) async {
    final conn = await conectar();

    try {
      final resultado = await conn.execute(
        '''
        SELECT id, nome_usuario, email, numero_usuario
        FROM tbl_usuario
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

  // UPDATE - Atualizar usuário
  Future<int> atualizarUsuario({
    required int id,
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    // Gera um novo hash para a senha atualizada
    final senhaHash = BCrypt.hashpw(senha, BCrypt.gensalt());

    final conn = await conectar();

    try {
      final resultado = await conn.execute(
        '''
        UPDATE tbl_usuario
        SET
          nome_usuario = :nome,
          email = :email,
          numero_usuario = :telefone,
          senha = :senha
        WHERE id = :id
        ''',
        {
          'id': id,
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'senha': senhaHash,
        },
      );

      return resultado.affectedRows.toInt();
    } finally {
      await conn.close();
    }
  }

  // DELETE - Excluir usuário
  Future<int> excluirUsuario(int id) async {
    final conn = await conectar();

    try {
      final resultado = await conn.execute(
        '''
        DELETE FROM tbl_usuario
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
