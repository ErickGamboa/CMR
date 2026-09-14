import 'package:flutter/material.dart';

import '../../core/datos/modelos.dart';
import '../../core/datos/repositorio.dart';
import '../../widgets/carga_de_datos.dart';
import '../../widgets/foto_pendiente.dart';
import '../../widgets/recarga.dart';
import '../../widgets/tarjeta_prescripcion.dart';
import 'marcas_screen.dart';
import 'plan_alimentacion_vista.dart';
import 'repositorio_plan.dart';

/// Módulo Mi plan: alimentos y suplementos.
class MiPlanScreen extends StatefulWidget {
  const MiPlanScreen({
    super.key,
    this.fuentePlan,
    this.fuentePaciente,
    this.fuenteCatalogo,
  });

  /// De dónde se lee el plan de alimentación. En la app va sin definir y sale
  /// de Supabase; los tests inyectan una fuente falsa.
  final FuentePlan? fuentePlan;

  /// De dónde salen los suplementos recetados a este paciente.
  final FuentePaciente? fuentePaciente;

  /// De dónde sale el catálogo de marcas, que es igual para todos.
  final FuenteCatalogo? fuenteCatalogo;

  @override
  State<MiPlanScreen> createState() => _MiPlanScreenState();
}

class _MiPlanScreenState extends State<MiPlanScreen> {
  // Un control para las dos pestañas: el botón está en la barra, que es común.
  final _recarga = ControlRecarga();

  @override
  void dispose() {
    _recarga.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi plan'),
          actions: [BotonRecargar(control: _recarga)],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Alimentos'),
              Tab(text: 'Suplementos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PlanAlimentacionVista(fuente: widget.fuentePlan, control: _recarga),
            _Suplementos(
              paciente: widget.fuentePaciente,
              catalogo: widget.fuenteCatalogo,
              control: _recarga,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo recetado a este paciente arriba, y abajo el catálogo de marcas.
///
/// Son dos cosas distintas y por eso son dos consultas: lo de arriba es del
/// paciente, lo de abajo es el mismo catálogo para todos. Si el doctor
/// todavía no le recetó nada, el catálogo igual se muestra.
class _Suplementos extends StatelessWidget {
  const _Suplementos({
    required this.paciente,
    required this.catalogo,
    required this.control,
  });

  final FuentePaciente? paciente;
  final FuenteCatalogo? catalogo;
  final ControlRecarga control;

  void _abrirMarcas(BuildContext context, CategoriaSuplemento categoria) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarcasScreen(categoria: categoria),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final datos = paciente ?? RepositorioPaciente();
    final publico = catalogo ?? RepositorioCatalogo();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        CargaDeDatos<List<Prescripcion>>(
          control: control,
          cargar: () => datos.prescripciones(TipoPrescripcion.suplemento),
          vacio: const _SinRecetados(),
          constructor: (context, recetados) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Titulo(
                texto: 'Recetados por tu doctor',
                detalle: recetados.length == 1
                    ? '1 suplemento'
                    : '${recetados.length} suplementos',
              ),
              const SizedBox(height: 14),
              for (final s in recetados)
                TarjetaPrescripcion(
                  prescripcion: s,
                  icono: Icons.medication_liquid_outlined,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CargaDeDatos<List<CategoriaSuplemento>>(
          control: control,
          cargar: publico.categoriasDeSuplemento,
          vacio: const SizedBox.shrink(),
          constructor: (context, categorias) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Titulo(
                texto: 'Ejemplos y marcas',
                detalle: 'Toca un suplemento para ver las marcas recomendadas',
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
                children: [
                  for (final c in categorias)
                    _FichaCategoria(
                      // Un mismo nombre puede estar recetado arriba y ser
                      // categoría acá (p. ej. "Omega 3"): la llave los
                      // distingue.
                      key: ValueKey('categoria-${c.nombre}'),
                      categoria: c,
                      onTap: () => _abrirMarcas(context, c),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Las fotos de producto están pendientes.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SinRecetados extends StatelessWidget {
  const _SinRecetados();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titulo(
          texto: 'Recetados por tu doctor',
          detalle: 'Todavía no tienes suplementos recetados.',
        ),
        const SizedBox(height: 6),
        Text(
          'Mientras tanto, abajo están los tipos de suplemento y las marcas '
          'que el doctor recomienda.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.texto, required this.detalle});

  final String texto;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(texto, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          detalle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FichaCategoria extends StatelessWidget {
  const _FichaCategoria({
    super.key,
    required this.categoria,
    required this.onTap,
  });

  final CategoriaSuplemento categoria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: FotoPendiente(icono: categoria.icono)),
              const SizedBox(height: 10),
              Text(
                categoria.nombre,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                categoria.marcas.length == 1
                    ? '1 marca'
                    : '${categoria.marcas.length} marcas',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
