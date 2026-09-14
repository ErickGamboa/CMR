import 'package:flutter/material.dart';

import '../../core/datos/modelos.dart';
import '../../core/datos/repositorio.dart';
import '../../widgets/carga_de_datos.dart';
import '../../widgets/tarjeta_prescripcion.dart';

/// Módulo Péptidos y medicamentos: lo que el doctor tiene asignado al paciente.
class PeptidosScreen extends StatelessWidget {
  const PeptidosScreen({super.key, this.fuente});

  /// De dónde salen. En la app va sin definir y sale de Supabase; los tests
  /// inyectan una fuente falsa.
  final FuentePaciente? fuente;

  @override
  Widget build(BuildContext context) {
    final datos = fuente ?? RepositorioPaciente();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Péptidos y medicamentos'),
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
              cargar: () => datos.prescripciones(TipoPrescripcion.peptido),
              icono: Icons.vaccines_outlined,
              vacio: 'Todavía no tienes péptidos asignados.',
            ),
            _Lista(
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
    required this.cargar,
    required this.icono,
    required this.vacio,
  });

  final Future<List<Prescripcion>> Function() cargar;
  final IconData icono;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    return CargaDeDatos<List<Prescripcion>>(
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
