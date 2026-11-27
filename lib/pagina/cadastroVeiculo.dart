import 'package:flutter/material.dart';
import 'package:projeto_estacionamento/pagina/CRUDVeiculo.dart';

class telaCadastro extends StatefulWidget {
  final int idUsuario;

  const telaCadastro({super.key, required this.idUsuario});

  @override
  State<telaCadastro> createState() => _tela_cadastro();
}

class _tela_cadastro extends State<telaCadastro> {
  final _ChaveValidar = GlobalKey<FormState>();

  String placa = "";
  final _placaController = TextEditingController();

  String marca = "";
  final _marcaController = TextEditingController();

  String modelo = "";
  final _modeloController = TextEditingController();

  String cor = "";
  final _corController = TextEditingController();

  int ano = 0;
  final _anoController = TextEditingController();
  String? _idEmEdicao;
  bool _carregando = false;
  String? _tipoVeiculo;

  // Lista local mantida com veiculos.add()
  List<Map<String, dynamic>> veiculos = [];

  void LimparCampos() {
    setState(() {
      _placaController.clear();
      _marcaController.clear();
      _modeloController.clear();
      _corController.clear();
      _anoController.clear();
      _idEmEdicao = null;
      _tipoVeiculo = null;
    });
  }

  Future<void> _salvarveiculo() async {
    if (_placaController.text.isEmpty ||
        _marcaController.text.isEmpty ||
        _modeloController.text.isEmpty ||
        _corController.text.isEmpty ||
        _anoController.text.isEmpty ||
        _tipoVeiculo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos!")),
      );
      return;
    }
    setState(() {
      _carregando = true;
    });
    try {
      final crud = CarroCrud();

      final resultado = await crud.cadastrarCarro(
        idUsuario: widget.idUsuario,
        placa: _placaController.text.trim(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        cor: _corController.text.trim(),
        tipoVeiculo: _tipoVeiculo!,
      );
      if (!mounted) return;

      if (resultado > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veiculo cadastrado com sucesso!")),
        );
        LimparCampos();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao cadastrar: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _corController.dispose();
    _anoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const proporcaoImagem = 2216 / 709;
    final largura = MediaQuery.of(context).size.width;
    final alturaHeader = (largura / proporcaoImagem).clamp(110.0, 220.0);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: alturaHeader,
        title: const Padding(
          padding: EdgeInsets.only(bottom: 35),
          child: Text(
            "Cadastro de veículo.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/imagens/header_carro.png"),
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
      ),

      body: Form(
        key: _ChaveValidar,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),

              const Text(
                "Placa",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _placaController,
                decoration: const InputDecoration(
                  hintText: "Insira a placa do veículo.",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.directions_car,
                    color: Colors.deepOrange,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Marca",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  hintText: "Marca do veículo.",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label, color: Colors.deepOrange),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Modelo",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  hintText: "Modelo do veículo.",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.directions_car,
                    color: Colors.deepOrange,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Cor",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _corController,
                decoration: const InputDecoration(
                  hintText: "Cor do veículo.",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.palette, color: Colors.deepOrange),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Ano",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _anoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Ano do veículo.",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    color: Colors.deepOrange,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _tipoVeiculo,
                decoration: const InputDecoration(
                  labelText: "Selecione o tipo do veículo",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category, color: Colors.deepOrange),
                ),
                items: const [
                  DropdownMenuItem(value: "carro", child: Text("Carro")),
                  DropdownMenuItem(value: "moto", child: Text("Moto")),
                ],
                onChanged: (valor) {
                  setState(() {
                    _tipoVeiculo = valor;
                  });
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: _carregando ? null : _salvarveiculo,
                label: Text(
                  _carregando
                      ? "Salvando..."
                      : _idEmEdicao == null
                      ? "Cadastrar"
                      : "Atualizar",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
