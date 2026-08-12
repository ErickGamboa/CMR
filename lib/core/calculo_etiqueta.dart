import 'dart:math' as math;

/// Equivalencias de una porción según la etiqueta nutricional.
class PorcionesEtiqueta {
  const PorcionesEtiqueta({
    required this.grasas,
    required this.carbohidratos,
    required this.proteinas,
    required this.carbohidratosNetos,
  });

  final int grasas;
  final int carbohidratos;
  final int proteinas;

  /// Carbohidratos totales menos la fibra. Se muestra porque explica de dónde
  /// sale el conteo de carbos y evita que parezca un error.
  final double carbohidratosNetos;
}

/// Gramos que equivalen a una unidad de cada grupo.
const gramosPorGrasa = 5.0;
const gramosPorCarbohidrato = 15.0;
const gramosPorProteina = 7.0;

/// Convierte gramos a unidades redondeando en el punto medio, con el medio
/// exacto hacia abajo.
///
/// Con grasa (5 g por unidad): 5 g → 1, 7.5 g → 1, 7.6 g → 2, 2.5 g → 0,
/// 3 g → 1. Es redondeo al entero más cercano salvo que el empate baja, que
/// es justo lo contrario de lo que hace `round()`.
int equivalencias(double gramos, double gramosPorUnidad) {
  if (gramos <= 0) return 0;

  // El epsilon protege del ruido binario: 7.5/5 puede quedar en
  // 1.5000000000000002 y entonces el empate subiría en vez de bajar.
  const epsilon = 1e-9;
  final unidades = gramos / gramosPorUnidad;
  return math.max(0, (unidades - 0.5 - epsilon).ceil());
}

/// Calcula las equivalencias de una porción.
///
/// La fibra no se cuenta como carbohidrato: se resta de los carbos totales
/// antes de convertir.
PorcionesEtiqueta calcularPorciones({
  required double grasaTotal,
  required double carbohidratosTotales,
  required double fibra,
  required double proteina,
}) {
  final netos = math.max(0.0, carbohidratosTotales - fibra);

  return PorcionesEtiqueta(
    grasas: equivalencias(grasaTotal, gramosPorGrasa),
    carbohidratos: equivalencias(netos, gramosPorCarbohidrato),
    proteinas: equivalencias(proteina, gramosPorProteina),
    carbohidratosNetos: netos,
  );
}
