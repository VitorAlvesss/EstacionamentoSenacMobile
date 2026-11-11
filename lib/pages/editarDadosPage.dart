import 'dart:io';
import 'package:flutter/material.dart';

class EditarDadosPage extends StatefulWidget {
  final String nome;
  final String email;

  const EditarDadosPage({super.key, required this.nome, required this.email});

  @override
  State<EditarDadosPage> createState() => _EditarDadosPage();
}

class _EditarDadosPage extends State<EditarDadosPage> {
  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              // nome
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: widget.nome,
              ),
            ),

            SizedBox(height: 25),

            TextField(
              // email
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: widget.email,
              ),
            ),

            SizedBox(height: 25),

            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Sua nova senha',
              ),
            ),

            SizedBox(height: 25),

            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Confirme sua nova senha',
              ),
            ),

            SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    icon: Icon(Icons.arrow_back),
                    label: const Text('Cancelar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.edit),
                    label: const Text('Salvar alterações'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Editar dados do usuário'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
    );
  }
}
