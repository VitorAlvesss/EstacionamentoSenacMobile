import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual das telas de login e cadastro (o mesmo da tela de cadastro original):
/// cabeçalho laranja com curva + cartão branco com os campos.

abstract final class CoresApp {
  static const laranja = Color(0xFFFF6900);
  static const laranjaEscuro = Color(0xFFE65100);
  static const fundo = Color(0xFFFFF8F5);
  static const icone = Color(0xFF424242);
  static const borda = Color(0xFFBBBBBB);
}

/// Cabeçalho laranja com a curva embaixo. [child] fica dentro da SafeArea.
class CabecalhoCurvo extends StatelessWidget {
  const CabecalhoCurvo({super.key, required this.child, this.altura = 245});

  final Widget child;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CabecalhoClipper(),
      child: Container(
        height: altura,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [CoresApp.laranja, CoresApp.laranjaEscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Cartão branco arredondado onde ficam os campos.
class CartaoFormulario extends StatelessWidget {
  const CartaoFormulario({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 28, 14, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Campo com ícone à esquerda, título com * vermelho e borda arredondada.
///
/// Para senha, passe [senha] = true e controle o "olhinho" com
/// [ocultarSenha] + [aoAlternarSenha].
class CampoFormulario extends StatelessWidget {
  const CampoFormulario({
    super.key,
    required this.titulo,
    required this.dica,
    required this.icone,
    required this.controller,
    this.teclado = TextInputType.text,
    this.senha = false,
    this.ocultarSenha = true,
    this.aoAlternarSenha,
    this.validar,
    this.formatadores,
    this.acaoTeclado,
    this.aoEnviar,
    this.dicasPreenchimento,
    this.habilitado = true,
  });

  final String titulo;
  final String dica;
  final IconData icone;
  final TextEditingController controller;
  final TextInputType teclado;
  final bool senha;
  final bool ocultarSenha;
  final VoidCallback? aoAlternarSenha;
  final String? Function(String?)? validar;
  final List<TextInputFormatter>? formatadores;
  final TextInputAction? acaoTeclado;
  final ValueChanged<String>? aoEnviar;
  final Iterable<String>? dicasPreenchimento;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 27),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 65,
            child: Icon(icone, size: 35, color: CoresApp.icone),
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
                      TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: controller,
                  enabled: habilitado,
                  keyboardType: teclado,
                  obscureText: senha && ocultarSenha,
                  enableSuggestions: !senha,
                  autocorrect: !senha,
                  inputFormatters: formatadores,
                  textInputAction: acaoTeclado,
                  onFieldSubmitted: aoEnviar,
                  autofillHints: dicasPreenchimento,
                  validator: validar ??
                      (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Preencha este campo';
                        }
                        return null;
                      },
                  decoration: InputDecoration(
                    hintText: dica,
                    hintStyle: const TextStyle(color: Colors.black54, fontSize: 17),
                    errorMaxLines: 2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
                    suffixIcon: senha
                        ? IconButton(
                            onPressed: aoAlternarSenha,
                            tooltip: ocultarSenha ? 'Mostrar senha' : 'Esconder senha',
                            icon: Icon(ocultarSenha ? Icons.visibility_off : Icons.visibility),
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: const BorderSide(color: CoresApp.borda),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: const BorderSide(color: CoresApp.laranja, width: 2),
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
}

/// Botão laranja grande; mostra um "carregando" e fica travado enquanto
/// [carregando] for true (evita cadastrar/entrar duas vezes).
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.texto,
    required this.aoPressionar,
    this.carregando = false,
  });

  final String texto;
  final VoidCallback aoPressionar;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        onPressed: carregando ? null : aoPressionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: CoresApp.laranja,
          foregroundColor: Colors.white,
          disabledBackgroundColor: CoresApp.laranja.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: carregando
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : Text(texto, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Mostra uma mensagem embaixo da tela (verde = sucesso, vermelho = erro).
void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
}

/// Curva do cabeçalho.
class CabecalhoClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

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
