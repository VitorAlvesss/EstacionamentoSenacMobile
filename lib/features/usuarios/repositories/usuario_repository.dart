import 'package:projeto_estacionamento/core/conexao/banco_mysql.dart';
import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';
import 'package:projeto_estacionamento/core/utils/conversao.dart';
import 'package:projeto_estacionamento/features/usuarios/models/usuario.dart';

/// Usuário + hash da senha. Só existe aqui dentro, para o login comparar.
typedef UsuarioComSenha = ({Usuario usuario, String senhaHash});

/// Todas as consultas SQL da tbl_usuario (igual ao usuarioRepository.js do web).
class UsuarioRepository {
  UsuarioRepository([ExecutorSql? banco]) : _banco = banco ?? BancoMySql.instancia;

  final ExecutorSql _banco;

  static const _colunas = 'id, nome_usuario, email, numero_usuario, cargo, ativo';

  /// Login aceita e-mail OU telefone (só dígitos), como no web.
  Future<UsuarioComSenha?> buscarPorLogin(String login) async {
    final linhas = await _banco.consultar(
      'SELECT $_colunas, senha FROM tbl_usuario '
      'WHERE email = :login OR numero_usuario = :login LIMIT 1',
      {'login': login},
    );
    if (linhas.isEmpty) return null;
    return (
      usuario: Usuario.daLinha(linhas.first),
      senhaHash: lerTextoOuNulo(linhas.first['senha']) ?? '',
    );
  }

  Future<Usuario?> buscarPorId(int id) async {
    final linhas = await _banco.consultar(
      'SELECT $_colunas FROM tbl_usuario WHERE id = :id',
      {'id': id},
    );
    return linhas.isEmpty ? null : Usuario.daLinha(linhas.first);
  }
}
