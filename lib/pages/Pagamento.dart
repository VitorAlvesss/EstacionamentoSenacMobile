import 'package:flutter/material.dart';
import 'package:projeto_estacionamento/core/ui.dart';
//import 'package:projeto_estacionamento/data/pagamento_repository.dart';
import 'package:projeto_estacionamento/features/pagamentos/repositories/pagamento_repository.dart';


enum PaymentMethod { pix, credit, debit }

extension PaymentMethodInfo on PaymentMethod {
  String get title => switch (this) {
        PaymentMethod.pix => 'Pix',
        PaymentMethod.credit => 'Cartão de Crédito',
        PaymentMethod.debit => 'Cartão de Débito',
      };

  String get subtitle => switch (this) {
        PaymentMethod.pix => 'Aprovação instantânea',
        PaymentMethod.credit => 'Visa, Mastercard, Elo e outras',
        PaymentMethod.debit => 'Débito direto na conta',
      };

  IconData get icon => switch (this) {
        PaymentMethod.pix => Icons.qr_code_2_rounded,
        PaymentMethod.credit => Icons.credit_card_rounded,
        PaymentMethod.debit => Icons.account_balance_wallet_rounded,
      };
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.totalValue,
    required this.hours,
  });

  final double totalValue;
  final int hours;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.pix;

  bool _saving = false;

  Future<void> _pay() async {
    setState(() => _saving = true);
    final ok = await PagamentoRepository().salvarPagamento({
      'valor': widget.totalValue,
      'metodo': _method.title,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível registrar o pagamento. Tente novamente.'),
      ));
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 64,
        ),
        title: const Text(
          'Pagamento confirmado!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Seu estacionamento de ${formatHours(widget.hours)} foi pago com '
          '${_method.title}.\n\nValor: ${formatBRL(widget.totalValue)}',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(180, 50)),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Voltar ao início'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    // Retorna à tela inicial (Tela 1).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Efetuar Pagamento'),
        // O botão de voltar é adicionado automaticamente pelo Navigator.
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AmountSummaryCard(
              total: widget.totalValue,
              hours: widget.hours,
            ),
            const SizedBox(height: 24),
            const SectionTitle('Forma de pagamento'),
            PaymentMethodsCard(
              selected: _method,
              onSelected: (m) => setState(() => _method = m),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton.icon(
          onPressed: _saving ? null : _pay,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_rounded),
          label: Text(_saving ? 'Registrando...' : 'Efetuar Pagamento'),
        ),
      ),
    );
  }
}

/// Seção 1 — valor total vindo da Tela 1.
class AmountSummaryCard extends StatelessWidget {
  const AmountSummaryCard({
    super.key,
    required this.total,
    required this.hours,
  });

  final double total;
  final int hours;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valor a pagar',
            style: TextStyle(color: Color(0xFFB9C7DE), fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            formatBRL(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFFB9C7DE),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Permanência de ${formatHours(hours)}',
                style: const TextStyle(color: Color(0xFFB9C7DE), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seção 2 — caixa com as opções de pagamento selecionáveis.
class PaymentMethodsCard extends StatelessWidget {
  const PaymentMethodsCard({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (final method in PaymentMethod.values)
            PaymentOptionTile(
              method: method,
              selected: method == selected,
              onTap: () => onSelected(method),
            ),
        ],
      ),
    );
  }
}

class PaymentOptionTile extends StatelessWidget {
  const PaymentOptionTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected ? AppColors.navySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.navy : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        method.icon,
                        color: selected ? Colors.white : AppColors.navy,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? AppColors.navy : AppColors.textSecondary,
                    ),
                  ],
                ),
                // Detalhe simulado do Pix (apenas quando selecionado).
                if (method == PaymentMethod.pix && selected)
                  const _PixDetails(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PixDetails extends StatelessWidget {
  const _PixDetails();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.qr_code_2_rounded, size: 56, color: AppColors.navy),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chave Pix (simulada)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'estacionamento@pix.com.br',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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