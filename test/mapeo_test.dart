import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/core/modulos_habilitados.dart';
import 'package:cmr_app/features/inicio/inicio_screen.dart';
import 'package:cmr_app/features/inicio/modulos.dart';
import 'package:cmr_app/features/mapeo/mapeo_screen.dart';
import 'package:cmr_app/features/mapeo/modelo_mapeo.dart';
import 'package:cmr_app/features/mapeo/repositorio_mapeo.dart';
import 'package:cmr_app/theme/app_theme.dart';

import 'fake_auth.dart';

/// Fuente falsa: guarda en memoria, con la misma regla de "uno por día" que
/// impone la llave única de la tabla.
class _FuenteFalsa implements FuenteMapeo {
  _FuenteFalsa([List<RegistroMapeo> iniciales = const []]) {
    for (final r in iniciales) {
      _guardado[TipoMapeo.presion]![r.fechaIso] = r;
    }
  }

  final _guardado = {
    for (final t in TipoMapeo.values) t: <String, RegistroMapeo>{},
  };

  int guardadas = 0;
  FallaMapeo? falla;

  @override
  Future<List<RegistroMapeo>> historial(TipoMapeo tipo) async {
    if (falla case final f?) throw f;
    return _guardado[tipo]!.values.toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Future<void> guardar(TipoMapeo tipo, RegistroMapeo registro) async {
    if (falla case final f?) throw f;
    guardadas++;
    if (registro.vacio) {
      _guardado[tipo]!.remove(registro.fechaIso);
    } else {
      _guardado[tipo]![registro.fechaIso] = registro;
    }
  }

  RegistroMapeo? deDia(TipoMapeo tipo, DateTime dia) =>
      _guardado[tipo]![RegistroMapeo.claveDe(dia)];
}

class _ModulosFalsos implements FuenteModulos {
  const _ModulosFalsos(this.claves);

  final Set<String> claves;

