import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/features/libro/libro_screen.dart';
import 'package:cmr_app/features/libro/modelo_libro.dart';
import 'package:cmr_app/features/libro/repositorio_libro.dart';
import 'package:cmr_app/theme/app_theme.dart';

/// Fuente de datos falsa: la pantalla del libro no toca Supabase en los tests.
class _FuenteFalsa implements FuenteLibro {
  _FuenteFalsa(this.libro);

  final Libro libro;

  @override
  Future<Libro> cargar() async => libro;

  @override
  Future<Libro> recargar() async => libro;
}

AlimentoLibro _alimento({
  required String id,
  required String seccionId,
  required String nombre,
  String? subseccion,
  List<String> marcas = const [],
  String? porcion,
  Map<GrupoIntercambio, double> vale = const {},
  Intercambios? alternativa,
  bool grasaVariable = false,
  bool libre = false,
  String? nota,
}) {
  return AlimentoLibro(
    id: id,
    seccionId: seccionId,
    subseccion: subseccion,
    nombre: nombre,
    marcas: marcas,
    porcion: porcion,
    vale: Intercambios(vale),
    alternativa: alternativa,
    grasaVariable: grasaVariable,
    libre: libre,
    nota: nota,
  );
}

/// Un libro chiquito con las formas que importan: un alimento con dos grupos,
/// uno con marca, uno con conteo alternativo y uno libre.
Libro _libroDePrueba() {
  return Libro([
    SeccionLibro(
      id: 'carbohidratos',
      nombre: 'Carbohidratos',
      tipo: TipoSeccion.grupo,
      grupo: GrupoIntercambio.carbohidratos,
      nota: null,
      alimentos: [
        _alimento(
          id: 'c1',
          seccionId: 'carbohidratos',
          subseccion: 'Tortillas',
          nombre: 'Tortilla wrap integral',
          marcas: ['Mission'],
          porcion: '1 unidad',
          vale: {
            GrupoIntercambio.carbohidratos: 1.5,
            GrupoIntercambio.grasas: 1,
          },
        ),
        _alimento(
          id: 'c2',
          seccionId: 'carbohidratos',
          subseccion: 'Panes',
          nombre: 'Pan Vital',
          marcas: ['Bimbo'],
          porcion: '1 unidad',
          vale: {GrupoIntercambio.carbohidratos: 1},
        ),
        _alimento(
          id: 'c3',
          seccionId: 'carbohidratos',
          subseccion: 'Vegetales harinosos',
          nombre: 'Plátano maduro o verde',
          porcion: '¼ unidad',
          vale: {GrupoIntercambio.carbohidratos: 1},
        ),
      ],
    ),
    SeccionLibro(
      id: 'lacteos',
      nombre: 'Lácteos',
      tipo: TipoSeccion.grupo,
      grupo: GrupoIntercambio.lacteos,
      nota: null,
      alimentos: [
        _alimento(
          id: 'l1',
          seccionId: 'lacteos',
          subseccion: 'Quesos',
          nombre: 'Queso fresco',
          porcion: '30 g',
          vale: {GrupoIntercambio.proteinas: 1},
          alternativa: const Intercambios({GrupoIntercambio.lacteos: 1}),
        ),
      ],
    ),
    SeccionLibro(
      id: 'subway',
      nombre: 'Subway',
      tipo: TipoSeccion.restaurante,
      grupo: null,
      nota: null,
      alimentos: [
        _alimento(
          id: 's1',
          seccionId: 'subway',
          nombre: 'Vegetariano',
          porcion: '15 cm',
          vale: {
            GrupoIntercambio.carbohidratos: 2.5,
            GrupoIntercambio.vegetales: 1,
          },
        ),
      ],
    ),
    SeccionLibro(
      id: 'libres',
      nombre: 'Alimentos libres',
      tipo: TipoSeccion.libres,
      grupo: null,
      nota: 'No gastan intercambios.',
      alimentos: [
        _alimento(
          id: 'lb1',
          seccionId: 'libres',
          nombre: 'Café, todos los tuestes',
          libre: true,
        ),
      ],
    ),
  ]);
}

