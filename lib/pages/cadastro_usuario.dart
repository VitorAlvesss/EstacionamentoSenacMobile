
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';

class CadastroUsuario extends StatefulWidget {

  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();

}

class _CadastroUsuarioState extends State<CadastroUsuario> {

  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();

  final Color laranja = const Color(0xFFFF6900);
  final Color fundo = const Color(0xFFFFF8F5);

  bool ocultarSenha = true;

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Método salvar cadastro
  void salvarUsuario() {

    if (formKey.currentState!.validate()) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      nomeController.clear();
      emailController.clear();
      telefoneController.clear();
      senhaController.clear();

    }

  }

  @override
  void dispose() {

    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();

    super.dispose();

  }

  // Campo de texto personalizado
  Widget campoTexto({
    required String titulo,
    required String dica,
    required IconData icone,
    required TextEditingController controller,
    TextInputType teclado = TextInputType.text,
    bool senha = false,
    String? Function(String?)? validar,
    List<TextInputFormatter>? formatadores,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 27),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          SizedBox(
            width: 65,
            child: Icon(
              icone,
              size: 35,
              color: const Color(0xFF424242),
            ),
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
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 9),

                TextFormField(
                  controller: controller,
                  keyboardType: teclado,
                  obscureText: senha && ocultarSenha,
                  inputFormatters: formatadores,

                  validator: validar ?? (value) {
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
                      borderSide: const BorderSide(
                        color: Color(0xFFBBBBBB),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide(
                        color: laranja,
                        width: 2,
                      ),
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

          // Cabeçalho
          ClipPath(
            clipper: CabecalhoClipper(),

            child: Container(
              height: 245,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    laranja,
                    const Color(0xFFE65100),
                  ],
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

                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Expanded(
                        child: Text(
                          'Cadastro',
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

          // Formulário
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

                padding: const EdgeInsets.fromLTRB(
                  14, 28, 14, 30,
                ),

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

                      // Nome
                      campoTexto(
                        titulo: 'Nome',
                        dica: 'Informe seu nome completo',
                        icone: Icons.person_outline,
                        controller: nomeController,
                      ),

                      // E-mail
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

                      // Telefone
                      campoTexto(
                        titulo: 'Telefone',
                        dica: '(00) 00000-0000',
                        icone: Icons.phone_outlined,
                        controller: telefoneController,
                        teclado: TextInputType.phone,
                        formatadores: [telefoneMask],
                      ),

                      // Senha
                      campoTexto(
                        titulo: 'Senha',
                        dica: 'Crie uma senha',
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

                      // Botão cadastrar
                      SizedBox(
                        width: double.infinity,
                        height: 65,

                        child: ElevatedButton.icon(

                          onPressed: salvarUsuario,


                          label: const Text(
                            'Cadastrar',
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

// Curva do cabeçalho
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
