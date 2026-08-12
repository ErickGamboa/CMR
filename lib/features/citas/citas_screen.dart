import 'package:flutter/material.dart';

import '../../core/datos_demo.dart';

/// Historial y agenda de citas.
///
/// Las pendientes van con el color de marca y las ya cumplidas en gris, para
/// que se distinga de un vistazo qué queda por hacer.
class CitasScreen extends StatelessWidget {
  const CitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ahora = DateTime.now();

    final citas = DatosDemo.citas;
    final pendientes = citas.where((c) => c.fecha.isAfter(ahora)).toList();
    // Las cumplidas van de la más reciente a la más vieja.
    final cumplidas = citas.where((c) => !c.fecha.isAfter(ahora)).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Scaffold(
      appBar: AppBar(title: const Text('Mis citas')),
      body: citas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Todavía no tenés citas registradas.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (pendientes.isNotEmpty) ...[
                  _Encabezado(
                    texto: 'Pendientes',
                    cantidad: pendientes.length,
                  ),
                  const SizedBox(height: 12),
                  for (final c in pendientes)
                    _TarjetaCita(cita: c, cumplida: false),
                  const SizedBox(height: 20),
                ],
                if (cumplidas.isNotEmpty) ...[
                  _Encabezado(
                    texto: 'Anteriores',
                    cantidad: cumplidas.length,
                  ),
                  const SizedBox(height: 12),
                  for (final c in cumplidas)
                    _TarjetaCita(cita: c, cumplida: true),
                ],
              ],
            ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.texto, required this.cantidad});

  final String texto;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(texto, style: theme.textTheme.titleMedium),
        const SizedBox(width: 8),
        Text(
          '$cantidad',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TarjetaCita extends StatelessWidget {
  const _TarjetaCita({required this.cita, required this.cumplida});

  final Cita cita;
  final bool cumplida;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // El gris de las cumplidas se mantiene sobre 4.5:1 contra el fondo: es
    // texto atenuado, no texto ilegible.
    final principal = cumplida ? scheme.onSurfaceVariant : scheme.onSurface;
    final secundario = scheme.onSurfaceVariant;

    return Card(
      key: ValueKey('cita-${cita.fecha.toIso8601String()}'),
      margin: const EdgeInsets.only(bottom: 12),
      color: cumplida ? scheme.surfaceContainer : scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cumplida ? scheme.surface : scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                cumplida ? Icons.check : Icons.event_outlined,
                size: 20,
                color: cumplida ? secundario : scheme.onPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatearFechaLarga(cita.fecha),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: principal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // El estado va escrito además de codificado por color: en
                  // gris contra azul no todo el mundo ve la diferencia.
                  _Estado(cumplida: cumplida),
                  const SizedBox(height: 10),
                  Text(
                    '${cita.profesional} · ${cita.especialidad}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: secundario),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cita.lugar,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: secundario),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({required this.cumplida});

  final bool cumplida;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cumplida ? Colors.transparent : scheme.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cumplida ? scheme.outline : scheme.primary,
        ),
      ),
      child: Text(
        cumplida ? 'Cumplida' : 'Pendiente',
        style: theme.textTheme.labelSmall?.copyWith(
          color: cumplida ? scheme.onSurfaceVariant : scheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
