import 'package:flutter/material.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:projeto_estacionamento/pagina/cadastroVeiculo.dart';
import 'package:projeto_estacionamento/pagina/cadastroUsuario.dart';
class LoginUsuario extends StatefulWidget {
  final VoidCallback? aoCadastrar;

  const LoginUsuario({super.key, this.aoCadastrar});

  @override
  State<LoginUsuario> createState() => _LoginUsuarioState();
}

class _LoginUsuarioState extends State<LoginUsuario> {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  final Color laranja = const Color(0xFFFF6900);
  final Color fundo = const Color(0xFFFFF8F5);

  bool ocultarSenha = true;


  Future<void> entrarUsuario() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    MySQLConnection? conn;

    try {
      conn = await MySQLConnection.createConnection(
        host: "estacionamento-senac-senacsp-e198.g.aivencloud.com",
        port: 20494,
        userName: "avnadmin",
        password: "",
        databaseName: "estacionamentoSenac",
      );

      await conn.connect();

      final resultado = await conn.execute(
        '''
      SELECT id, senha
      FROM tbl_usuario
      WHERE email = :email
      ''',
        {
          'email': emailController.text.trim(),
        },
      );

      if (resultado.rows.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail ou senha incorretos!'),
          ),
        );
        return;
      }

      final usuario = resultado.rows.first.assoc();

      final idUsuario = int.parse(usuario['id'].toString());
      final senhaHash = usuario['senha'].toString();

      final senhaCorreta = BCrypt.checkpw(
        senhaController.text,
        senhaHash,
      );

      if (!senhaCorreta) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail ou senha incorretos!'),
          ),
        );
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => telaCadastro(
            idUsuario: idUsuario,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer login: $e'),
        ),
      );
    } finally {
      await conn?.close();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();

    super.dispose();
  }

  Widget campoTexto({
    required String titulo,
    required String dica,
    required IconData icone,
    required TextEditingController controller,
    TextInputType teclado = TextInputType.text,
    bool senha = false,
    String? Function(String?)? validar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 27),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 65,
            child: Icon(icone, size: 35, color: const Color(0xFF424242)),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: titulo,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 9),

                TextFormField(
                  controller: controller,
                  keyboardType: teclado,
                  obscureText: senha && ocultarSenha,

                  validator:
                      validar ??
                      (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Preencha este campo';
                        }
                        return null;
                      },

                  decoration: InputDecoration(
                    hintText: dica,

                    hintStyle: const TextStyle(
                      color: Colors.black54,
                      fontSize: 17,
                    ),

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 19,
                    ),

                    suffixIcon: senha
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                ocultarSenha = !ocultarSenha;
                              });
                            },
                            icon: Icon(
                              ocultarSenha
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          )
                        : null,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: const BorderSide(color: Color(0xFFBBBBBB)),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide(color: laranja, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      body: Stack(
        children: [
          ClipPath(
            clipper: CabecalhoClipper(),

            child: Container(
              height: 245,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [laranja, const Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),

              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),

                  child: Row(
                    children: [
                      const SizedBox(width: 8),

                      const Expanded(
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 205,
                left: 16,
                right: 16,
                bottom: 30,
              ),

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.fromLTRB(14, 28, 14, 30),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Form(
                  key: formKey,

                  child: Column(
                    children: [
                      campoTexto(
                        titulo: 'E-mail',
                        dica: 'Informe seu e-mail',
                        icone: Icons.email_outlined,
                        controller: emailController,
                        teclado: TextInputType.emailAddress,

                        validar: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo obrigatório';
                          }

                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value.trim())) {
                            return 'Informe um e-mail válido';
                          }

                          return null;
                        },
                      ),

                      campoTexto(
                        titulo: 'Senha',
                        dica: 'Informe sua senha',
                        icone: Icons.lock_outline,
                        controller: senhaController,
                        senha: true,

                        validar: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }

                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 65,

                        child: ElevatedButton(
                          onPressed: entrarUsuario,

                          child: const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: laranja,
                            foregroundColor: Colors.white,
                            elevation: 4,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Ainda não possui uma conta?',
                        style: TextStyle(fontSize: 16),
                      ),

                     const SizedBox(height: 30),

                     ElevatedButton(
                       onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroUsuario()));

                      },

                        child: Text(
                          'Cadastre-se',
                          style: TextStyle(
                            color: laranja,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                     ),
                    ],
                  ),

                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CabecalhoClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height - 15);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 65,
      size.width * 0.55,
      size.height - 25,
    );

    path.quadraticBezierTo(
      size.width * 0.82,
      size.height + 5,
      size.width,
      size.height - 35,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
