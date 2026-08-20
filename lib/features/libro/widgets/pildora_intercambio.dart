import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../modelo_libro.dart';

/// La equivalencia de un grupo, como "1 C" o "½ G".
///
/// Lleva la cantidad y la letra juntas, no solo el color: el color ayuda a
/// barrer la lista con la vista, pero quien no distinga los seis tonos igual
/// lee la letra.
class PildoraIntercambio extends StatelessWidget {
  const PildoraIntercambio({
    super.key,
    required this.grupo,
    required this.cantidad,
    this.compacta = true,
    this.sufijo = '',
  });

  final GrupoIntercambio grupo;
  final double cantidad;

  /// En la lista se usa compacta ("1 C"); en la hoja de detalle, con el nombre
  /// completo del grupo.
  final bool compacta;

  /// Se pega a la cantidad. Lo usa el plan de alimentación para el "+" de
  /// "2+", que quiere decir "al menos dos".
  final String sufijo;

  @override
  Widget build(BuildContext context) {
    final colores = coloresDe(grupo);
    final cantidadTexto = '${formatearCantidad(cantidad)}$sufijo';
    final texto = compacta
        ? '$cantidadTexto ${grupo.letra}'
        : '$cantidadTexto '
            '${cantidad == 1 && sufijo.isEmpty ? grupo.singular : grupo.plural}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacta ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: colores.fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: colores.texto,
          fontWeight: FontWeight.w700,
          fontSize: compacta ? 13 : 14,
          height: 1.2,
        ),
      ),
    );
  }

  static ({Color fondo, Color texto}) coloresDe(GrupoIntercambio grupo) {
    return switch (grupo) {
      GrupoIntercambio.carbohidratos => AppColors.pildoraCarbohidratos,
      GrupoIntercambio.frutas => AppColors.pildoraFrutas,
      GrupoIntercambio.proteinas => AppColors.pildoraProteinas,
      GrupoIntercambio.vegetales => AppColors.pildoraVegetales,
      GrupoIntercambio.lacteos => AppColors.pildoraLacteos,
      GrupoIntercambio.grasas => AppColors.pildoraGrasas,
    };
  }
}

/// Las píldoras de un alimento, en el orden de las columnas del libro.
class PildorasDeAlimento extends StatelessWidget {
  const PildorasDeAlimento({super.key, required this.alimento});

  final AlimentoLibro alimento;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (alimento.libre && alimento.vale.vacio) {
      return _Marca(texto: 'Libre', color: theme.colorScheme.secondary);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        for (final (grupo, cantidad) in alimento.vale.presentes)
          PildoraIntercambio(grupo: grupo, cantidad: cantidad),

        // El "ó" del libro: el alimento cuenta de una forma o de la otra.
        if (alimento.alternativa != null)
          _Marca(texto: 'ó', color: theme.colorScheme.onSurfaceVariant),
        if (alimento.alternativa != null)
          for (final (grupo, cantidad) in alimento.alternativa!.presentes)
            PildoraIntercambio(grupo: grupo, cantidad: cantidad),

        // El "*" del libro en las comidas compuestas.
        if (alimento.grasaVariable)
          _Marca(
            texto: '+ grasa*',
            color: PildoraIntercambio.coloresDe(GrupoIntercambio.grasas).texto,
          ),
      ],
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1.2,
        ),
      ),
    );
  }
}
