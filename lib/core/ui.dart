import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF14325C);
  static const Color navySoft = Color(0xFFE3EAF5);
  static const Color background = Color(0xFFF3F5F9);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFDDE3EC);
  static const Color textPrimary = Color(0xFF1B2433);
  static const Color textSecondary = Color(0xFF5E6B80);
  static const Color success = Color(0xFF1E8E5A);
  static const Color shadow = Color(0x14000000);
}

String formatBRL(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String formatHours(int hours) => '$hours ${hours == 1 ? 'hora' : 'horas'}';

/// Caixa branca com borda arredondada usada em todas as seções.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Barra fixa na parte inferior com o botão principal da tela.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: child,
        ),
      ),
    );
  }
}