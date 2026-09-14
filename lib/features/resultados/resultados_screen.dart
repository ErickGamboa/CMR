import 'package:flutter/material.dart';

import '../../core/datos/modelos.dart';
import '../../core/datos/repositorio.dart';
import '../../core/fechas.dart';
import '../../theme/app_colors.dart';
import '../../widgets/carga_de_datos.dart';
import '../../widgets/recarga.dart';

/// Resultados de composición corporal de una medición, con filtro por fecha.
class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key, this.fuente});

  /// De dónde salen. En la app va sin definir y sale de Supabase; los tests
  /// inyectan una fuente falsa.
  final FuentePaciente? fuente;

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
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
        title: const Text('Resultados'),
        actions: [BotonRecargar(control: _recarga)],
      ),
      body: CargaDeDatos<List<Medicion>>(
        control: _recarga,
        cargar: () => (widget.fuente ?? RepositorioPaciente()).mediciones(),
        vacio: const SinDatos(
          icono: Icons.insights_outlined,
          mensaje: 'Todavía no tienes mediciones registradas.',
        ),
        constructor: (context, mediciones) => _Vista(mediciones: mediciones),
      ),
    );
  }
}

class _Vista extends StatefulWidget {
  const _Vista({required this.mediciones});

  final List<Medicion> mediciones;

  @override
  State<_Vista> createState() => _VistaState();
}

class _VistaState extends State<_Vista> {
  /// La más reciente por defecto: es la que el paciente viene a ver.
  late int _indice = widget.mediciones.length - 1;

  @override
  Widget build(BuildContext context) {
    final mediciones = widget.mediciones;
    final m = mediciones[_indice];

    return Column(
      children: [
        _FiltroFechas(
          mediciones: mediciones,
          indice: _indice,
          onCambio: (i) => setState(() => _indice = i),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Dato(
                etiqueta: 'Peso',
                valor: m.peso.toStringAsFixed(1),
                unidad: 'kg',
                icono: Icons.monitor_weight_outlined,
              ),
              _Dato(
                etiqueta: 'Músculo ganado',
                valor: m.musculoGanado.toStringAsFixed(1),
                unidad: 'kg',
                icono: Icons.fitness_center,
                color: AppColors.turquesaBiocelular,
                detalle: 'Acumulado desde el inicio del plan',
              ),
              _Dato(
                etiqueta: 'Grasa perdida',
                valor: m.grasaPerdida.toStringAsFixed(1),
                unidad: 'kg',
                icono: Icons.trending_down,
                color: AppColors.azulAbisal,
                detalle: 'Acumulado desde el inicio del plan',
              ),
              _Dato(
                etiqueta: '% de grasa',
                valor: m.porcentajeGrasa.toStringAsFixed(1),
                unidad: '%',
                icono: Icons.pie_chart_outline,
              ),
              _Dato(
                etiqueta: 'Grasa visceral',
                valor: m.grasaVisceral.toStringAsFixed(0),
                unidad: '',
                icono: Icons.donut_large_outlined,
                detalle: 'Índice del equipo de bioimpedancia',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fila de fechas para elegir qué medición se está viendo.
class _FiltroFechas extends StatelessWidget {
  const _FiltroFechas({
    required this.mediciones,
    required this.indice,
    required this.onCambio,
  });

  final List<Medicion> mediciones;
  final int indice;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        height: 40,
        // Arranca a la derecha, donde está la medición más reciente, que es la
        // seleccionada por defecto.
        child: ListView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (var i = mediciones.length - 1; i >= 0; i--) ...[
              _Fecha(
                key: ValueKey('fecha-${mediciones[i].fecha.toIso8601String()}'),
                texto: formatearFechaBreve(mediciones[i].fecha),
                activa: i == indice,
                onTap: () => onCambio(i),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Fecha extends StatelessWidget {
  const _Fecha({
    super.key,
    required this.texto,
    required this.activa,
    required this.onTap,
  });

  final String texto;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: activa ? scheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activa ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            texto,
            style: theme.textTheme.labelMedium?.copyWith(
              color: activa ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: activa ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.etiqueta,
    required this.valor,
    required this.unidad,
    required this.icono,
    this.detalle,
    this.color,
  });

  final String etiqueta;
  final String valor;
  final String unidad;
  final IconData icono;
  final String? detalle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 22, color: color ?? scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: theme.textTheme.bodyMedium),
                  if (detalle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detalle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(
                text: valor,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  if (unidad.isNotEmpty)
                    TextSpan(
                      text: ' $unidad',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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
