import 'dart:io';
import 'package:flutter/material.dart';

class EditarDadosPage extends StatefulWidget {
	final String nome;
	final String email;

	const EditarDadosPage ({
		super.key,
		required this.nome,
		required this.email,
		});

	@override
	State<EditarDadosPage> createState() => _EditarDadosPage();
}

class _EditarDadosPage extends State<EditarDadosPage> {
	@override
	Widget build(BuildContext ctx) {
		return Scaffold(
			appBar: appBar(
				title: const Text('Editar dados do usuário'),
				),
				backgroundColor: Colors.white,
				foregroundColor: Colors.black,
			),
			body: Padding(
				padding: const EdgeInsets.all(24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [
						TextField( // nome
							decoration: InputDecoration(
								border: OutlineInputBorder(),
								hintText: widget.nome,
								label: const Text(''),
								),
							),
						TextField( // email
							decoration: InputDecoration(
								border: OutlineInputBorder(),
								hintText: widget.email,
								label: const Text(''),
								),
							),
						TextField(
							decoration: InputDecoration(
								border: OutlineInputBorder,
								hintText: const Text('Sua nova senha'),
								label: const Text('Nova senha'),
								),
							),
						TextField(
							decoration: InputDecoration(
								border: OutlineInputBorder,
								hintText: const Text('Confirme sua nova senha'),
								label: const Text('Confirmar nova senha'),
								),
							),
						const SizedBox(
							width: double.infinity,
							height: 50,
							child: Row(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									ElevatedButton(
										onPressed: () {
											Navigator.pop(ctx);
											},
										style: ElevatedButton.styleFrom(
											backgroundColor: Colors.red,
											foregroundColor: Colors.white
											)
										label: const Text('Cancelar'),
										)
									ElevatedButton.icon(
										onPressed: () {},
										icon: const Icon(Icons.edit),
										style: ElevatedButton.styleFrom(
											backgroundColor: Colors.indigo,
											foregroundColor: Colors.white,
											)
										label: const Text('Salvar alterações'),
										),
									],
								),
							),
						],
					),
				);
	}
}