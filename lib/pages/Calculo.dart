import 'package:flutter/material.dart';
import 'package:projeto_estacionamento/core/ui.dart';
import 'package:projeto_estacionamento/pages/Pagamento.dart';

class ParkingTariff {
  ParkingTariff._();

  static const int minHours = 1;
  static const int maxHours = 12;

  static const double oneHour = 10.0;
  static const double twoHours = 18.0;
  static const double threeHours = 25.0;
  static const double extraHour = 5.0; // a partir da 4ª hora

  /// 1h = R$ 10 | 2h = R$ 18 | 3h = R$ 25 + R$ 5 por hora adicional.
  static double calculate(int hours) {
    if (hours <= 1) return oneHour;
    if (hours == 2) return twoHours;
    return threeHours + (hours - 3) * extraHour;
  }

  /// Texto explicando como o valor foi composto.
  static String breakdown(int hours) {
    if (hours <= 1) return 'Tarifa de 1 hora';
    if (hours == 2) return 'Tarifa de 2 horas';
    final extra = hours - 3;
    if (extra == 0) return 'Tarifa de 3 horas';
    return '${formatBRL(threeHours)} (3 h) + $extra × ${formatBRL(extraHour)}';
  }

  /// Índice da linha da tabela que se aplica às horas escolhidas.
  static int tableRowFor(int hours) => hours <= 1 ? 0 : (hours == 2 ? 1 : 2);
}

class ParkCalculatorScreen extends StatefulWidget {
  const ParkCalculatorScreen({super.key});

  @override
  State<ParkCalculatorScreen> createState() => _ParkCalculatorScreenState();
}

class _ParkCalculatorScreenState extends State<ParkCalculatorScreen> {
  int _hours = 1;

  double get _total => ParkingTariff.calculate(_hours);

  void _setHours(int value) {
    setState(() {
      _hours = value.clamp(ParkingTariff.minHours, ParkingTariff.maxHours);
    });
  }

  void _goToPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PagamentoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_parking_rounded, size: 22),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Estacionamento - Cálculo de Tarifas',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.attach_money_rounded, size: 22),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Tabela de tarifas'),
            TariffTableCard(highlightedRow: ParkingTariff.tableRowFor(_hours)),
            const SizedBox(height: 24),
            const SectionTitle('Quanto tempo você vai ficar?'),
            HourSelectorCard(hours: _hours, onChanged: _setHours),
            const SizedBox(height: 24),
            const SectionTitle('Resumo'),
            TotalSummaryCard(hours: _hours, total: _total),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton.icon(
          onPressed: _goToPayment,
          icon: const Icon(Icons.arrow_forward_rounded),
          iconAlignment: IconAlignment.end,
          label: const Text('Avançar para Pagamento'),
        ),
      ),
    );
  }
}

/// Seção 1 — tabela de tarifas com destaque na faixa aplicada.
class TariffTableCard extends StatelessWidget {
  const TariffTableCard({super.key, required this.highlightedRow});

  final int highlightedRow;

  static const _rows = <({String label, String price})>[
    (label: '1 hora', price: 'R\$ 10,00'),
    (label: '2 horas', price: 'R\$ 18,00'),
    (label: '3+ horas', price: 'R\$ 25,00 + R\$ 5,00/h adicional'),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (var i = 0; i < _rows.length; i++)
            _TariffRow(
              label: _rows[i].label,
              price: _rows[i].price,
              highlighted: i == highlightedRow,
            ),
        ],
      ),
    );
  }
}

class _TariffRow extends StatelessWidget {
  const _TariffRow({
    required this.label,
    required this.price,
    required this.highlighted,
  });

  final String label;
  final String price;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.navySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 20,
            color: highlighted ? AppColors.navy : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                color: highlighted ? AppColors.navy : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seção 2 — seletor de horas (slider + botões −/+) com ícone de relógio.
class HourSelectorCard extends StatelessWidget {
  const HourSelectorCard({
    super.key,
    required this.hours,
    required this.onChanged,
  });

  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.navySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_filled_rounded,
              size: 34,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: hours > ParkingTariff.minHours
                    ? () => onChanged(hours - 1)
                    : null,
                icon: const Icon(Icons.remove_rounded),
                tooltip: 'Diminuir uma hora',
              ),
              SizedBox(
                width: 140,
                child: Text(
                  formatHours(hours),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: hours < ParkingTariff.maxHours
                    ? () => onChanged(hours + 1)
                    : null,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Aumentar uma hora',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: hours.toDouble(),
            min: ParkingTariff.minHours.toDouble(),
            max: ParkingTariff.maxHours.toDouble(),
            divisions: ParkingTariff.maxHours - ParkingTariff.minHours,
            label: formatHours(hours),
            onChanged: (v) => onChanged(v.round()),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 h', style: TextStyle(color: AppColors.textSecondary)),
              Text('12 h', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seção 3 — valor total calculado em tempo real.
class TotalSummaryCard extends StatelessWidget {
  const TotalSummaryCard({super.key, required this.hours, required this.total});

  final int hours;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Color(0xFFB9C7DE),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    formatBRL(total),
                    key: ValueKey<double>(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatHours(hours),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ParkingTariff.breakdown(hours),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFB9C7DE),
                    fontSize: 13,
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