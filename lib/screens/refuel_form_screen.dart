import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db.dart';
import '../models.dart';

class RefuelFormScreen extends StatefulWidget {
  final Vehicle vehicle;
  final List<Refuel> existing;
  const RefuelFormScreen({super.key, required this.vehicle, required this.existing});
  @override
  State<RefuelFormScreen> createState() => _RefuelFormScreenState();
}

class _RefuelFormScreenState extends State<RefuelFormScreen> {
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _km = TextEditingController();
  final _liters = TextEditingController();
  String _fuel = 'gasolina';
  DateTime _date = DateTime.now();
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  double? get _total {
    final p = _num(_price.text), l = _num(_liters.text);
    return (p != null && l != null) ? p * l : null;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (t == null) return;
    setState(() => _date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  String? _positive(String? v) {
    final n = _num(v ?? '');
    return (n == null || n <= 0) ? 'Valor inválido' : null;
  }

  /// A km precisa ser coerente com os abastecimentos vizinhos (por data).
  String? _kmValidator(String? v) {
    final km = _num(v ?? '');
    if (km == null || km < 0) return 'Quilometragem inválida';
    final before = widget.existing.where((r) => r.date.isBefore(_date)).toList();
    final after = widget.existing.where((r) => r.date.isAfter(_date)).toList();
    if (before.isNotEmpty && km <= before.last.km) return 'Deve ser maior que ${before.last.km.toStringAsFixed(0)} km';
    if (after.isNotEmpty && km >= after.first.km) return 'Deve ser menor que ${after.first.km.toStringAsFixed(0)} km';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await AppDb.insertRefuel(Refuel(
      vehicleId: widget.vehicle.id!,
      fuel: _fuel,
      price: _num(_price.text)!,
      km: _num(_km.text)!,
      liters: _num(_liters.text)!,
      date: _date,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    const dec = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Novo abastecimento')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<String>(
            value: _fuel,
            decoration: const InputDecoration(labelText: 'Combustível', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'etanol', child: Text('Etanol')),
              DropdownMenuItem(value: 'gasolina', child: Text('Gasolina')),
              DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
            ],
            onChanged: (v) => setState(() => _fuel = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _price, keyboardType: dec, validator: _positive,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Preço por litro (R\$)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _km, keyboardType: dec, validator: _kmValidator,
            decoration: const InputDecoration(labelText: 'Quilometragem (km)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _liters, keyboardType: dec, validator: _positive,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Litros abastecidos', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(4)),
            leading: const Icon(Icons.event),
            title: Text(DateFormat('dd/MM/yyyy HH:mm').format(_date)),
            subtitle: const Text('Data e horário'),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          Text('Total: ${_total == null ? '—' : _money.format(_total)}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Salvar abastecimento')),
        ]),
      ),
    );
  }
}
