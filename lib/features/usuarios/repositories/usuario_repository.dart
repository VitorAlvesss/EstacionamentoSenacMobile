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

  /// Diz se o e-mail e/ou o telefone já pertencem a alguém (as duas colunas
  /// são UNIQUE na tbl_usuario). A comparação é feita pelo MySQL, então segue
  /// a mesma regra de maiúsculas/minúsculas que o UNIQUE usa.
  Future<DadosEmUso> verificarDadosEmUso({required String email, String? telefone}) async {
    final linhas = await _banco.consultar(
      'SELECT '
      'EXISTS(SELECT 1 FROM tbl_usuario WHERE email = :email) AS email_em_uso, '
      'EXISTS(SELECT 1 FROM tbl_usuario WHERE numero_usuario = :telefone) AS telefone_em_uso',
      {'email': email, 'telefone': telefone},
    );
    final linha = linhas.isEmpty ? const <String, Object?>{} : linhas.first;
    return (
      email: lerBool(linha['email_em_uso']),
      telefone: lerBool(linha['telefone_em_uso']),
    );
  }

  /// Grava um novo usuário e devolve o id gerado (igual ao `criar` do web).
  ///
  /// `cargo`, `ativo` e `data_cadastro` ficam com o DEFAULT da tabela
  /// ('usuario', TRUE, agora). O app NUNCA envia o cargo: assim o usuário do
  /// banco do app pode ter permissão de INSERT só nestas 4 colunas e ninguém
  /// consegue criar um administrador pelo celular (ver docs/BACKEND.md).
  Future<int> inserir({
    required String nome,
    required String email,
    String? telefone,
    required String senhaHash,
  }) async {
    final resultado = await _banco.executar(
      'INSERT INTO tbl_usuario (nome_usuario, email, numero_usuario, senha) '
      'VALUES (:nome, :email, :telefone, :senha)',
      {'nome': nome, 'email': email, 'telefone': telefone, 'senha': senhaHash},
    );
    return resultado.idInserido;
  }
}

/// Resultado de [UsuarioRepository.verificarDadosEmUso].
typedef DadosEmUso = ({bool email, bool telefone});
