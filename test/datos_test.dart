import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/core/datos/modelos.dart';
import 'package:cmr_app/core/datos/repositorio.dart';
import 'package:cmr_app/core/iconos.dart';
import 'package:cmr_app/features/citas/citas_screen.dart';
import 'package:cmr_app/features/inicio/inicio_screen.dart';
import 'package:cmr_app/features/laboratorios/laboratorios_screen.dart';
import 'package:cmr_app/features/peptidos/peptidos_screen.dart';
import 'package:cmr_app/features/plan/mi_plan_screen.dart';
import 'package:cmr_app/features/recomendaciones/recomendaciones_screen.dart';
import 'package:cmr_app/features/resultados/resultados_screen.dart';
import 'package:cmr_app/features/videos/videos_screen.dart';
import 'package:cmr_app/theme/app_theme.dart';

import 'fake_auth.dart';
import 'fuentes_falsas.dart';

Future<void> _abrir(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: pantalla));
  await tester.pumpAndSettle();
}

void main() {
  // En postgrest-dart `ascending` es false por defecto, así que un
  // `.order('fecha')` pelado ordena al revés sin avisar. Pasó una vez: el Home
  // tomaba como "próxima cita" la más lejana, y Resultados mostraba la
  // medición más vieja como la última. Esto lo agarra antes de publicar.
  test('todo .order() dice explícitamente en qué dirección ordena', () {
    final sospechosas = <String>[];

    for (final archivo in Directory('lib').listSync(recursive: true)) {
      if (archivo is! File || !archivo.path.endsWith('.dart')) continue;

      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i];
        if (!linea.contains('.order(')) continue;
        // Los comentarios hablan de `.order()` sin llamarlo.
        if (linea.trimLeft().startsWith('//')) continue;
        // La dirección puede ir en la misma línea o en la siguiente.
        final bloque = linea + (i + 1 < lineas.length ? lineas[i + 1] : '');
        if (bloque.contains('ascending:')) continue;
        sospechosas.add('${archivo.path}:${i + 1}');
      }
    }

    expect(
      sospechosas,
      isEmpty,
      reason: 'sin `ascending:` el orden queda descendente sin que se note',
    );
  });

  group('lectura de filas de Supabase', () {
    test('una cita con tipo desconocido se descarta en vez de reventar', () {
      expect(
        Cita.desdeFila({
          'fecha': '2026-09-18T10:30:00',
          'tipo': 'telefonica',
          'profesional': 'X',
          'especialidad': 'Y',
          'lugar': 'Z',
        }),
        isNull,
      );
    });

    test('la hora de la cita se lee tal cual, sin correrla de zona', () {
      final cita = Cita.desdeFila({
        'fecha': '2026-09-18T10:30:00',
        'tipo': 'medica',
        'profesional': 'X',
        'especialidad': 'Y',
        'lugar': 'Z',
      })!;

      expect(cita.fecha.hour, 10);
      expect(cita.fecha.minute, 30);
    });

    test('los numeric vienen como texto y se convierten', () {
      final m = Medicion.desdeFila({
        'fecha': '2026-08-08',
        'peso': '88.90',
        'porcentaje_grasa': '28.40',
        'grasa_visceral': '9.00',
        'grasa_perdida': '7.50',
        'musculo_ganado': 2.2,
      });

      expect(m.peso, 88.9);
      expect(m.musculoGanado, 2.2);
      expect(m.grasaPerdida, 7.5);
    });

    test('un ícono que la app no conoce cae en el genérico, no en null', () {
      final r = Recomendacion.desdeFila({
        'fecha': '2026-08-08',
        'titulo': 'T',
        'texto': 'X',
        'icono': 'algo_que_el_doctor_inventó',
      });

      expect(r.icono, Icons.lightbulb_outline);
      expect(iconoPorNombre('agua'), Icons.water_drop_outlined);
      expect(nombresDeIcono, contains('consejo'));
    });

    test('un analito sin unidad ni referencia no rompe', () {
      final a = AnalisisLab.desdeFila({'nombre': 'TSH', 'valor': '2.4'});

      expect(a.unidad, '');
      expect(a.referencia, '');
      expect(a.fueraDeRango, isFalse);
    });
  });

  group('paciente sin nada cargado', () {
    late PacienteFalso vacia;
    late CatalogoFalso sinCatalogo;

    setUp(() {
      vacia = PacienteFalso.vacia();
      sinCatalogo = CatalogoFalso.vacio();
    });

    testWidgets('Laboratorios lo dice en vez de quedarse en blanco', (
      tester,
    ) async {
      await _abrir(tester, LaboratoriosScreen(fuente: vacia));

      expect(
        find.text('Todavía no tienes laboratorios registrados.'),
        findsOneWidget,
      );
    });

    testWidgets('Resultados lo dice', (tester) async {
      await _abrir(tester, ResultadosScreen(fuente: vacia));

      expect(
        find.text('Todavía no tienes mediciones registradas.'),
        findsOneWidget,
      );
    });

    testWidgets('Recomendaciones lo dice', (tester) async {
      await _abrir(tester, RecomendacionesScreen(fuente: vacia));

      expect(
        find.text('Tu doctor todavía no te dejó recomendaciones.'),
        findsOneWidget,
      );
    });

    testWidgets('Péptidos lo dice en las dos pestañas', (tester) async {
      await _abrir(tester, PeptidosScreen(fuente: vacia));

      expect(
        find.text('Todavía no tienes péptidos asignados.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(Tab, 'Medicamentos'));
      await tester.pumpAndSettle();

      expect(
        find.text('Todavía no tienes medicamentos asignados.'),
        findsOneWidget,
      );
    });

    testWidgets('Citas lo dice en la pestaña que corresponde', (tester) async {
      await _abrir(tester, CitasScreen(fuente: vacia));

      expect(find.text('Todavía no tienes citas médicas.'), findsOneWidget);
    });

    testWidgets('Videos lo dice', (tester) async {
      await _abrir(tester, VideosScreen(fuente: sinCatalogo));

      expect(find.text('Todavía no hay videos publicados.'), findsOneWidget);
    });

    testWidgets('el Home no muestra tarjeta de cita ni resumen', (
      tester,
    ) async {
      await _abrir(
        tester,
        InicioScreen(
          auth: FakeAuth(),
          onIrACitas: () {},
          modulos: const ModulosFalsos(),
          paciente: vacia,
          catalogo: sinCatalogo,
        ),
      );

      expect(find.text('PRÓXIMA CITA'), findsNothing);
      expect(find.text('Resumen de salud'), findsNothing);
      // Los accesos rápidos sí: no dependen de que el doctor cargue nada.
      expect(find.text('Leer etiqueta'), findsOneWidget);
    });

    testWidgets('sin suplementos recetados igual se ve el catálogo de marcas', (
      tester,
    ) async {
      await _abrir(
        tester,
        MiPlanScreen(fuentePaciente: vacia, fuenteCatalogo: CatalogoFalso()),
      );

      await tester.tap(find.widgetWithText(Tab, 'Suplementos'));
      await tester.pumpAndSettle();

      expect(
        find.text('Todavía no tienes suplementos recetados.'),
        findsOneWidget,
      );
      expect(find.text('Ejemplos y marcas'), findsOneWidget);
      expect(find.text('Proteína'), findsOneWidget);
    });
  });

  group('sin conexión', () {
    testWidgets('cada módulo ofrece reintentar, y el reintento funciona', (
      tester,
    ) async {
      final fuente = PacienteFalso()
        ..falla = const FallaDatos('No pudimos conectar.');

      await _abrir(tester, RecomendacionesScreen(fuente: fuente));

      expect(find.text('No pudimos conectar.'), findsOneWidget);

      fuente.falla = null;
      await tester.tap(find.widgetWithText(FilledButton, 'Intentar de nuevo'));
      await tester.pumpAndSettle();

      expect(find.text('Sube la proteína en el desayuno'), findsOneWidget);
    });

    testWidgets('el Home se queda sin tarjeta pero no se llena de errores', (
      tester,
    ) async {
      final fuente = PacienteFalso()
        ..falla = const FallaDatos('No pudimos conectar.');

      await _abrir(
        tester,
        InicioScreen(
          auth: FakeAuth(),
          onIrACitas: () {},
          modulos: const ModulosFalsos(),
          paciente: fuente,
          catalogo: CatalogoFalso(),
        ),
      );

      expect(find.text('No pudimos conectar.'), findsNothing);
      expect(find.text('Intentar de nuevo'), findsNothing);
      expect(find.text('PRÓXIMA CITA'), findsNothing);
      // La fila de accesos no depende de la red.
      expect(find.text('Leer etiqueta'), findsOneWidget);
    });
  });

  group('datos cargados', () {
    testWidgets('Videos lista lo publicado y avisa que abre afuera', (
      tester,
    ) async {
      await _abrir(tester, VideosScreen(fuente: CatalogoFalso()));

      expect(find.text('Se abren fuera de la app'), findsOneWidget);
      for (final v in videosDePrueba) {
        expect(find.text(v.titulo), findsOneWidget, reason: v.titulo);
      }
    });

    testWidgets('el Home muestra la cita que sigue, no una ya cumplida', (
      tester,
    ) async {
      await _abrir(
        tester,
        InicioScreen(
          auth: FakeAuth(),
          onIrACitas: () {},
          modulos: const ModulosFalsos(),
          paciente: PacienteFalso(),
          catalogo: CatalogoFalso(),
        ),
      );

      final ahora = DateTime.now();
      final proxima = citasDePrueba.firstWhere((c) => c.fecha.isAfter(ahora));

      expect(find.text('PRÓXIMA CITA'), findsOneWidget);
      expect(
        find.textContaining(proxima.especialidad),
        findsOneWidget,
        reason: 'debe ser la primera pendiente',
      );
    });
  });
}
