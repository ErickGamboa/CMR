import 'package:flutter/material.dart';

import '../../core/datos_demo.dart';
import '../../widgets/tarjeta_prescripcion.dart';

/// Módulo Péptidos y medicamentos: lo que el doctor tiene asignado al paciente.
class PeptidosScreen extends StatelessWidget {
  const PeptidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              prescripciones: DatosDemo.peptidos,
              icono: Icons.vaccines_outlined,
              vacio: 'Todavía no tenés péptidos asignados.',
            ),
            _Lista(
              prescripciones: DatosDemo.medicamentos,
              icono: Icons.medication_outlined,
              vacio: 'Todavía no tenés medicamentos asignados.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.prescripciones,
    required this.icono,
    required this.vacio,
  });

  final List<Prescripcion> prescripciones;
  final IconData icono;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (prescripciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            vacio,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text(
          'Asignado por tu doctor',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        for (final p in prescripciones)
          TarjetaPrescripcion(prescripcion: p, icono: icono),
      ],
    );
  }
}
