import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/core/datos/modelos.dart';
import 'package:cmr_app/core/datos/repositorio.dart';
import 'package:cmr_app/features/citas/citas_screen.dart';
import 'package:cmr_app/features/laboratorios/laboratorios_screen.dart';
import 'package:cmr_app/features/recomendaciones/recomendaciones_screen.dart';
import 'package:cmr_app/features/resultados/resultados_screen.dart';
import 'package:cmr_app/features/videos/videos_screen.dart';
import 'package:cmr_app/theme/app_theme.dart';
import 'package:cmr_app/widgets/carga_de_datos.dart';
import 'package:cmr_app/widgets/recarga.dart';

import 'fuentes_falsas.dart';

Future<void> _abrir(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: pantalla));
  await tester.pumpAndSettle();
}

/// Fuente que cuenta cuántas veces le pidieron los datos y puede cambiar de
/// respuesta entre una llamada y otra, como pasa cuando el doctor carga algo
/// mientras el paciente tiene la app abierta.
class PacienteQueCambia extends PacienteFalso {
  PacienteQueCambia() : super(recomendaciones: const []);

  int pedidos = 0;
  List<Recomendacion> siguiente = const [];

  @override
  Future<List<Recomendacion>> recomendaciones() async {
    pedidos++;
    return siguiente;
  }
}

void main() {
  group('ControlRecarga', () {
    test('la generación sube en cada recarga', () {
      final control = ControlRecarga();
      addTearDown(control.dispose);

      expect(control.generacion, 0);
      control.recargar();
      control.recargar();
      expect(control.generacion, 2);
    });

    test('cargando cuenta las cargas en curso, no una sola', () {
      final control = ControlRecarga();
      addTearDown(control.dispose);

      expect(control.cargando, isFalse);

      // Dos pestañas pidiendo a la vez: el botón tiene que seguir girando
      // hasta que terminen las dos.
      control.iniciar();
      control.iniciar();
      expect(control.cargando, isTrue);

      control.terminar();
      expect(control.cargando, isTrue);

      control.terminar();
      expect(control.cargando, isFalse);
    });

    test('no explota si se avisa después de desecharlo', () {
      final control = ControlRecarga()..dispose();

      // Una carga que termina cuando la pantalla ya se cerró.
      expect(control.terminar, returnsNormally);
      expect(control.recargar, returnsNormally);
    });
  });

  group('el botón de la barra', () {
    testWidgets('está en todas las pantallas que bajan datos', (tester) async {
      final paciente = PacienteFalso();
      final catalogo = CatalogoFalso();

      final pantallas = <String, Widget>{
        'Recomendaciones': RecomendacionesScreen(fuente: paciente),
        'Laboratorios': LaboratoriosScreen(fuente: paciente),
        'Resultados': ResultadosScreen(fuente: paciente),
        'Citas': CitasScreen(fuente: paciente),
        'Videos': VideosScreen(fuente: catalogo),
      };

      for (final entrada in pantallas.entries) {
        await _abrir(tester, entrada.value);
        expect(
          find.byTooltip('Actualizar'),
          findsOneWidget,
          reason: entrada.key,
        );
      }
    });

    testWidgets('vuelve a pedir los datos y muestra lo nuevo', (tester) async {
      final fuente = PacienteQueCambia();

      await _abrir(tester, RecomendacionesScreen(fuente: fuente));

      expect(fuente.pedidos, 1);
      expect(
        find.text('Tu doctor todavía no te dejó recomendaciones.'),
        findsOneWidget,
      );

      // El doctor le carga una mientras la app está abierta.
      fuente.siguiente = [
        Recomendacion(
          fecha: DateTime(2026, 9, 14),
          titulo: 'Toma más agua',
          texto: 'Dos litros y medio al día.',
          icono: Icons.water_drop_outlined,
        ),
      ];

      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();

      expect(fuente.pedidos, 2);
      expect(find.text('Toma más agua'), findsOneWidget);
    });

    testWidgets('no dispara dos consultas encima', (tester) async {
      final control = ControlRecarga();
      addTearDown(control.dispose);

      await _abrir(
        tester,
        Scaffold(
          appBar: AppBar(actions: [BotonRecargar(control: control)]),
        ),
      );

      // Mientras algo está cargando, el botón no acepta otro toque.
      //
      // Va con `pump` y no con `pumpAndSettle`: el ícono gira en bucle
      // mientras carga, y `pumpAndSettle` espera a que no queden animaciones,
      // o sea para siempre.
      control.iniciar();
      await tester.pump();

      final boton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.refresh),
      );
      expect(boton.onPressed, isNull);

      control.terminar();
      await tester.pumpAndSettle();

      final despues = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.refresh),
      );
      expect(despues.onPressed, isNotNull);
    });
  });

  group('CargaDeDatos con control', () {
    testWidgets('reintentar tras una falla también funciona', (tester) async {
      final control = ControlRecarga();
      addTearDown(control.dispose);

      final fuente = PacienteFalso()
        ..falla = const FallaDatos('No pudimos conectar.');

      await _abrir(
        tester,
        Scaffold(
          appBar: AppBar(actions: [BotonRecargar(control: control)]),
          body: CargaDeDatos<List<Recomendacion>>(
            control: control,
            cargar: fuente.recomendaciones,
            constructor: (context, datos) => Text('${datos.length}'),
          ),
        ),
      );

      expect(find.text('No pudimos conectar.'), findsOneWidget);

      fuente.falla = null;
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();

      expect(find.text('${recomendacionesDePrueba.length}'), findsOneWidget);
    });
  });
}
