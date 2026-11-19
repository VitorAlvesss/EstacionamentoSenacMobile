import 'package:flutter/material.dart';

void main() => runApp(const AppEstacionamento());

String brl(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

// 1h = 10 | 2h = 18 | 3h+ = 25 + 5 por hora adicional
double calcTotal(int h) => h == 1 ? 10 : (h == 2 ? 18 : 25.0 + 5 * (h - 3));

class AppEstacionamento extends StatelessWidget {
  const AppEstacionamento({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Estacionamento',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0D47A1),
          scaffoldBackgroundColor: const Color(0xFFF3F5F9),
          appBarTheme: const AppBarTheme(centerTitle: true),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        home: const TelaCalculadora(),
      );
}

//Componentes reutilizáveis

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const SectionCard(
      {super.key, required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: c.primary),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }
}

class BottomAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const BottomAction({super.key, required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(onPressed: onPressed, child: Text(label)),
        ),
      );
}

//A primeira tela

class TelaCalculadora extends StatefulWidget {
  const TelaCalculadora({super.key});
  @override
  State<TelaCalculadora> createState() => _TelaCalculadoraState();
}

class _TelaCalculadoraState extends State<TelaCalculadora> {
  int hours = 1;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final total = calcTotal(hours);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estacionamento - Cálculo de Tarifas'),
        leading: const Icon(Icons.local_parking),
        actions: const [
          Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.attach_money))
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SectionCard(
          title: 'Tabela de Tarifas',
          icon: Icons.receipt_long,
          child: Column(children: const [
            _TariffRow('1 Hora', 'R\$ 10,00'),
            Divider(),
            _TariffRow('2 Horas', 'R\$ 18,00'),
            Divider(),
            _TariffRow('3+ Horas', 'R\$ 25,00 + R\$ 5/h adicional'),
          ]),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Tempo de Permanência',
          icon: Icons.schedule,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.access_time_filled, color: c.primary, size: 32),
              const SizedBox(width: 8),
              Text('$hours ${hours == 1 ? 'hora' : 'horas'}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            Slider(
              value: hours.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '$hours h',
              onChanged: (v) => setState(() => hours = v.round()),
            ),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('1h'),
              Text('12h'),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Card(
          color: c.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text('Total a pagar',
                  style: TextStyle(color: c.onPrimaryContainer)),
              const SizedBox(height: 4),
              Text(brl(total),
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: c.onPrimaryContainer)),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: BottomAction(
        label: 'Avançar para Pagamento',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PaymentScreen(total: total))),
      ),
    );
  }
}

class _TariffRow extends StatelessWidget {
  final String time, price;
  const _TariffRow(this.time, this.price);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(price, textAlign: TextAlign.end)),
        ]),
      );
}

// ---------- TELA 2 ----------

enum PayMethod { pix, credit, debit }

class PaymentScreen extends StatefulWidget {
  final double total;
  const PaymentScreen({super.key, required this.total});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PayMethod method = PayMethod.pix;

  static const _options = {
    PayMethod.pix: (Icons.qr_code_2, 'Pix', 'Aprovação instantânea'),
    PayMethod.credit: (Icons.credit_card, 'Cartão de Crédito', 'Pague na maquininha'),
    PayMethod.debit: (Icons.payment, 'Cartão de Débito', 'Débito em conta'),
  };

  void _pay() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 56),
          title: const Text('Pagamento confirmado!'),
          content: Text(
              'Pagamento de ${brl(widget.total)} do estacionamento realizado com sucesso.',
              textAlign: TextAlign.center),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.popUntil(context, (r) => r.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Efetuar Pagamento')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(
          color: c.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text('Valor a pagar',
                  style: TextStyle(color: c.onPrimaryContainer)),
              const SizedBox(height: 4),
              Text(brl(widget.total),
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: c.onPrimaryContainer)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Forma de Pagamento',
          icon: Icons.account_balance_wallet,
          child: Column(
            children: [
              for (final e in _options.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => setState(() => method = e.key),
                    selected: method == e.key,
                    selectedTileColor: c.primaryContainer.withOpacity(.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: method == e.key ? c.primary : Colors.black12,
                          width: method == e.key ? 2 : 1),
                    ),
                    leading: Icon(e.value.$1),
                    title: Text(e.value.$2,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(e.value.$3),
                    trailing: Icon(method == e.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                  ),
                ),
            ],
          ),
        ),
      ]),
      bottomNavigationBar:
          BottomAction(label: 'Efetuar Pagamento', onPressed: _pay),
    );
  }
}