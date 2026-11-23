import 'package:flutter/material.dart';
import '../features/pagamentos/repositories/pagamento_repository.dart';

class PagamentoScreen extends StatefulWidget {
  const PagamentoScreen({super.key});

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  // Lista de ultimos pagamentos baseada nos dados web
  final _pagamentoRepository = PagamentoRepository();
  List<Map<String, Object>> pagamentos = [];

  @override
  void initState() {
    super.initState();
    _carregarPagamentos();
  }

  Future<void> _carregarPagamentos() async {
    final resultado = await _pagamentoRepository.selectPagamento();
    if (!mounted) return;
    setState(() => pagamentos = resultado);
  }

  String _formatarValor(Object? valor) {
    final numero = double.tryParse(valor?.toString() ?? '') ?? 0;
    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Fundo escuro padrão do projeto
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financeiro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Faturamento do estacionamento', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
drawer: Drawer(
  backgroundColor: const Color(0xFF0F172A),
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      const DrawerHeader(
        decoration: BoxDecoration(color: Color(0xFF0B0F19)),
        child: Center(
          child: Text(
            'Goiabinha & CIA',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.home, color: Colors.white70),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pop(context), // fecha o menu
      ),
      ListTile(
        leading: const Icon(Icons.app_registration, color: Colors.white70),
        title: const Text('Cadastro', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: const Icon(Icons.local_parking, color: Colors.white70),
        title: const Text('Vagas', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: const Icon(Icons.car_rental, color: Colors.white70),
        title: const Text('VeÃ­culos / UsuÃ¡rios', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: const Icon(Icons.login, color: Colors.white70),
        title: const Text('Entradas e SaÃ­das', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.blue),
        title: const Text(
          'Financeiro',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        onTap: () => Navigator.pop(context), 
      ),
      ListTile(
        leading: const Icon(Icons.devices, color: Colors.white70),
        title: const Text('Dispositivos IoT', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pop(context),
      ),
    ],
  ),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de Resumo Financeiro
            _buildResumoCard(
              title: 'Total de ganho hoje',
              value: 'R\$ 0,00',
              icon: Icons.payments,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildResumoCard(
              title: 'Total de ganho no mês',
              value: 'R\$ 0,00',
              icon: Icons.calendar_month,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildResumoCard(
              title: 'Pagamentos pendentes',
              value: ' 0',
              icon: Icons.pending_actions,
              color: Colors.red,
            ),
            const SizedBox(height: 24),

            // cabeçalho da sessão de historico
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ULTIMOS PAGAMENTOS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver todos', style: TextStyle(color: Colors.blueAccent)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de Pagamentos Otimizado para Mobile
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pagamentos.length,
              itemBuilder: (context, index) {
                final item = pagamentos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pagamento #${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            _formatarValor(item['valor']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 16),
                      _buildInfoRow('MÃ©todo:', item['metodo']?.toString() ?? 'NÃ£o informado'),
                      _buildInfoRow('Data:', item['data_pagamento']?.toString() ?? 'NÃ£o informada'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}


