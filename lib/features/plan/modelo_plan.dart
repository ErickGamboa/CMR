/// Modelo del plan de alimentación que el doctor le asigna al paciente.
///
/// En papel es una tabla: los seis grupos de intercambio en las filas, los
/// tiempos de comida en las columnas, y en cada celda cuántos intercambios de
/// ese grupo van en ese tiempo. Un guion quiere decir que ese grupo no va en
/// ese tiempo, y un "+" que la cantidad es un mínimo y no un techo.
library;

import '../../core/intercambios.dart';

export '../../core/intercambios.dart';

/// Los tiempos de comida, en el orden del día.
enum TiempoComida {
  desayuno(valor: 'desayuno', etiqueta: 'Desayuno'),
  meriendaManana(valor: 'merienda_manana', etiqueta: 'Merienda de la mañana'),
  almuerzo(valor: 'almuerzo', etiqueta: 'Almuerzo'),
  meriendaTarde(valor: 'merienda_tarde', etiqueta: 'Merienda de la tarde'),
  cena(valor: 'cena', etiqueta: 'Cena');

  const TiempoComida({required this.valor, required this.etiqueta});

  /// El valor del enum `tiempo_comida` de Postgres.
  final String valor;

  final String etiqueta;

  static TiempoComida? porValor(String? valor) {
    for (final t in values) {
      if (t.valor == valor) return t;
    }
    return null;
  }
}

/// Cuántos intercambios de un grupo van en un tiempo de comida, o en el día.
class Asignacion {
  const Asignacion(this.cantidad, {this.esMinimo = false});

  final double cantidad;

  /// El "+" de la tabla impresa: "2+" son dos o más, no exactamente dos.
  final bool esMinimo;

  /// "2" o "2+", como en el papel.
  String get texto => '${formatearCantidad(cantidad)}${esMinimo ? '+' : ''}';
}

/// El plan de alimentación de un paciente.
class PlanAlimentacion {
  const PlanAlimentacion({
    required this.vigenteDesde,
    required this.notas,
    required this.totales,
    required this.distribucion,
  });

  final DateTime vigenteDesde;

  /// Indicaciones que el doctor escribió junto al plan.
  final String? notas;

  /// Cuánto de cada grupo va en todo el día.
  ///
  /// Se guarda aparte de la suma de los tiempos de comida porque no siempre
  /// coincide: en un plan puede decir "4+ vegetales al día" y repartir "2+" en
  /// tres tiempos, que suma seis.
  final Map<GrupoIntercambio, Asignacion> totales;

  /// Cuánto de cada grupo va en cada tiempo de comida. Lo que no está asignado
  /// no aparece: es el guion de la tabla impresa.
  final Map<TiempoComida, Map<GrupoIntercambio, Asignacion>> distribucion;

  /// Los grupos que el plan usa, en el orden del libro. Si el plan no asigna
  /// lácteos, la pantalla no muestra una fila de lácteos vacía.
  List<GrupoIntercambio> get grupos => GrupoIntercambio.values
      .where(
        (g) =>
            totales.containsKey(g) ||
            distribucion.values.any((tiempo) => tiempo.containsKey(g)),
      )
      .toList();

  /// Los tiempos de comida que tienen algo asignado.
  List<TiempoComida> get tiemposConIntercambios => TiempoComida.values
      .where((t) => (distribucion[t] ?? const {}).isNotEmpty)
      .toList();

  Map<GrupoIntercambio, Asignacion> de(TiempoComida tiempo) =>
      distribucion[tiempo] ?? const {};

  bool get vacio => totales.isEmpty && distribucion.isEmpty;
}
