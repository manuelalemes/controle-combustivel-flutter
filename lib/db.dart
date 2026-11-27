import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class AppDb {
  static Database? _db;
  static Future<Database> get db async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'combustivel.db');
    return openDatabase(path, version: 1,
        onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
        onCreate: (d, v) async {
          await d.execute('CREATE TABLE vehicle(id INTEGER PRIMARY KEY AUTOINCREMENT, brand TEXT NOT NULL, model TEXT NOT NULL, year INTEGER NOT NULL, engine REAL NOT NULL)');
          await d.execute('CREATE TABLE refuel(id INTEGER PRIMARY KEY AUTOINCREMENT, vehicle_id INTEGER NOT NULL, fuel TEXT NOT NULL, price REAL NOT NULL, km REAL NOT NULL, liters REAL NOT NULL, date TEXT NOT NULL, FOREIGN KEY(vehicle_id) REFERENCES vehicle(id) ON DELETE CASCADE)');
        });
  }

  static Future<Vehicle?> getVehicle() async {
    final rows = await (await db).query('vehicle', limit: 1);
    return rows.isEmpty ? null : Vehicle.fromMap(rows.first);
  }

static Future<void> insertVehicle(Vehicle v) async {
  final d = await db;
  await d.delete('vehicle'); // garante um único veículo
  await d.insert('vehicle', v.toMap());
}

// apaga o veículo (e, por CASCADE, todos os abastecimentos)
static Future<void> deleteVehicle(int id) async {
  await (await db).delete('vehicle');
}

  static Future<List<Refuel>> refuels(int vehicleId) async {
    final rows = await (await db).query('refuel', where: 'vehicle_id = ?', whereArgs: [vehicleId], orderBy: 'date ASC');
    return rows.map(Refuel.fromMap).toList();
  }

  static Future<void> insertRefuel(Refuel r) async => (await db).insert('refuel', r.toMap());
  static Future<void> deleteRefuel(int id) async => (await db).delete('refuel', where: 'id = ?', whereArgs: [id]);
}
