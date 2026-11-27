import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db.dart';
import '../models.dart';
import 'refuel_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback onVehicleDeleted;
  const DashboardScreen({super.key, required this.vehicle, required this.onVehicleDeleted});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Refuel>> _future = AppDb.refuels(widget.vehicle.id!);
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _date = DateFormat('dd/MM/yyyy HH:mm');

  void _reload() {
  setState(() {
    _future = AppDb.refuels(widget.vehicle.id!);
  });
}

  Future<void> _addRefuel(List<Refuel> existing) async {
    final ok = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => RefuelFormScreen(vehicle: widget.vehicle, existing: existing)));
    if (ok == true) _reload();
  }

  Future<void> _deleteVehicle() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: const Text('Todos os abastecimentos deste veículo também serão removidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) {
      await AppDb.deleteVehicle(widget.vehicle.id!);
      widget.onVehicleDeleted();
    }
  }

  Future<void> _deleteRefuel(Refuel r) async {
    await AppDb.deleteRefuel(r.id!);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return FutureBuilder<List<Refuel>>(
      future: _future,
      builder: (context, snap) {
        final list = snap.data ?? [];
        final entries = buildEntries(list);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [IconButton(tooltip: 'Excluir veículo', icon: const Icon(Icons.delete_outline), onPressed: _deleteVehicle)],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: snap.hasData ? () => _addRefuel(list) : null,
            icon: const Icon(Icons.local_gas_station),
            label: const Text('Abastecer'),
          ),
          body: !snap.hasData
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text('${v.brand} ${v.model}'),
                      subtitle: Text('Ano ${v.year} • Motor ${v.engine.toStringAsFixed(1)} L'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Nenhum abastecimento ainda. Toque em "Abastecer".')),
                    )
                  else ...[
                    _chartCard('Valor de cada abastecimento (R\$)', _totalsChart(entries)),
                    if (entries.length < 2)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('O primeiro abastecimento é a referência inicial. Registre mais um para ver km/L e R\$/km.'),
                      )
                    else ...[
                      _chartCard('Consumo (km/L)', _lineChart(entries, (e) => e.kmL)),
                      _chartCard('Custo por km (R\$/km)', _lineChart(entries, (e) => e.costKm)),
                    ],
                    const SizedBox(height: 8),
                    Text('Histórico', style: Theme.of(context).textTheme.titleMedium),
                    ...entries.reversed.map(_tile),
                  ],
                ]),
        );
      },
    );
  }

  Widget _tile(Entry e) {
    final r = e.r;
    final sub = StringBuffer('${_date.format(r.date)}\n${r.liters.toStringAsFixed(2)} L a ${_money.format(r.price)}/L • ${r.km.toStringAsFixed(0)} km');
    if (e.kmL != null) {
      sub.write('\n${e.dist!.toStringAsFixed(0)} km rodados • ${e.kmL!.toStringAsFixed(2)} km/L • ${_money.format(e.costKm)}/km');
    } else {
      sub.write('\nReferência inicial');
    }
    return Card(
      child: ListTile(
        isThreeLine: true,
        title: Text('${r.fuel[0].toUpperCase()}${r.fuel.substring(1)} — ${_money.format(r.total)}'),
        subtitle: Text(sub.toString()),
        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteRefuel(r)),
      ),
    );
  }

  Widget _chartCard(String title, Widget chart) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
            SizedBox(height: 200, child: chart),
          ]),
        ),
      );

  FlTitlesData _titles() => FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(value < 10 ? 1 : 0), style: const TextStyle(fontSize: 10)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) => value % 1 == 0
                ? Padding(padding: const EdgeInsets.only(top: 6), child: Text('#${value.toInt() + 1}', style: const TextStyle(fontSize: 10)))
                : const SizedBox.shrink(),
          ),
        ),
      );

  Widget _totalsChart(List<Entry> entries) => BarChart(BarChartData(
        titlesData: _titles(),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(x: i, barRods: [BarChartRodData(toY: entries[i].r.total, width: 14, color: Theme.of(context).colorScheme.primary)])
        ],
      ));

  Widget _lineChart(List<Entry> entries, double? Function(Entry) pick) {
    final spots = <FlSpot>[
      for (var i = 0; i < entries.length; i++)
        if (pick(entries[i]) != null) FlSpot(i.toDouble(), pick(entries[i])!)
    ];
    return LineChart(LineChartData(
      titlesData: _titles(),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (entries.length - 1).toDouble(),
      lineBarsData: [
        LineChartBarData(spots: spots, isCurved: false, barWidth: 3, color: Theme.of(context).colorScheme.primary, dotData: const FlDotData(show: true)),
      ],
    ));
  }
}
