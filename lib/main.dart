import 'package:flutter/material.dart';

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

      //home: aqui precisaria ser a tela de login... talvez (ou coloca alguma outra, só pra teste)
    );
  }
}
