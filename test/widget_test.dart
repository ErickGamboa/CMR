import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/core/fechas.dart';

import 'package:cmr_app/core/auth/servicio_auth.dart';
import 'package:cmr_app/features/auth/auth_gate.dart';
import 'package:cmr_app/features/auth/login_screen.dart';
import 'package:cmr_app/features/cuenta/mi_cuenta_screen.dart';
import 'package:cmr_app/features/inicio/home_shell.dart';
import 'package:cmr_app/features/inicio/modulos.dart';
import 'package:cmr_app/features/plan/mi_plan_screen.dart';
import 'package:cmr_app/main.dart';
import 'package:cmr_app/theme/app_theme.dart';
import 'package:cmr_app/widgets/cmr_logo.dart';
import 'package:cmr_app/widgets/pantalla_carga.dart';
import 'package:cmr_app/widgets/tarjeta_prescripcion.dart';

import 'fake_auth.dart';
import 'fuentes_falsas.dart';

void main() {
  late FakeAuth auth;
  late PacienteFalso paciente;
  late CatalogoFalso catalogo;

  setUp(() {
    auth = FakeAuth();
    paciente = PacienteFalso();
    catalogo = CatalogoFalso();
  });
  tearDown(() => auth.dispose());

  Future<void> abrir(WidgetTester tester, {ServicioAuth? servicio}) =>
      tester.pumpWidget(
        CmrApp(auth: servicio ?? auth, cuenta: CuentaFalsa()),
      );

  testWidgets('sin sesión la app abre en el login con el tema de marca', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CmrLogo), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, const Color(0xFF090972));
  });

  group('pantalla de carga', () {
    testWidgets('calca el splash nativo: logo completo, mismo ancho, centrado', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const PantallaCarga()),
      );

      final logo = tester.widget<CmrLogo>(find.byType(CmrLogo));
      expect(logo.variante, CmrLogoVariante.completo);
      expect(tester.getSize(find.byType(Image)).width, PantallaCarga.anchoLogo);

      // Centrado exacto: el sistema dibuja su splash en el centro, y cualquier
      // desvío se vería como un salto al entregar el control a Flutter.
      final pantalla = tester.getSize(find.byType(Scaffold));
      final centro = tester.getCenter(find.byType(Image));
      expect(centro.dx, closeTo(pantalla.width / 2, 0.5));
      expect(centro.dy, closeTo(pantalla.height / 2, 0.5));
    });

    testWidgets('el indicador no aparece de una, para no parpadear', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const PantallaCarga()),
      );

      double opacidad() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

      expect(opacidad(), 0);

      // Sin `pumpAndSettle`: el indicador gira para siempre y nunca asienta.
      await tester.pump(PantallaCarga.esperaIndicador);
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacidad(), 1);
    });
  });

  testWidgets('CmrLogo respeta la proporción del arte', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CmrLogo(ancho: 260))),
    );

    final tamano = tester.getSize(find.byType(Image));
    expect(tamano.width, 260);
    expect(tamano.height, closeTo(260 * 991 / 1385, 0.5));
  });

  group('validación del login', () {
    testWidgets('exige ambos campos y no llama al servicio', (tester) async {
      await abrir(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
      await tester.pump();

      expect(find.text('Ingresa tu correo'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
      expect(auth.llamadas, isEmpty);
    });

    testWidgets('rechaza correo mal formado y clave corta', (tester) async {
      await abrir(tester);

      await tester.enterText(_campo('Correo electrónico'), 'algo-invalido');
      await tester.enterText(_campo('Contraseña'), 'corta');
      await tester.pump();

      expect(find.text('El correo no tiene un formato válido'), findsOneWidget);
      expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);
    });

    testWidgets('ofrece crear cuenta, pero no recuperar la contraseña', (
      tester,
    ) async {
      await abrir(tester);

      expect(find.text('Crear una cuenta'), findsOneWidget);

      // Recuperar la contraseña no está en la app: el correo de recuperación
      // todavía no tiene por dónde salir, y el doctor puede asignar una nueva
      // desde el sitio.
      expect(find.textContaining('Olvidaste'), findsNothing);
      expect(find.textContaining('Olvidé'), findsNothing);
    });

    testWidgets('el ojito alterna la visibilidad de la contraseña', (
      tester,
    ) async {
      await abrir(tester);

      TextField clave() => tester.widget<TextField>(
        find.descendant(
          of: _campo('Contraseña'),
          matching: find.byType(TextField),
        ),
      );

      expect(clave().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(clave().obscureText, isFalse);
    });
  });

  group('login contra el servicio de auth', () {
    testWidgets('recorta espacios del correo y manda la clave tal cual', (
      tester,
    ) async {
      await abrir(tester);
      await _completarYEnviar(tester, correo: '  ana@cmr.cr ');

      expect(auth.llamadas.single.correo, 'ana@cmr.cr');
      expect(auth.llamadas.single.clave, 'clave-segura');
    });

    testWidgets('muestra el spinner y bloquea el botón mientras envía', (
      tester,
    ) async {
      auth.suspenderProximoIngreso();
      await abrir(tester);
      await _completarYEnviar(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final boton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(boton.onPressed, isNull);

      auth.resolver();
      await tester.pumpAndSettle();
    });

    testWidgets('al abrir sesión el gate cambia a la home', (tester) async {
      await abrir(tester);
      expect(find.byType(LoginScreen), findsOneWidget);

      await _completarYEnviar(tester);
      await tester.pumpAndSettle();

      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('muestra el mensaje de la falla y deja reintentar', (
      tester,
    ) async {
      final malas = FakeAuth(
        falla: const FallaAuth('Correo o contraseña incorrectos.'),
      );
      addTearDown(malas.dispose);

      await abrir(tester, servicio: malas);
      await _completarYEnviar(tester);
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);

      final boton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(boton.onPressed, isNotNull);
    });

    testWidgets('con sesión previa arranca directo en la home', (tester) async {
      await abrir(tester);
      await _completarYEnviar(tester);
      await tester.pumpAndSettle();

      // Simula reabrir la app: Supabase persiste la sesión.
      await tester.pumpWidget(const SizedBox());
      await abrir(tester);
      await tester.pump();

      expect(find.byType(HomeShell), findsOneWidget);
    });
  });

  group('cierre de sesión', () {
    // Salir vive dentro de Mi cuenta, junto a eliminar la cuenta: el borrado
    // tiene que poder encontrarse sin dar vueltas para pasar las tiendas.
    Future<void> abrirMiCuenta(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Mi cuenta'));
      await tester.pumpAndSettle();
    }

    testWidgets('pide confirmación y vuelve al login', (tester) async {
      await abrir(tester);
      await _completarYEnviar(tester);
      await tester.pumpAndSettle();

      await abrirMiCuenta(tester);
      await tester.tap(find.widgetWithText(ListTile, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Cerrar sesión'), findsWidgets);

      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(auth.autenticado, isFalse);
    });

    testWidgets('cancelar mantiene la sesión', (tester) async {
      await abrir(tester);
      await _completarYEnviar(tester);
      await tester.pumpAndSettle();

      await abrirMiCuenta(tester);
      await tester.tap(find.widgetWithText(ListTile, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      // Sigue en Mi cuenta: el Home está debajo, fuera de pantalla.
      expect(find.byType(MiCuentaScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(auth.autenticado, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
    });
  });

  testWidgets('AuthGate arranca en el login cuando no hay sesión', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: AuthGate(auth: auth)));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  group('navegación del home', () {
    /// Monta el home ya autenticado, con los datos del paciente falsos.
    ///
    /// No pasa por el login: eso tiene su propio grupo, y encadenarlo acá
    /// obligaría a arrastrar las fuentes por CmrApp y AuthGate solo para los
    /// tests.
    Future<void> entrar(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HomeShell(auth: auth, paciente: paciente, catalogo: catalogo),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la barra inferior tiene todos los módulos primarios', (
      tester,
    ) async {
      await entrar(tester);

      final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(barra.destinations, hasLength(ModuloPrimario.values.length));

      for (final m in ModuloPrimario.values) {
        expect(find.text(m.etiqueta), findsWidgets, reason: m.etiqueta);
      }
    });

    testWidgets('cada módulo primario abre su pantalla', (tester) async {
      await entrar(tester);

      for (final m in ModuloPrimario.values.skip(1)) {
        await _irA(tester, m);

        // El IndexedStack tiene todas las pantallas montadas a la vez, así que
        // buscar su título no prueba nada: hay que mirar cuál está activa.
        expect(
          tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
          m.index,
          reason: 'el módulo ${m.etiqueta} debe quedar activo',
        );
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          m.index,
        );
      }
    });

    // El contenido del libro se prueba en libro_test.dart, con una fuente de
    // datos falsa: acá solo interesa que el módulo abra con sus secciones.
    testWidgets('Libro abre con sus secciones', (tester) async {
      await entrar(tester);
      await _irA(tester, ModuloPrimario.libro);

      expect(find.widgetWithText(Tab, 'Restaurantes'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Libres'), findsOneWidget);
    });

    testWidgets('Mi plan tiene las pestañas Alimentos y Suplementos', (
      tester,
    ) async {
      await entrar(tester);
      await _irA(tester, ModuloPrimario.plan);

      expect(find.widgetWithText(Tab, 'Alimentos'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Suplementos'), findsOneWidget);
    });

    testWidgets('Suplementos lista los recetados y los ejemplos', (
      tester,
    ) async {
      await entrar(tester);
      await _irA(tester, ModuloPrimario.plan);

      await tester.tap(find.widgetWithText(Tab, 'Suplementos'));
      await tester.pumpAndSettle();

      expect(find.text('Recetados por tu doctor'), findsOneWidget);
      // Se recorre de arriba abajo, en el mismo orden en que están en la
      // pantalla: la lista monta sus hijos por demanda.
      for (final s in suplementosDePrueba) {
        final tarjeta = find.widgetWithText(TarjetaPrescripcion, s.nombre);
        await _bajarEnPlan(tester, tarjeta);
        expect(tarjeta, findsOneWidget, reason: s.nombre);
      }
      for (final c in categoriasDePrueba) {
        await _bajarEnPlan(tester, _categoria(c.nombre));
        expect(_categoria(c.nombre), findsOneWidget, reason: c.nombre);
      }
    });

    testWidgets('tocar un suplemento abre sus marcas recomendadas', (
      tester,
    ) async {
      await entrar(tester);
      await _irA(tester, ModuloPrimario.plan);

      await tester.tap(find.widgetWithText(Tab, 'Suplementos'));
      await tester.pumpAndSettle();

      final proteina = categoriasDePrueba.first;
      await _bajarEnPlan(tester, _categoria(proteina.nombre));
      await tester.tap(_categoria(proteina.nombre));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, proteina.nombre), findsOneWidget);
      for (final marca in proteina.marcas) {
        expect(find.text(marca.nombre), findsOneWidget, reason: marca.nombre);
      }
    });

    testWidgets('Péptidos y medicamentos separa las dos listas', (
      tester,
    ) async {
      await entrar(tester);
      await _irA(tester, ModuloPrimario.peptidos);

      for (final p in peptidosDePrueba) {
        expect(find.text(p.nombre), findsOneWidget, reason: p.nombre);
      }

      await tester.tap(find.widgetWithText(Tab, 'Medicamentos'));
      await tester.pumpAndSettle();

      for (final m in medicamentosDePrueba) {
        expect(find.text(m.nombre), findsOneWidget, reason: m.nombre);
      }
    });

    testWidgets('el Home muestra próxima cita, accesos y el resumen', (
      tester,
    ) async {
      await entrar(tester);

      expect(find.text('PRÓXIMA CITA'), findsOneWidget);
      expect(find.textContaining('Dra. Prueba'), findsOneWidget);
      expect(find.text('Resumen de salud'), findsOneWidget);
      expect(find.text('Grasa perdida'), findsOneWidget);
      expect(find.text('Músculo ganado'), findsOneWidget);
    });

    testWidgets('ninguna etiqueta de módulo secundario se corta', (
      tester,
    ) async {
      await entrar(tester);

      for (final m in ModuloSecundario.abiertos) {
        final texto = tester.widget<Text>(find.text(m.etiqueta));
        expect(texto.maxLines, 1, reason: m.etiqueta);

        // Si el render fuera más ancho que la ficha, habría elipsis.
        final renderizado = tester.renderObject<RenderParagraph>(
          find.text(m.etiqueta),
        );
        expect(
          renderizado.didExceedMaxLines,
          isFalse,
          reason: 'la etiqueta "${m.etiqueta}" no debe cortarse',
        );
      }
    });

    testWidgets('cada módulo secundario navega y permite volver', (
      tester,
    ) async {
      await entrar(tester);

      for (final m in ModuloSecundario.abiertos) {
        // La fila arranca centrada, así que hay ítems fuera de vista a ambos
        // lados; ensureVisible los acerca sin importar la dirección.
        await tester.ensureVisible(find.text(m.etiqueta));
        await tester.pumpAndSettle();
        await tester.tap(find.text(m.etiqueta));
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(AppBar, m.etiqueta),
          findsOneWidget,
          reason: 'el módulo ${m.etiqueta} debe abrir su pantalla',
        );

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(HomeShell), findsOneWidget);
      }
    });

    testWidgets('en pantalla angosta la fila arranca centrada y muestra '
        'las dos flechas', (tester) async {
      // Un teléfono real: las cinco fichas (600px) no entran a lo ancho.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await entrar(tester);

      final fila = tester
          .state<ScrollableState>(find.byType(Scrollable).at(1))
          .position;
      expect(fila.maxScrollExtent, greaterThan(0));
      expect(
        fila.pixels,
        closeTo(fila.maxScrollExtent / 2, 1),
        reason: 'debe arrancar a la mitad, asomando fichas de ambos lados',
      );

      expect(_opacidadFlecha(tester, Icons.chevron_left), 1);
      expect(_opacidadFlecha(tester, Icons.chevron_right), 1);
    });

    testWidgets('al llegar al extremo izquierdo se apaga esa flecha', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await entrar(tester);

      tester
          .state<ScrollableState>(find.byType(Scrollable).at(1))
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();

      expect(_opacidadFlecha(tester, Icons.chevron_left), 0);
      expect(_opacidadFlecha(tester, Icons.chevron_right), 1);
    });

    testWidgets('si todo entra a lo ancho no hay flechas', (tester) async {
      // Ancho de tablet: las cinco fichas caben sin desbordar.
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await entrar(tester);

      expect(_opacidadFlecha(tester, Icons.chevron_left), 0);
      expect(_opacidadFlecha(tester, Icons.chevron_right), 0);
    });

    testWidgets('el resumen muestra los kilos de la última medición', (
      tester,
    ) async {
      await entrar(tester);

      final ultima = medicionesDePrueba.last;
      expect(_kilos(tester), ['7.5', '2.2']);
      expect(
        find.textContaining(formatearFechaBreve(ultima.fecha)),
        findsOneWidget,
      );
    });

    testWidgets('las barras salen del cero hacia lados opuestos y comparten '
        'escala', (tester) async {
      await entrar(tester);
      await tester.pumpAndSettle();

      final ultima = medicionesDePrueba.last;
      final grasa = _barra(tester, 'Grasa perdida');
      final musculo = _barra(tester, 'Músculo ganado');

      // Divergen: la de grasa termina donde arranca la de músculo.
      expect(grasa.right, closeTo(musculo.left, 3));

      // Misma escala: la razón de largos es la razón de los valores.
      expect(
        grasa.width / musculo.width,
        closeTo(ultima.grasaPerdida / ultima.musculoGanado, 0.05),
      );
    });

    testWidgets('la tarjeta de próxima cita lleva al módulo de citas', (
      tester,
    ) async {
      await entrar(tester);

      await tester.tap(find.text('PRÓXIMA CITA'));
      await tester.pumpAndSettle();

      // Cambia de pestaña en vez de empujar otra pantalla: las citas ya son
      // un módulo de la barra inferior.
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        ModuloPrimario.citas.index,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        ModuloPrimario.citas.index,
      );
    });
  });
}

/// Cambia de módulo primario desde la barra inferior.
///
/// Se busca dentro de la [NavigationBar] a propósito: "Péptidos" también es el
/// nombre de una pestaña, y todas las pantallas están montadas a la vez.
Future<void> _irA(WidgetTester tester, ModuloPrimario modulo) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(modulo.etiqueta),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _categoria(String nombre) => find.byKey(ValueKey('categoria-$nombre'));

/// Baja dentro de la pestaña de Mi plan hasta que [objetivo] exista.
///
/// La lista construye sus hijos por demanda, así que lo que está bajo el
/// pliegue todavía no está en el árbol y `ensureVisible` no lo encontraría.
Future<void> _bajarEnPlan(WidgetTester tester, Finder objetivo) async {
  await tester.scrollUntilVisible(
    objetivo,
    200,
    scrollable: find
        .descendant(
          of: find.byType(MiPlanScreen),
          matching: find.byType(Scrollable),
        )
        .last,
  );
  await tester.pumpAndSettle();
}

/// Rectángulo que ocupa la barra de [metrica] en el resumen.
Rect _barra(WidgetTester tester, String metrica) =>
    tester.getRect(find.byKey(ValueKey('barra-$metrica')));

/// Los dos valores en kilos del resumen, en orden: grasa perdida y músculo
/// ganado. Van en `Text.rich` porque el número y la unidad tienen estilos
/// distintos, así que hay que leer el span en vez de buscar un texto plano.
List<String> _kilos(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.textSpan)
    .whereType<TextSpan>()
    .where(
      (s) => s.children?.any((c) => c is TextSpan && c.text == ' kg') ?? false,
    )
    .map((s) => s.text!)
    .toList();

/// Opacidad de la flecha que envuelve a [icono].
double _opacidadFlecha(WidgetTester tester, IconData icono) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byIcon(icono),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

Finder _campo(String etiqueta) =>
    find.widgetWithText(TextFormField, etiqueta).first;

Future<void> _completarYEnviar(
  WidgetTester tester, {
  String correo = 'ana@cmr.cr',
  String clave = 'clave-segura',
}) async {
  await tester.enterText(_campo('Correo electrónico'), correo);
  await tester.enterText(_campo('Contraseña'), clave);
  await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
  await tester.pump();
}