Future<void> _abrirLibro(WidgetTester tester) async {
  // Ancho de sobra a propósito: los seis chips de filtro tienen que caber para
  // poder tocarlos sin ir desplazando la fila en cada test.
  tester.view.physicalSize = const Size(2800, 3600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: LibroScreen(fuente: _FuenteFalsa(_libroDePrueba())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('cantidades', () {
    test('los medios se escriben con ½, como en el libro impreso', () {
      expect(formatearCantidad(0.5), '½');
      expect(formatearCantidad(1.5), '1½');
      expect(formatearCantidad(2.5), '2½');
    });

    test('los enteros no llevan decimal', () {
      expect(formatearCantidad(1), '1');
      expect(formatearCantidad(8), '8');
    });
  });

  group('búsqueda', () {
    test('ignora tildes y mayúsculas', () {
      expect(normalizar('Melón'), 'melon');
      expect(normalizar('LÁCTEOS'), 'lacteos');
    });

    test('el alimento se encuentra por su marca', () {
      final alimento = _alimento(
        id: 'x',
        seccionId: 'carbohidratos',
        nombre: 'Pan Vital',
        marcas: ['Bimbo'],
      );

      expect(alimento.coincideCon(normalizar('bimbo')), isTrue);
      expect(alimento.coincideCon(normalizar('pozuelo')), isFalse);
    });
  });

  group('conteo', () {
    test('se dice con palabras, no con letras', () {
      const vale = Intercambios({
        GrupoIntercambio.carbohidratos: 1.5,
        GrupoIntercambio.grasas: 1,
      });

      expect(vale.enPalabras(), '1½ carbohidratos + 1 grasa');
    });

    test('sale en el orden de las columnas del libro', () {
      const vale = Intercambios({
        GrupoIntercambio.grasas: 1,
        GrupoIntercambio.carbohidratos: 1,
      });

      expect(
        vale.presentes.map((e) => e.$1.letra).toList(),
        ['C', 'G'],
      );
    });

    test('el conteo alternativo cuenta para los filtros', () {
      final queso = _alimento(
        id: 'q',
        seccionId: 'lacteos',
        nombre: 'Queso fresco',
        vale: {GrupoIntercambio.proteinas: 1},
        alternativa: const Intercambios({GrupoIntercambio.lacteos: 1}),
      );

      expect(queso.gasta(GrupoIntercambio.proteinas), isTrue);
      expect(queso.gasta(GrupoIntercambio.lacteos), isTrue);
      expect(queso.gasta(GrupoIntercambio.grasas), isFalse);
    });
  });

  group('pantalla del libro', () {
    testWidgets('abre hojeable, con sus secciones y subsecciones',
        (tester) async {
      await _abrirLibro(tester);

      // "Carbohidratos" también es la etiqueta de un chip de filtro, así que
      // las aserciones apuntan a textos que solo existen en la lista.
      expect(find.text('TORTILLAS'), findsOneWidget);
      expect(find.text('QUESOS'), findsOneWidget);
      expect(find.text('Tortilla wrap integral'), findsOneWidget);
      // El conteo abreviado, en el orden de las columnas.
      expect(find.text('1½ C'), findsOneWidget);
      expect(find.text('1 G'), findsOneWidget);
    });

    testWidgets('buscar por marca deja solo ese alimento, con su sección',
        (tester) async {
      await _abrirLibro(tester);

      await tester.enterText(find.byType(TextField), 'bimbo');
      await tester.pumpAndSettle();

      expect(find.text('Pan Vital'), findsOneWidget);
      expect(find.text('Tortilla wrap integral'), findsNothing);
      expect(find.text('1 alimento'), findsOneWidget);
      // Sin encabezados de sección, cada fila dice de dónde salió.
      expect(find.text('Carbohidratos · Panes'), findsOneWidget);
    });

    testWidgets('buscar sin tildes encuentra el alimento con tilde',
        (tester) async {
      await _abrirLibro(tester);

      await tester.enterText(find.byType(TextField), 'platano');
      await tester.pumpAndSettle();

      expect(find.text('Plátano maduro o verde'), findsOneWidget);
      expect(find.text('Pan Vital'), findsNothing);
    });

    testWidgets('filtrar por grupo deja los que gastan ese grupo',
        (tester) async {
      await _abrirLibro(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Grasas'));
      await tester.pumpAndSettle();

      expect(find.text('Tortilla wrap integral'), findsOneWidget);
      expect(find.text('Pan Vital'), findsNothing);
      expect(find.text('Queso fresco'), findsNothing);
    });

    testWidgets('el filtro toma en cuenta el conteo alternativo',
        (tester) async {
      await _abrirLibro(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Lácteos'));
      await tester.pumpAndSettle();

      expect(find.text('Queso fresco'), findsOneWidget);
    });

    testWidgets('el detalle explica el conteo con palabras y la alternativa',
        (tester) async {
      await _abrirLibro(tester);

      await tester.tap(find.text('Queso fresco'));
      await tester.pumpAndSettle();

      expect(find.text('PORCIÓN'), findsOneWidget);
      // Dos veces: en la fila que quedó atrás y en grande dentro de la hoja.
      expect(find.text('30 g'), findsNWidgets(2));
      expect(find.text('1 proteína'), findsOneWidget);
      expect(find.text('o bien'), findsOneWidget);
      expect(find.text('1 lácteo'), findsOneWidget);
    });

    testWidgets('los alimentos libres van en su pestaña y no gastan nada',
        (tester) async {
      await _abrirLibro(tester);

      await tester.tap(find.widgetWithText(Tab, 'Libres'));
      await tester.pumpAndSettle();

      expect(find.text('Café, todos los tuestes'), findsOneWidget);
      expect(find.text('Libre'), findsOneWidget);
      // Los filtros por grupo no aplican acá.
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('los restaurantes van aparte de los alimentos',
        (tester) async {
      await _abrirLibro(tester);

      expect(find.text('Vegetariano'), findsNothing);

      await tester.tap(find.widgetWithText(Tab, 'Restaurantes'));
      await tester.pumpAndSettle();

      expect(find.text('Subway'), findsOneWidget);
      expect(find.text('Vegetariano'), findsOneWidget);
    });

    testWidgets('la simbología está a mano desde el módulo', (tester) async {
      await _abrirLibro(tester);

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      expect(find.text('Cómo leer el libro'), findsOneWidget);
      for (final grupo in GrupoIntercambio.values) {
        expect(find.text(grupo.etiqueta), findsWidgets, reason: grupo.name);
      }
    });
  });
}
