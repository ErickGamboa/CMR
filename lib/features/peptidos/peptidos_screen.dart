import 'package:flutter/material.dart';

import '../../core/datos/modelos.dart';
import '../../core/datos/repositorio.dart';
import '../../widgets/carga_de_datos.dart';
import '../../widgets/recarga.dart';
import '../../widgets/tarjeta_prescripcion.dart';

/// Módulo Péptidos y medicamentos: lo que el doctor tiene asignado al paciente.
class PeptidosScreen extends StatefulWidget {
  const PeptidosScreen({super.key, this.fuente});

  /// De dónde salen. En la app va sin definir y sale de Supabase; los tests
  /// inyectan una fuente falsa.
  final FuentePaciente? fuente;

  @override
  State<PeptidosScreen> createState() => _PeptidosScreenState();
}

class _PeptidosScreenState extends State<PeptidosScreen> {
  // Un solo control para las dos pestañas: el botón está en la barra, que es
  // común, y recargar una sola dejaría la otra vieja sin que se note.
  final _recarga = ControlRecarga();

  @override
  void dispose() {
    _recarga.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final datos = widget.fuente ?? RepositorioPaciente();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Péptidos y medicamentos'),
          actions: [BotonRecargar(control: _recarga)],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Péptidos'),
              Tab(text: 'Medicamentos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Lista(
              control: _recarga,
              cargar: () => datos.prescripciones(TipoPrescripcion.peptido),
              icono: Icons.vaccines_outlined,
              vacio: 'Todavía no tienes péptidos asignados.',
            ),
            _Lista(
              control: _recarga,
              cargar: () => datos.prescripciones(TipoPrescripcion.medicamento),
              icono: Icons.medication_outlined,
              vacio: 'Todavía no tienes medicamentos asignados.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.control,
    required this.cargar,
    required this.icono,
    required this.vacio,
  });

  final ControlRecarga control;
  final Future<List<Prescripcion>> Function() cargar;
  final IconData icono;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    return CargaDeDatos<List<Prescripcion>>(
      control: control,
      cargar: cargar,
      vacio: SinDatos(icono: icono, mensaje: vacio),
      constructor: (context, prescripciones) {
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Text(
              'Asignado por tu doctor',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            for (final p in prescripciones)
              TarjetaPrescripcion(prescripcion: p, icono: icono),
          ],
        );
      },
    );
  }
}
