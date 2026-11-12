class Usuario {
  final int? id;
  final String? nome;
  final String? email;
  final String? telefone;

  Usuario({this.id, this.nome, this.email, this.telefone});

  factory Usuario.fromMap(Map<String, String?> map) {
    return Usuario(
      id: map['id'] != null ? int.tryParse(map['id']!) : null,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    // dificilmente isso daqui vai ser usado (eu acho), mas tá aí né
    return {'nome': nome, 'email': email, 'telefone': telefone};
  }
}
