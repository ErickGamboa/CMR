import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/fechas.dart' show formatearFechaCorta;
import '../libro/libro_screen.dart';
import '../libro/widgets/pildora_intercambio.dart';
import 'modelo_plan.dart';
import 'repositorio_plan.dart';

/// El plan de alimentación del paciente.
///
/// En papel es una tabla de seis filas por cinco columnas, que en un teléfono
/// no se lee sin hacer zoom. Acá se voltea: primero el día completo, y después
/// una tarjeta por tiempo de comida, porque la pregunta que uno se hace frente
/// al plato no es "¿cómo es mi tabla?" sino "¿qué me toca en el almuerzo?".
///
/// Cada grupo es tocable y abre el libro filtrado por ese grupo, que es el
/// paso que faltaba entre "me tocan 2 carbohidratos" y "entonces qué como".
class PlanAlimentacionVista extends StatefulWidget {
  const PlanAlimentacionVista({super.key, this.fuente});

  /// De dónde se lee el plan. En la app va sin definir y sale de Supabase;
  /// los tests inyectan una fuente falsa.
  final FuentePlan? fuente;

  @override
  State<PlanAlimentacionVista> createState() => _PlanAlimentacionVistaState();
}

class _PlanAlimentacionVistaState extends State<PlanAlimentacionVista> {
  FuentePlan? _fuente;
  late Future<PlanAlimentacion?> _carga = _cargar();

  /// La fuente se resuelve dentro de este `async` para que, si Supabase no
  /// está inicializado, el error caiga en el [FutureBuilder].
  Future<PlanAlimentacion?> _cargar({bool deNuevo = false}) async {
    final fuente = _fuente ??=
        widget.fuente ?? RepositorioPlan(Supabase.instance.client);
    return deNuevo ? fuente.recargar() : fuente.cargar();
  }

  void _abrirLibro(GrupoIntercambio grupo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LibroScreen(filtroInicial: {grupo}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlanAlimentacion?>(
      future: _carga,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Falla(
            mensaje: snapshot.error is FallaPlan
                ? (snapshot.error! as FallaPlan).mensaje
                : 'No pudimos cargar tu plan.',
            onReintentar: () => setState(() {
              _carga = _cargar(deNuevo: true);
            }),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final plan = snapshot.data;
        if (plan == null || plan.vacio) return const _SinPlan();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _TarjetaDelDia(plan: plan, onGrupo: _abrirLibro),
            const SizedBox(height: 8),
            for (final tiempo in TiempoComida.values)
              _TarjetaTiempo(
                tiempo: tiempo,
                asignaciones: plan.de(tiempo),
                onGrupo: _abrirLibro,
              ),
            if (plan.notas != null) ...[
              const SizedBox(height: 8),
              _Notas(texto: plan.notas!),
            ],
          ],
        );
      },
    );
  }
}

/// Los totales del día. Es lo primero porque es lo que el paciente memoriza.
class _TarjetaDelDia extends StatelessWidget {
  const _TarjetaDelDia({required this.plan, required this.onGrupo});

  final PlanAlimentacion plan;
  final ValueChanged<GrupoIntercambio> onGrupo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hayMinimos = plan.totales.values.any((a) => a.esMinimo);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu día', style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              'Vigente desde el ${formatearFechaCorta(plan.vigenteDesde)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final grupo in plan.grupos)
                  if (plan.totales[grupo] case final total?)
                    InkWell(
                      onTap: () => onGrupo(grupo),
                      borderRadius: BorderRadius.circular(8),
                      child: PildoraIntercambio(
                        grupo: grupo,
                        cantidad: total.cantidad,
                        sufijo: total.esMinimo ? '+' : '',
                        compacta: false,
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 15, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Toca un grupo para ver en el libro qué puedes comer.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (hayMinimos) ...[
              const SizedBox(height: 6),
              Text(
                'El "+" quiere decir al menos esa cantidad: puedes comer más.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un tiempo de comida. Los que no llevan nada también se muestran: que en la
/// merienda de la mañana no vaya nada es información, no un hueco.
class _TarjetaTiempo extends StatelessWidget {
  const _TarjetaTiempo({
    required this.tiempo,
    required this.asignaciones,
    required this.onGrupo,
  });

  final TiempoComida tiempo;
  final Map<GrupoIntercambio, Asignacion> asignaciones;
  final ValueChanged<GrupoIntercambio> onGrupo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final grupos = GrupoIntercambio.values
        .where(asignaciones.containsKey)
        .toList();

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tiempo.etiqueta,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (grupos.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Text(
                  'Sin intercambios asignados',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final grupo in grupos)
                InkWell(
                  onTap: () => onGrupo(grupo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            grupo.etiqueta,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        PildoraIntercambio(
                          grupo: grupo,
                          cantidad: asignaciones[grupo]!.cantidad,
                          sufijo: asignaciones[grupo]!.esMinimo ? '+' : '',
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Notas extends StatelessWidget {
  const _Notas({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinPlan extends StatelessWidget {
  const _SinPlan();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu_outlined,
                size: 44,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Todavía no tienes un plan cargado',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tu doctor lo asigna después de la consulta. Mientras tanto '
              'puedes consultar el libro de intercambios.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Falla extends StatelessWidget {
  const _Falla({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: onReintentar,
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
