import 'package:flutter/material.dart';

import '../../core/datos/modelos.dart';
import '../../core/datos/repositorio.dart';
import '../../core/fechas.dart';
import '../../widgets/carga_de_datos.dart';
import '../../widgets/recarga.dart';

/// Lista de laboratorios por fecha. Cada uno se despliega hacia abajo con sus
/// resultados.
class LaboratoriosScreen extends StatefulWidget {
  const LaboratoriosScreen({super.key, this.fuente});

  /// De dónde salen. En la app va sin definir y sale de Supabase; los tests
  /// inyectan una fuente falsa.
  final FuentePaciente? fuente;

  @override
  State<LaboratoriosScreen> createState() => _LaboratoriosScreenState();
}

class _LaboratoriosScreenState extends State<LaboratoriosScreen> {
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
        title: const Text('Laboratorios'),
        actions: [BotonRecargar(control: _recarga)],
      ),
      body: CargaDeDatos<List<Laboratorio>>(
        control: _recarga,
        cargar: () => (widget.fuente ?? RepositorioPaciente()).laboratorios(),
        vacio: const SinDatos(
          icono: Icons.science_outlined,
          mensaje: 'Todavía no tienes laboratorios registrados.',
        ),
        constructor: (context, laboratorios) =>
            _Lista(laboratorios: laboratorios),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.laboratorios});

  final List<Laboratorio> laboratorios;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Toca una fecha para ver los resultados',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < laboratorios.length; i++)
          _TarjetaLaboratorio(
            laboratorio: laboratorios[i],
            // El más reciente arranca abierto: es el que se consulta.
            abiertoInicialmente: i == 0,
          ),
      ],
    );
  }
}

class _TarjetaLaboratorio extends StatelessWidget {
  const _TarjetaLaboratorio({
    required this.laboratorio,
    required this.abiertoInicialmente,
  });

  final Laboratorio laboratorio;
  final bool abiertoInicialmente;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final alertas = laboratorio.fueraDeRango;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // ExpansionTile pinta una línea arriba y abajo al abrirse que acá
        // sobra: la tarjeta ya delimita el bloque.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('lab-${laboratorio.fecha.toIso8601String()}'),
          initiallyExpanded: abiertoInicialmente,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.science_outlined,
              size: 20,
              color: scheme.primary,
            ),
          ),
          title: Text(
            formatearFechaCorta(laboratorio.fecha),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              laboratorio.nombre,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          children: [
            for (final a in laboratorio.analisis) _FilaAnalisis(analisis: a),
            if (alertas > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alertas == 1
                          ? '1 valor fuera del rango de referencia'
                          : '$alertas valores fuera del rango de referencia',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaAnalisis extends StatelessWidget {
  const _FilaAnalisis({required this.analisis});

  final AnalisisLab analisis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fuera = analisis.fueraDeRango;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(analisis.nombre, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'Ref. ${analisis.referencia} ${analisis.unidad}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // El ícono acompaña al color: fuera de rango no puede depender
              // solo del rojo.
              if (fuera) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: scheme.error,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '${analisis.valor} ${analisis.unidad}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fuera ? scheme.error : scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
