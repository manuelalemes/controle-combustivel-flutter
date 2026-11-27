class Vehicle {
  final int? id;
  final String brand, model;
  final int year;
  final double engine; // cilindrada em litros (ex.: 1.0)
  Vehicle({this.id, required this.brand, required this.model, required this.year, required this.engine});

  Map<String, Object?> toMap() => {'brand': brand, 'model': model, 'year': year, 'engine': engine};
  factory Vehicle.fromMap(Map<String, Object?> m) => Vehicle(
      id: m['id'] as int,
      brand: m['brand'] as String,
      model: m['model'] as String,
      year: m['year'] as int,
      engine: (m['engine'] as num).toDouble());
}

class Refuel {
  final int? id;
  final int vehicleId;
  final String fuel; // etanol, gasolina, diesel
  final double price, km, liters;
  final DateTime date;
  Refuel({this.id, required this.vehicleId, required this.fuel, required this.price, required this.km, required this.liters, required this.date});

  double get total => price * liters;

  Map<String, Object?> toMap() => {
        'vehicle_id': vehicleId, 'fuel': fuel, 'price': price,
        'km': km, 'liters': liters, 'date': date.toIso8601String()
      };
  factory Refuel.fromMap(Map<String, Object?> m) => Refuel(
      id: m['id'] as int,
      vehicleId: m['vehicle_id'] as int,
      fuel: m['fuel'] as String,
      price: (m['price'] as num).toDouble(),
      km: (m['km'] as num).toDouble(),
      liters: (m['liters'] as num).toDouble(),
      date: DateTime.parse(m['date'] as String));
}

/// Abastecimento + indicadores (null no primeiro registro).
class Entry {
  final Refuel r;
  final double? dist, kmL, costKm;
  Entry(this.r, this.dist, this.kmL, this.costKm);
}

List<Entry> buildEntries(List<Refuel> l) {
  final out = <Entry>[];
  for (var i = 0; i < l.length; i++) {
    if (i == 0) {
      out.add(Entry(l[i], null, null, null));
      continue;
    }
    final d = l[i].km - l[i - 1].km;
    out.add(d > 0 ? Entry(l[i], d, d / l[i].liters, l[i].total / d) : Entry(l[i], null, null, null));
  }
  return out;
}
