import 'package:flutter/material.dart';

import 'package:projeto_estacionamento/features/features.dart';
import 'package:projeto_estacionamento/pages/componentes/visual_formulario.dart';
import 'package:projeto_estacionamento/pages/inicio_page.dart';
import 'package:projeto_estacionamento/pages/login_page.dart';

void main() {
  runApp(const AppEstacionamento());
}

class AppEstacionamento extends StatelessWidget {
  const AppEstacionamento({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'App Estacionamento',

      theme: ThemeData(
        primarySwatch: Colors.indigo,

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
      ),

      home: const TelaAbertura(),
    );
  }
}

/// Primeira tela: se o usuário já estava logado vai direto para o início,
/// senão vai para o login.
class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key});

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura> {
  late final Future<Usuario?> _sessao = _restaurarSessao();

  static Future<Usuario?> _restaurarSessao() async {
    try {
      return await UsuarioController.instancia.restaurarSessao();
    } catch (_) {
      return null; // qualquer problema (banco fora, sem config…): vai para o login
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Usuario?>(
      future: _sessao,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: CoresApp.fundo,
            body: Center(child: CircularProgressIndicator(color: CoresApp.laranja)),
          );
        }
        return snapshot.data != null ? const InicioPage() : const LoginPage();
      },
    );
  }
}
