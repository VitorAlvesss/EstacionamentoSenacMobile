import 'package:flutter/material.dart';
import 'pagina/login_usuario.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Estacionamento Senac',

      initialRoute: '/',

      routes: {
        '/': (context) => LoginUsuario(
          aoCadastrar: () {
            Navigator.pushNamed(context, '/cadastro');
          },
        ),

        '/cadastro': (context) => const LoginUsuario(),
      },
    );
  }
}
