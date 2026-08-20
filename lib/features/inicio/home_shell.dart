import 'package:flutter/material.dart';

import '../../core/auth/servicio_auth.dart';
import '../citas/citas_screen.dart';
import '../libro/libro_screen.dart';
import '../peptidos/peptidos_screen.dart';
import '../plan/mi_plan_screen.dart';
import 'inicio_screen.dart';
import 'modulos.dart';

/// Contenedor de los módulos primarios con la barra inferior.
///
/// Usa [IndexedStack] para que cada pestaña conserve su estado y su posición
/// de scroll al ir y volver.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.auth});

  final ServicioAuth auth;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  void _ir(ModuloPrimario modulo) =>
      setState(() => _indice = modulo.index);

  Widget _pantalla(ModuloPrimario modulo) => switch (modulo) {
        // La tarjeta de próxima cita cambia de pestaña en vez de empujar otra
        // pantalla: las citas ya son un módulo de la barra, y abrirlas encima
        // dejaría dos copias de la misma lista en la pila.
        ModuloPrimario.inicio => InicioScreen(
            auth: widget.auth,
            onIrACitas: () => _ir(ModuloPrimario.citas),
          ),
        ModuloPrimario.libro => const LibroScreen(),
        ModuloPrimario.plan => const MiPlanScreen(),
        ModuloPrimario.peptidos => const PeptidosScreen(),
        ModuloPrimario.citas => const CitasScreen(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          for (final m in ModuloPrimario.values) _pantalla(m),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: [
          for (final m in ModuloPrimario.values)
            NavigationDestination(
              icon: Icon(m.icono),
              selectedIcon: Icon(m.iconoActivo),
              label: m.etiqueta,
              tooltip: m.titulo,
            ),
        ],
      ),
    );
  }
}
