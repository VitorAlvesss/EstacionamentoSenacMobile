import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/cadastro_usuario.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AppEstacionamento());
}

class AppEstacionamento extends StatelessWidget{
  const AppEstacionamento({super.key});

  @override
  Widget build(BuildContext context){
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

      home: const CadastroUsuario(),
    );
  }
}
