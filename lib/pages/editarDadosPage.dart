import 'dart:io';
import 'package:flutter/material.dart';
import '../features/repositories/usuario_repository.dart';

class EditarDadosPage extends StatefulWidget {
  final int id;
  final String nome;
  final String email;

  const EditarDadosPage({super.key, required this.id, required this.nome, required this.email});

  @override
  State<EditarDadosPage> createState() => _EditarDadosPage();
}

class _EditarDadosPage extends State<EditarDadosPage> {
  
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  final AppDatabase appDB = AppDatabase();
  final UsuarioRepository repo = UsuarioRepository();

  @override
  void initState() {
  	super.initState();
  	nomeController.text = widget.nome;
  	emailController.text = widget.email;
  }


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
                controller: nomeController,
              ),
            ),

            SizedBox(height: 25),

            TextField(
              // email
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                controller: emailController,
              ),
            ),

            SizedBox(height: 25),

            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Sua nova senha',
                controller: senhaController,
              ),
            ),

            SizedBox(height: 25),

            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Confirme sua nova senha',
                controller: confirmarSenhaController,
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
                    onPressed: () async {
                    	try {
                    		final campoNome = nomeController.text.isEmpty ? null : nomeController.text.trim();
                    		final campoEmail = emailController.text.isEmpty ? null : emailController.text.trim();
                    		final campoSenha = senhaController.text.isEmpty ? null : senhaController.text.trim();

                    		if (senhaController.text != confirmarSenhaController.text) {
                    			if (!mounted) return;

								ScaffoldMessenger.of(
	                    			ctx, 
	                    		).showSnackBar(SnackBar(content: Text('As senhas precisam ser iguais')));
	                    		return;            			
                    		}
                    		int rows = await repo.updateUsuario(widget.id, campoNome, campoEmail, campoSenha);
                    		if (!mounted) return;

                    		ScaffoldMessenger.of(
                    			ctx, 
                    		).showSnackBar(SnackBar(content: Text('Dados atualizados!')));
                    	} catch (e) {
                    		if (!mounted) return;

                    		ScaffoldMessenger.of(
                    			ctx, 
                    		).showSnackBar(SnackBar(content: Text('ERRO: $e')));
                    		}
                    }, 
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