  @override
  Future<Set<String>> habilitados() async => claves;
}

DateTime get _hoy => RegistroMapeo.soloDia(DateTime.now());

Future<void> _abrir(WidgetTester tester, FuenteMapeo fuente) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MapeoScreen(fuente: fuente),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('modelo', () {
    test('descarta los momentos en blanco y recorta lo demás', () {
      final r = RegistroMapeo(
        fecha: DateTime(2026, 9, 12, 17, 40),
        valores: {
          MomentoMapeo.ayunas: '  120/80  ',
          MomentoMapeo.libre: '   ',
          MomentoMapeo.antesDeDormir: '',
        },
      );

      expect(r.valorDe(MomentoMapeo.ayunas), '120/80');
      expect(r.valorDe(MomentoMapeo.libre), '');
      expect(r.vacio, isFalse);

      // La hora se descarta: el registro es del día, no de un instante.
      expect(r.fecha, DateTime(2026, 9, 12));
      expect(r.fechaIso, '2026-09-12');
    });

    test('sin nada escrito el registro está vacío', () {
      final r = RegistroMapeo(
        fecha: DateTime(2026, 9, 12),
        valores: {MomentoMapeo.ayunas: '   '},
      );

      expect(r.vacio, isTrue);
    });

    test('la fecha ISO lleva ceros a la izquierda', () {
      expect(RegistroMapeo.claveDe(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('pantalla', () {
    testWidgets('abre con las dos pestañas y las tres casillas del día', (
      tester,
    ) async {
      await _abrir(tester, _FuenteFalsa());

      expect(find.widgetWithText(AppBar, 'Mapeo'), findsOneWidget);
      expect(find.text('Presión arterial'), findsOneWidget);
      expect(find.text('Glisemia'), findsOneWidget);

      expect(find.text('En ayunas'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('Antes de dormir'), findsOneWidget);

      // Arranca en hoy, que es lo que se anota el 99% de las veces.
      expect(find.text('Hoy'), findsOneWidget);
    });

    testWidgets('guardar manda las tres casillas del día elegido', (
      tester,
    ) async {
      final fuente = _FuenteFalsa();
      await _abrir(tester, fuente);

      await tester.enterText(
        find.widgetWithText(TextField, 'En ayunas'),
        '118/76',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Antes de dormir'),
        '125/80',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      final guardado = fuente.deDia(TipoMapeo.presion, _hoy)!;
      expect(guardado.valorDe(MomentoMapeo.ayunas), '118/76');
      expect(guardado.valorDe(MomentoMapeo.antesDeDormir), '125/80');
      expect(guardado.valorDe(MomentoMapeo.libre), '');
      expect(find.text('Guardado'), findsOneWidget);
    });

    testWidgets('el botón de guardar solo se prende si hay algo que guardar', (
      tester,
    ) async {
      await _abrir(tester, _FuenteFalsa());

      FilledButton boton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardar'),
      );

      expect(boton().onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, '*'), '130/85');
      await tester.pump();

      expect(boton().onPressed, isNotNull);
    });

    testWidgets('volver a guardar el mismo día corrige, no agrega otra fila', (
      tester,
    ) async {
      final fuente = _FuenteFalsa();
      await _abrir(tester, fuente);

      await tester.enterText(
        find.widgetWithText(TextField, 'En ayunas'),
        '118/76',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'En ayunas'),
        '121/79',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(await fuente.historial(TipoMapeo.presion), hasLength(1));
      expect(
        fuente.deDia(TipoMapeo.presion, _hoy)!.valorDe(MomentoMapeo.ayunas),
        '121/79',
      );
    });

    testWidgets('el día anterior abre en blanco y el historial queda listado', (
      tester,
    ) async {
      final fuente = _FuenteFalsa();
      await _abrir(tester, fuente);

      await tester.enterText(
        find.widgetWithText(TextField, 'En ayunas'),
        '118/76',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Registros anteriores'), findsOneWidget);

      await tester.tap(find.byTooltip('Día anterior'));
      await tester.pumpAndSettle();

      expect(find.text('Hoy'), findsNothing);
      final campo = tester.widget<TextField>(
        find.widgetWithText(TextField, 'En ayunas'),
      );
      expect(campo.controller!.text, isEmpty);
    });

    testWidgets('no se puede adelantar más allá de hoy', (tester) async {
      await _abrir(tester, _FuenteFalsa());

      final siguiente = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(siguiente.onPressed, isNull);
    });

    testWidgets('cambiar de día con algo escrito pregunta antes de perderlo', (
      tester,
    ) async {
      final fuente = _FuenteFalsa();
      await _abrir(tester, fuente);

      await tester.enterText(
        find.widgetWithText(TextField, 'En ayunas'),
        '118/76',
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Día anterior'));
      await tester.pumpAndSettle();

      expect(find.text('Tienes cambios sin guardar'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Guardar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(fuente.deDia(TipoMapeo.presion, _hoy), isNotNull);
      expect(find.text('Hoy'), findsNothing);
    });

    testWidgets('si la carga falla ofrece reintentar', (tester) async {
      final fuente = _FuenteFalsa()
        ..falla = const FallaMapeo('No pudimos conectar.');

      await _abrir(tester, fuente);

      expect(find.text('No pudimos conectar.'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Intentar de nuevo'),
        findsOneWidget,
      );

      fuente.falla = null;
      await tester.tap(find.widgetWithText(FilledButton, 'Intentar de nuevo'));
      await tester.pumpAndSettle();

      expect(find.text('En ayunas'), findsOneWidget);
    });
  });

  group('visibilidad en el Home', () {
    Future<void> abrirInicio(WidgetTester tester, Set<String> claves) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InicioScreen(
            auth: FakeAuth(),
            onIrACitas: () {},
            modulos: _ModulosFalsos(claves),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sin habilitar, Mapeo no aparece', (tester) async {
      await abrirInicio(tester, const {});

      expect(find.text('Mapeo'), findsNothing);
      expect(find.text('Resultados'), findsOneWidget);
    });

    testWidgets('habilitado, Mapeo aparece entre Resultados y Leer etiqueta', (
      tester,
    ) async {
      await abrirInicio(tester, const {'mapeo'});

      expect(find.text('Mapeo'), findsOneWidget);

      final orden = ModuloSecundario.visibles(const {'mapeo'});
      expect(
        orden.indexOf(ModuloSecundario.mapeo),
        orden.indexOf(ModuloSecundario.resultados) + 1,
      );
      expect(
        orden.indexOf(ModuloSecundario.leerEtiqueta),
        orden.indexOf(ModuloSecundario.mapeo) + 1,
      );
    });

    testWidgets('desde el Home se abre el módulo', (tester) async {
      await abrirInicio(tester, const {'mapeo'});

      await tester.ensureVisible(find.text('Mapeo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mapeo'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Mapeo'), findsOneWidget);
    });
  });
}
