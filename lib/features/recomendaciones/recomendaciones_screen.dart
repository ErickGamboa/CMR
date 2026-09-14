import 'package:flutter/material.dart';

import '../../core/datos/modelos.dart';
import '../../core/datos/repositorio.dart';
import '../../core/fechas.dart';
import '../../widgets/carga_de_datos.dart';
import '../../widgets/recarga.dart';

/// Recomendaciones que el doctor le dejó al paciente.
class RecomendacionesScreen extends StatefulWidget {
  const RecomendacionesScreen({super.key, this.fuente});

  /// De dónde salen. En la app va sin definir y sale de Supabase; los tests
  /// inyectan una fuente falsa.
  final FuentePaciente? fuente;

  @override
  State<RecomendacionesScreen> createState() => _RecomendacionesScreenState();
}

class _RecomendacionesScreenState extends State<RecomendacionesScreen> {
  final _recarga = ControlRecarga();

  @override
  void dispose() {
    _recarga.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recomendaciones'),
        actions: [BotonRecargar(control: _recarga)],
      ),
      body: CargaDeDatos<List<Recomendacion>>(
        control: _recarga,
        cargar: () =>
            (widget.fuente ?? RepositorioPaciente()).recomendaciones(),
        vacio: const SinDatos(
          icono: Icons.lightbulb_outline,
          mensaje: 'Tu doctor todavía no te dejó recomendaciones.',
        ),
        constructor: (context, recomendaciones) =>
            _Lista(recomendaciones: recomendaciones),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.recomendaciones});

  final List<Recomendacion> recomendaciones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'De tu doctor',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        for (final r in recomendaciones)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(r.icono, size: 22, color: scheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.titulo,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(r.texto, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        Text(
                          formatearFechaBreve(r.fecha),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
