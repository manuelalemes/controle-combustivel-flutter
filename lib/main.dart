import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db.dart';
import 'models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vehicle_form_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Controle de Combustível',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const Root(),
      );
}

/// Decide a tela: sem veículo -> cadastro; com veículo -> dashboard.
class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  late Future<Vehicle?> _future = AppDb.getVehicle();

  void _reload() {
  setState(() {
    _future = AppDb.getVehicle();
  });
}

  @override
  Widget build(BuildContext context) => FutureBuilder<Vehicle?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final v = snap.data;
          return v == null
              ? VehicleFormScreen(onSaved: _reload)
              : DashboardScreen(vehicle: v, onVehicleDeleted: _reload);
        },
      );
}
