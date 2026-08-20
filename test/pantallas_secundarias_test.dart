import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/core/datos_demo.dart';
import 'package:cmr_app/features/citas/citas_screen.dart';
import 'package:cmr_app/features/etiqueta/leer_etiqueta_screen.dart';
import 'package:cmr_app/features/laboratorios/laboratorios_screen.dart';
import 'package:cmr_app/features/recomendaciones/recomendaciones_screen.dart';
import 'package:cmr_app/features/resultados/resultados_screen.dart';
import 'package:cmr_app/theme/app_theme.dart';

/// Monta una pantalla suelta con el tema de la app.
///
/// El lienzo va grande a propósito: estas pantallas son listas que construyen
/// sus hijos por demanda, y en el lienzo por defecto (800x600) casi todo
/// quedaría sin montar y habría que ir desplazando en cada aserción.
Future<void> _abrir(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(2000, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: pantalla),
  );
}

void main() {
  group('Laboratorios', () {
    testWidgets('lista todas las fechas', (tester) async {
      await _abrir(tester, const LaboratoriosScreen());

      for (final lab in DatosDemo.laboratorios) {
        expect(
          find.text(formatearFechaCorta(lab.fecha)),
          findsOneWidget,
          reason: '${lab.fecha}',
        );
      }
    });

    testWidgets('el más reciente arranca desplegado con sus resultados',
        (tester) async {
      await _abrir(tester, const LaboratoriosScreen());

      final reciente = DatosDemo.laboratorios.first;
      for (final a in reciente.analisis) {
        expect(find.text(a.nombre), findsOneWidget, reason: a.nombre);
      }

      // TSH solo existe en el laboratorio más viejo, que está cerrado.
      expect(find.text('TSH'), findsNothing);
    });

    testWidgets('tocar una fecha despliega sus resultados', (tester) async {
      await _abrir(tester, const LaboratoriosScreen());

      final viejo = DatosDemo.laboratorios.last;
      final analito = viejo.analisis.firstWhere((a) => a.nombre == 'TSH');

      await tester.tap(find.text(formatearFechaCorta(viejo.fecha)));
      await tester.pumpAndSettle();

      expect(find.text(analito.nombre), findsOneWidget);
      expect(find.text('${analito.valor} ${analito.unidad}'), findsOneWidget);
    });

    testWidgets('avisa cuántos valores salieron del rango', (tester) async {
      await _abrir(tester, const LaboratoriosScreen());

      final reciente = DatosDemo.laboratorios.first;
      expect(reciente.fueraDeRango, 1);
      expect(find.text('1 valor fuera del rango de referencia'), findsOneWidget);
    });
  });

  group('Resultados', () {
    testWidgets('muestra las cinco métricas de la última medición',
        (tester) async {
      await _abrir(tester, const ResultadosScreen());

      final ultima = DatosDemo.mediciones.last;

      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Músculo ganado'), findsOneWidget);
      expect(find.text('Grasa perdida'), findsOneWidget);
      expect(find.text('% de grasa'), findsOneWidget);
      expect(find.text('Grasa visceral'), findsOneWidget);

      expect(_valores(tester), [
        ultima.peso.toStringAsFixed(1),
        ultima.musculoGanado.toStringAsFixed(1),
        ultima.grasaPerdida.toStringAsFixed(1),
        ultima.porcentajeGrasa.toStringAsFixed(1),
        ultima.grasaVisceral.toStringAsFixed(0),
      ]);
    });

    testWidgets('el filtro cambia la medición mostrada', (tester) async {
      await _abrir(tester, const ResultadosScreen());

      final primera = DatosDemo.mediciones.first;
      await tester.tap(
        find.byKey(ValueKey('fecha-${primera.fecha.toIso8601String()}')),
      );
      await tester.pumpAndSettle();

      expect(_valores(tester).first, primera.peso.toStringAsFixed(1));
      expect(_valores(tester)[3], primera.porcentajeGrasa.toStringAsFixed(1));
    });
  });

  group('Leer etiqueta', () {
    testWidgets('avisa que los valores son por porción', (tester) async {
      await _abrir(tester, const LeerEtiquetaScreen());

      expect(find.text('Todo es por porción'), findsOneWidget);
      expect(find.textContaining('no del paquete completo'), findsOneWidget);
    });

    testWidgets('calcula las equivalencias con la fibra descontada',
        (tester) async {
      await _abrir(tester, const LeerEtiquetaScreen());

      // Grasa 12 → 2, carbos 40-6=34 → 2, proteína 24 → 3.
      await _escribir(tester, 'Grasa total', '12');
      await _escribir(tester, 'Total de carbohidratos', '40');
      await _escribir(tester, 'Fibra', '6');
      await _escribir(tester, 'Proteína', '24');

      await _pulsar(tester, 'Calcular');

      expect(find.text('EQUIVALENCIAS POR PORCIÓN'), findsOneWidget);
      expect(_equivalencias(tester), ['2', '2', '3']);
      expect(find.textContaining('34 g netos'), findsOneWidget);
    });

    testWidgets('respeta el redondeo del punto medio hacia abajo',
        (tester) async {
      await _abrir(tester, const LeerEtiquetaScreen());

      // 7.5 g de grasa sigue siendo 1; 2.5 g de nada.
      await _escribir(tester, 'Grasa total', '7.5');
      await _pulsar(tester, 'Calcular');
      expect(_equivalencias(tester).first, '1');

      await _escribir(tester, 'Grasa total', '7.6');
      await _pulsar(tester, 'Calcular');
      expect(_equivalencias(tester).first, '2');
    });

    testWidgets('acepta coma como separador decimal', (tester) async {
      await _abrir(tester, const LeerEtiquetaScreen());

      await _escribir(tester, 'Grasa total', '7,6');
      await _pulsar(tester, 'Calcular');

      expect(_equivalencias(tester).first, '2');
    });

    testWidgets('los campos vacíos cuentan como cero', (tester) async {
      await _abrir(tester, const LeerEtiquetaScreen());

      await _pulsar(tester, 'Calcular');

      expect(_equivalencias(tester), ['0', '0', '0']);
    });
  });

  group('Recomendaciones', () {
    testWidgets('lista las del doctor', (tester) async {
      await _abrir(tester, const RecomendacionesScreen());

      for (final r in DatosDemo.recomendaciones) {
        await tester.scrollUntilVisible(find.text(r.titulo), 200);
        expect(find.text(r.titulo), findsOneWidget, reason: r.titulo);
      }
    });
  });

  group('Mis citas', () {
    testWidgets('abre en las médicas y separa pendientes de cumplidas',
        (tester) async {
      await _abrir(tester, const CitasScreen());

      final ahora = DateTime.now();
      final medicas = DatosDemo.citasDe(TipoCita.medica);
      final pendientes = medicas.where((c) => c.fecha.isAfter(ahora)).length;

      expect(find.widgetWithText(Tab, 'Cita médica'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Cita enfermería'), findsOneWidget);

      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Anteriores'), findsOneWidget);

      // El estado va escrito, no solo pintado.
      expect(find.text('Pendiente'), findsNWidgets(pendientes));

      expect(find.text('Cumplida'), findsWidgets);
      expect(medicas.length - pendientes, greaterThan(0));
    });

    testWidgets('la pestaña de enfermería muestra solo sus citas',
        (tester) async {
      await _abrir(tester, const CitasScreen());

      await tester.tap(find.widgetWithText(Tab, 'Cita enfermería'));
      await tester.pumpAndSettle();

      final enfermeria = DatosDemo.citasDe(TipoCita.enfermeria);
      expect(enfermeria, isNotEmpty);

      for (final c in enfermeria) {
        expect(
          find.byKey(ValueKey('cita-${c.fecha.toIso8601String()}')),
          findsOneWidget,
          reason: c.especialidad,
        );
      }
      // Y ninguna de las médicas se cuela.
      for (final c in DatosDemo.citasDe(TipoCita.medica)) {
        expect(
          find.byKey(ValueKey('cita-${c.fecha.toIso8601String()}')),
          findsNothing,
          reason: c.especialidad,
        );
      }
    });

    testWidgets('las cumplidas se ven atenuadas y las pendientes destacadas',
        (tester) async {
      await _abrir(tester, const CitasScreen());

      final ahora = DateTime.now();
      final medicas = DatosDemo.citasDe(TipoCita.medica);
      final pendiente = medicas.firstWhere((c) => c.fecha.isAfter(ahora));
      final cumplida = medicas.firstWhere((c) => !c.fecha.isAfter(ahora));

      final scheme = AppTheme.light.colorScheme;
      expect(_colorCita(tester, pendiente.fecha), scheme.tertiaryContainer);
      expect(_colorCita(tester, cumplida.fecha), scheme.surfaceContainer);
    });
  });
}

Color? _colorCita(WidgetTester tester, DateTime fecha) => tester
    .widget<Card>(find.byKey(ValueKey('cita-${fecha.toIso8601String()}')))
    .color;

/// Los números grandes de las tarjetas, que van en `Text.rich`.
List<String> _valores(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.textSpan)
    .whereType<TextSpan>()
    .where((s) => s.style?.fontWeight == FontWeight.w700)
    .map((s) => s.text!)
    .toList();

/// Las tres cantidades del bloque de resultado de la calculadora.
List<String> _equivalencias(WidgetTester tester) => [
      for (final etiqueta in ['Grasas', 'Carbohidratos', 'Proteínas'])
        tester
            .widget<Text>(find.byKey(ValueKey('equivalencias-$etiqueta')))
            .data!,
    ];

// Se usa `ensureVisible` y no `scrollUntilVisible`: cada campo de texto tiene
// su propio scrollable interno, así que buscar "el" scrollable es ambiguo.
Future<void> _escribir(
  WidgetTester tester,
  String etiqueta,
  String valor,
) async {
  final campo = find.widgetWithText(TextFormField, etiqueta);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, valor);
  await tester.pump();
}

Future<void> _pulsar(WidgetTester tester, String texto) async {
  final boton = find.widgetWithText(FilledButton, texto);
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}
