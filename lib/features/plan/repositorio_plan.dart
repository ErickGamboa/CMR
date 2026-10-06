import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/datos/repositorio.dart';
import '../../core/local/sincronizador.dart';
import 'modelo_plan.dart';

/// De dónde sale el plan de alimentación.
///
/// Igual que con el libro y con la autenticación, la pantalla depende de esta
/// interfaz y no de Supabase, así que los tests corren sin red.
abstract interface class FuentePlan {
  /// El plan activo del paciente, o `null` si el doctor todavía no le cargó
  /// ninguno.
  Future<PlanAlimentacion?> cargar();

  Future<PlanAlimentacion?> recargar();
}

/// Baja el plan activo del paciente de Supabase, o `null` si no tiene.
///
/// Las políticas de RLS ya limitan las tres tablas al paciente de la sesión,
/// así que acá no hace falta filtrar por paciente: pedir "el plan activo"
/// devuelve el propio y nada más.
Future<Object?> bajarPlan(SupabaseClient db) async {
  final plan = await db
      .from('planes_alimentacion')
      .select('id, vigente_desde, notas')
      .eq('activo', true)
      .maybeSingle();

  if (plan == null) return null;

  final id = plan['id'] as String;

  // Las dos salen juntas: son independientes y esperar una tras otra
  // alargaría la sincronización entera por nada.
  final (totales, distribucion) = await (
    db.from('plan_totales').select('grupo, total, es_minimo').eq('plan_id', id),
    db
        .from('plan_distribucion')
        .select('grupo, tiempo, cantidad, es_minimo')
        .eq('plan_id', id),
  ).wait;

  return {'plan': plan, 'totales': totales, 'distribucion': distribucion};
}

/// Lee el plan de la copia local.
class RepositorioPlan implements FuentePlan {
  RepositorioPlan([this._datos]);

  final Sincronizador? _datos;

  @override
  Future<PlanAlimentacion?> cargar() => _leer();

  /// Es lo mismo que [cargar]: la copia local siempre tiene lo último que se
  /// bajó, no hay nada en memoria que invalidar.
  @override
  Future<PlanAlimentacion?> recargar() => _leer();

  Future<PlanAlimentacion?> _leer() async {
    try {
      final datos = _datos ?? Sincronizador.actual;
      if (datos == null) {
        throw const FallaPlan('No pudimos abrir los datos guardados.');
      }

      final guardado = await datos.leer(Claves.plan) as Map<String, dynamic>?;
      if (guardado == null) return null;

      final plan = guardado['plan'] as Map<String, dynamic>;
      final totales = (guardado['totales'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final distribucion = (guardado['distribucion'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final porGrupo = <GrupoIntercambio, Asignacion>{};
      for (final fila in totales) {
        final grupo = GrupoIntercambio.porNombre(fila['grupo'] as String?);
        if (grupo == null) continue;
        porGrupo[grupo] = Asignacion(
          _aDouble(fila['total']),
          esMinimo: fila['es_minimo'] as bool? ?? false,
        );
      }

      return PlanAlimentacion(
        vigenteDesde: DateTime.parse(plan['vigente_desde'] as String),
        notas: plan['notas'] as String?,
        totales: porGrupo,
        distribucion: _agrupar(distribucion),
      );
    } on FallaDatos catch (e) {
      throw FallaPlan(e.mensaje);
    } on PostgrestException catch (e) {
      throw FallaPlan(
        e.code == '42P01'
            ? 'El plan todavía no está habilitado en el servidor.'
            : 'No pudimos cargar tu plan. Intenta de nuevo en unos minutos.',
      );
    } on SocketException {
      throw const FallaPlan(
        'No pudimos conectar. Revisa tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaPlan('El servidor tardó demasiado. Intenta de nuevo.');
    }
  }

  Map<TiempoComida, Map<GrupoIntercambio, Asignacion>> _agrupar(
    List<Map<String, dynamic>> filas,
  ) {
    final salida = <TiempoComida, Map<GrupoIntercambio, Asignacion>>{};
    for (final fila in filas) {
      final tiempo = TiempoComida.porValor(fila['tiempo'] as String?);
      final grupo = GrupoIntercambio.porNombre(fila['grupo'] as String?);
      final cantidad = _aDouble(fila['cantidad']);
      // Una cantidad en cero es lo mismo que el guion de la tabla impresa: no
      // vale la pena mostrar "0 proteínas" en la merienda.
      if (tiempo == null || grupo == null || cantidad <= 0) continue;

      (salida[tiempo] ??= {})[grupo] = Asignacion(
        cantidad,
        esMinimo: fila['es_minimo'] as bool? ?? false,
      );
    }
    return salida;
  }

  static double _aDouble(Object? valor) => switch (valor) {
    num v => v.toDouble(),
    String v => double.tryParse(v) ?? 0,
    _ => 0,
  };
}

/// Error con mensaje listo para mostrarle al paciente.
class FallaPlan implements Exception {
  const FallaPlan(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
