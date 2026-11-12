class Usuario {
	final int? id;
	final String nome;
	final String email;

	Usuario({
		this.id,
		this.nome,
		this.email,
	});

	factory Usuario.fromMap(Map<String, String?> map) {
		return Usuario(
			id: map['id'] != null ? int.tryParse(map['id']!) : null,
			nome: map['nome'] ?? '',
			email: map['email'] ?? '',
		);
	}

	Map<String, dynamic> toMap() { // dificilmente isso daqui vai ser usado (eu acho), mas tá aí né
		return {
			'nome': nome,
			'email': email,
		}
	}
}