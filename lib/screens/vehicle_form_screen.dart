import 'package:flutter/material.dart';
import '../api.dart';
import '../db.dart';
import '../models.dart';

class VehicleFormScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const VehicleFormScreen({super.key, required this.onSaved});
  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _form = GlobalKey<FormState>();
  final _year = TextEditingController();
  final _engine = TextEditingController();
  List<Brand> _brands = [];
  List<String> _models = [];
  Brand? _brand;
  String? _model;
  bool _loadingBrands = true, _loadingModels = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() { _loadingBrands = true; _error = null; });
    try {
      final b = await BrasilApi.brands();
      setState(() => _brands = b);
    } catch (e) {
      setState(() => _error = 'Falha ao carregar marcas. Verifique a internet.');
    } finally {
      setState(() => _loadingBrands = false);
    }
  }

  Future<void> _loadModels(Brand b) async {
    setState(() { _loadingModels = true; _models = []; _model = null; _error = null; });
    try {
      final m = await BrasilApi.models(b.code);
      setState(() => _models = m);
    } catch (e) {
      setState(() => _error = 'Falha ao carregar modelos.');
    } finally {
      setState(() => _loadingModels = false);
    }
  }

Future<void> _save() async {
  if (!_form.currentState!.validate()) return;
  try {
    await AppDb.insertVehicle(Vehicle(
      brand: _brand!.name,
      model: _model!,
      year: int.parse(_year.text.trim()),
      engine: double.parse(_engine.text.trim().replaceAll(',', '.')),
    ));
    widget.onSaved();
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
  }
}

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cadastrar veículo')),
        body: _loadingBrands
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _form,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (_error != null)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        title: Text(_error!),
                        trailing: TextButton(onPressed: _loadBrands, child: const Text('Tentar de novo')),
                      ),
                    ),
                  DropdownButtonFormField<Brand>(
                    value: _brand,
                    isExpanded: true,
                    menuMaxHeight: 400,
                    decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
                    items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                    onChanged: (b) {
                      setState(() => _brand = b);
                      if (b != null) _loadModels(b);
                    },
                    validator: (v) => v == null ? 'Selecione a marca' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _model,
                    isExpanded: true,
                    menuMaxHeight: 400,
                    decoration: InputDecoration(
                      labelText: _loadingModels ? 'Carregando modelos...' : 'Modelo',
                      border: const OutlineInputBorder(),
                    ),
                    items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (m) => setState(() => _model = m),
                    validator: (v) => v == null ? 'Selecione o modelo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ano', border: OutlineInputBorder()),
                    validator: (v) {
                      final y = int.tryParse(v?.trim() ?? '');
                      if (y == null || y < 1950 || y > DateTime.now().year + 1) return 'Ano inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _engine,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cilindrada (L, ex.: 1.0)', border: OutlineInputBorder()),
                    validator: (v) {
                      final e = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                      if (e == null || e <= 0 || e > 10) return 'Cilindrada inválida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _save, child: const Text('Salvar veículo')),
                ]),
              ),
      );
}
