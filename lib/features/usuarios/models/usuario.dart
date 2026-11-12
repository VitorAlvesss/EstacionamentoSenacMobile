import 'package:projeto_estacionamento/core/conexao/executor_sql.dart';
import 'package:projeto_estacionamento/core/utils/conversao.dart';

enum Cargo {
  usuario,
  administrador;

  static Cargo deTexto(String? texto) =>
      texto == 'administrador' ? Cargo.administrador : Cargo.usuario;
}

/// Usuário logado. NUNCA carrega a senha — ela fica só dentro do repository.
class Usuario {
  final int id;
  final String nome;
  final String email;
  final String? telefone;
  final Cargo cargo;
  final bool ativo;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.cargo = Cargo.usuario,
    this.ativo = true,
  });

  bool get ehAdmin => cargo == Cargo.administrador;

  /// Primeiro nome, para "Olá, Maria!".
  String get primeiroNome => nome.trim().split(RegExp(r'\s+')).first;

  /// Monta a partir de uma linha da tbl_usuario.
  factory Usuario.daLinha(LinhaSql linha) {
    return Usuario(
      id: lerInt(linha['id']),
      nome: lerTextoOuNulo(linha['nome_usuario']) ?? '',
      email: lerTextoOuNulo(linha['email']) ?? '',
      telefone: lerTextoOuNulo(linha['numero_usuario']),
      cargo: Cargo.deTexto(lerTextoOuNulo(linha['cargo'])),
      ativo: linha.containsKey('ativo') ? lerBool(linha['ativo']) : true,
    );
  }

  /// Para salvar a sessão no celular.
  Map<String, Object?> paraJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'cargo': cargo.name,
        'ativo': ativo,
      };

  factory Usuario.deJson(Map<String, Object?> json) {
    return Usuario(
      id: lerInt(json['id']),
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String?,
      cargo: Cargo.deTexto(json['cargo'] as String?),
      ativo: lerBool(json['ativo'] ?? true),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Usuario &&
      other.id == id &&
      other.nome == nome &&
      other.email == email &&
      other.telefone == telefone &&
      other.cargo == cargo &&
      other.ativo == ativo;

  @override
  int get hashCode => Object.hash(id, nome, email, telefone, cargo, ativo);

  @override
  String toString() => 'Usuario($id, $email, ${cargo.name})';
}
