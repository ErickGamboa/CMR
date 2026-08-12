import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/core/calculo_etiqueta.dart';

void main() {
  group('equivalencias de grasa (5 g por unidad)', () {
    // Los casos que definió el doctor, tal cual.
    test('5 g es 1 grasa', () => expect(equivalencias(5, gramosPorGrasa), 1));
    test('7.5 g sigue siendo 1 grasa',
        () => expect(equivalencias(7.5, gramosPorGrasa), 1));
    test('7.6 g ya son 2 grasas',
        () => expect(equivalencias(7.6, gramosPorGrasa), 2));
    test('2.5 g es 0 grasas',
        () => expect(equivalencias(2.5, gramosPorGrasa), 0));
    test('3 g ya es 1 grasa',
        () => expect(equivalencias(3, gramosPorGrasa), 1));

    test('el empate siempre baja, no sube', () {
      // 12.5 = 2.5 unidades exactas: el medio exacto se va para abajo.
      expect(equivalencias(12.5, gramosPorGrasa), 2);
      expect(equivalencias(12.6, gramosPorGrasa), 3);
      expect(equivalencias(17.5, gramosPorGrasa), 3);
    });

    test('cero y negativos dan cero', () {
      expect(equivalencias(0, gramosPorGrasa), 0);
      expect(equivalencias(-4, gramosPorGrasa), 0);
    });
  });

  group('equivalencias de carbohidrato (15 g) y proteína (7 g)', () {
    test('carbohidratos', () {
      expect(equivalencias(15, gramosPorCarbohidrato), 1);
      expect(equivalencias(22.5, gramosPorCarbohidrato), 1);
      expect(equivalencias(22.6, gramosPorCarbohidrato), 2);
      expect(equivalencias(7.5, gramosPorCarbohidrato), 0);
      expect(equivalencias(8, gramosPorCarbohidrato), 1);
    });

    test('proteínas', () {
      expect(equivalencias(7, gramosPorProteina), 1);
      expect(equivalencias(10.5, gramosPorProteina), 1);
      expect(equivalencias(10.6, gramosPorProteina), 2);
      expect(equivalencias(3.5, gramosPorProteina), 0);
      expect(equivalencias(4, gramosPorProteina), 1);
    });
  });

  group('calcularPorciones', () {
    test('la fibra se resta de los carbohidratos antes de convertir', () {
      // 30 g de carbos con 10 g de fibra = 20 g netos → 1 carbo (20/15 = 1.33).
      final r = calcularPorciones(
        grasaTotal: 0,
        carbohidratosTotales: 30,
        fibra: 10,
        proteina: 0,
      );

      expect(r.carbohidratosNetos, 20);
      expect(r.carbohidratos, 1);
    });

    test('sin restar la fibra el resultado sería otro', () {
      // 30 g crudos serían 2 carbos; con 10 de fibra baja a 1.
      expect(equivalencias(30, gramosPorCarbohidrato), 2);
    });

    test('más fibra que carbohidratos no da negativo', () {
      final r = calcularPorciones(
        grasaTotal: 0,
        carbohidratosTotales: 5,
        fibra: 12,
        proteina: 0,
      );

      expect(r.carbohidratosNetos, 0);
      expect(r.carbohidratos, 0);
    });

    test('una etiqueta completa', () {
      // Grasa 12 g → 2 (12/5 = 2.4)
      // Carbos 40 - 6 = 34 g → 2 (34/15 = 2.27)
      // Proteína 24 g → 3 (24/7 = 3.43)
      final r = calcularPorciones(
        grasaTotal: 12,
        carbohidratosTotales: 40,
        fibra: 6,
        proteina: 24,
      );

      expect(r.grasas, 2);
      expect(r.carbohidratos, 2);
      expect(r.proteinas, 3);
      expect(r.carbohidratosNetos, 34);
    });

    test('una etiqueta vacía da todo en cero', () {
      final r = calcularPorciones(
        grasaTotal: 0,
        carbohidratosTotales: 0,
        fibra: 0,
        proteina: 0,
      );

      expect(r.grasas, 0);
      expect(r.carbohidratos, 0);
      expect(r.proteinas, 0);
    });
  });
}
