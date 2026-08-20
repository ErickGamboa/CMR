import 'package:flutter/material.dart';

import '../../core/datos_demo.dart';
import '../../widgets/foto_pendiente.dart';
import '../../widgets/tarjeta_prescripcion.dart';
import 'marcas_screen.dart';
import 'plan_alimentacion_vista.dart';
import 'repositorio_plan.dart';

/// Módulo Mi plan: alimentos y suplementos.
class MiPlanScreen extends StatelessWidget {
  const MiPlanScreen({super.key, this.fuentePlan});

  /// De dónde se lee el plan de alimentación. En la app va sin definir y sale
  /// de Supabase; los tests inyectan una fuente falsa.
  final FuentePlan? fuentePlan;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi plan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Alimentos'),
              Tab(text: 'Suplementos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PlanAlimentacionVista(fuente: fuentePlan),
            const _Suplementos(),
          ],
        ),
      ),
    );
  }
}

class _Suplementos extends StatelessWidget {
  const _Suplementos();

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _Titulo(
          texto: 'Recetados por tu doctor',
          detalle: '${DatosDemo.suplementosRecetados.length} suplementos',
        ),
        const SizedBox(height: 14),
        for (final s in DatosDemo.suplementosRecetados)
          TarjetaPrescripcion(
            prescripcion: s,
            icono: Icons.medication_liquid_outlined,
          ),
        const SizedBox(height: 20),
        _Titulo(
          texto: 'Ejemplos y marcas',
          detalle: 'Tocá un suplemento para ver las marcas recomendadas',
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
            for (final c in DatosDemo.categoriasSuplementos)
              _FichaCategoria(
                // Un mismo nombre puede estar recetado arriba y ser categoría
                // acá (p. ej. "Omega 3"): la llave los distingue.
                key: ValueKey('categoria-${c.nombre}'),
                categoria: c,
                onTap: () => _abrirMarcas(context, c),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Las fotos de producto están pendientes.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
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
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${categoria.marcas.length} marcas',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
