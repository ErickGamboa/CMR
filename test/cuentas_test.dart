import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/core/auth/servicio_auth.dart';
import 'package:cmr_app/core/cuenta/estado_cuenta.dart';
import 'package:cmr_app/features/auth/crear_cuenta_screen.dart';
import 'package:cmr_app/features/auth/login_screen.dart';
import 'package:cmr_app/features/cuenta/mi_cuenta_screen.dart';
import 'package:cmr_app/features/inicio/home_shell.dart';
import 'package:cmr_app/main.dart';
import 'package:cmr_app/theme/app_theme.dart';

import 'fake_auth.dart';
import 'fuentes_falsas.dart';

Future<void> _abrir(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: pantalla));
  await tester.pumpAndSettle();
}

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

void main() {
  late FakeAuth auth;

  setUp(() => auth = FakeAuth());
  tearDown(() => auth.dispose());

  group('estado de la cuenta', () {
    test('sin ficha se trata como pendiente, no como aprobada', () {
      // Es el caso de una cuenta vieja o de la del doctor entrando a la app.
      // Ante la duda, la app no muestra nada.
      expect(EstadoCuenta.porValor(null), EstadoCuenta.pendiente);
      expect(EstadoCuenta.porValor('cualquier_cosa'), EstadoCuenta.pendiente);
    });

    test('traduce los valores de la base', () {
      expect(EstadoCuenta.porValor('activo'), EstadoCuenta.activa);
      expect(EstadoCuenta.porValor('inactivo'), EstadoCuenta.inactiva);
      expect(EstadoCuenta.porValor('pendiente'), EstadoCuenta.pendiente);
    });
  });

  group('portón de aprobación', () {
    Future<void> entrar(WidgetTester tester, CuentaFalsa cuenta) async {
      await tester.pumpWidget(CmrApp(auth: auth, cuenta: cuenta));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'paciente@ejemplo.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'secreta123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
      await tester.pumpAndSettle();
    }

    testWidgets('aprobada entra a la app', (tester) async {
      await entrar(tester, CuentaFalsa(EstadoCuenta.activa));

      expect(find.byType(HomeShell), findsOneWidget);
    });

    testWidgets('pendiente no entra: ve la pantalla de espera', (tester) async {
      await entrar(tester, CuentaFalsa(EstadoCuenta.pendiente));

      expect(find.byType(HomeShell), findsNothing);
      expect(find.text('Tu cuenta está en revisión'), findsOneWidget);
    });

    testWidgets('dada de baja tampoco, y lo dice distinto', (tester) async {
      await entrar(tester, CuentaFalsa(EstadoCuenta.inactiva));

      expect(find.byType(HomeShell), findsNothing);
      expect(find.text('Tu cuenta está dada de baja'), findsOneWidget);
    });

    testWidgets('si no se puede comprobar, no entra', (tester) async {
      // Dejar pasar "por si acaso" sería justo el agujero que la aprobación
      // viene a tapar.
      final cuenta = CuentaFalsa()
        ..falla = const FallaCuenta('No pudimos conectar.');

      await entrar(tester, cuenta);

      expect(find.byType(HomeShell), findsNothing);
      expect(find.text('No pudimos conectar.'), findsOneWidget);
    });

    testWidgets('al aprobarla, "Volver a revisar" deja entrar', (tester) async {
      final cuenta = CuentaFalsa(EstadoCuenta.pendiente);
      await entrar(tester, cuenta);

      expect(find.text('Tu cuenta está en revisión'), findsOneWidget);

      // El doctor la aprueba mientras el paciente espera.
      cuenta.estadoActual = EstadoCuenta.activa;
      await tester.tap(find.widgetWithText(FilledButton, 'Volver a revisar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeShell), findsOneWidget);
    });
  });

  group('crear cuenta', () {
    testWidgets('avisa que la clínica tiene que aprobarla', (tester) async {
      await _abrir(tester, CrearCuentaScreen(auth: auth));

      expect(
        find.textContaining('tiene que aprobar tu cuenta'),
        findsOneWidget,
      );
    });

    testWidgets('manda nombre, cédula y correo', (tester) async {
      await _abrir(tester, CrearCuentaScreen(auth: auth));

      await _escribir(tester, 'Nombre', 'María');
      await _escribir(tester, 'Apellidos', 'Rojas Vargas');
      await _escribir(tester, 'Cédula', '1-2345-6789');
      await _escribir(tester, 'Correo', 'maria@ejemplo.com');
      await _escribir(tester, 'Contraseña', 'secreta123');

      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(auth.registros, hasLength(1));
      expect(auth.registros.single.nombre, 'María');
      expect(auth.registros.single.cedula, '1-2345-6789');
      expect(auth.registros.single.correo, 'maria@ejemplo.com');
      // Registrarse no entra a la app: manda una solicitud y vuelve al login.
      expect(auth.autenticado, isFalse);
    });

    testWidgets('no manda nada si falta el nombre o el correo', (tester) async {
      await _abrir(tester, CrearCuentaScreen(auth: auth));

      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(auth.registros, isEmpty);
      expect(find.text('Escribe tu nombre'), findsOneWidget);
      expect(find.text('Escribe tu correo'), findsOneWidget);
    });

    testWidgets('rechaza una contraseña muy corta', (tester) async {
      await _abrir(tester, CrearCuentaScreen(auth: auth));

      await _escribir(tester, 'Nombre', 'María');
      await _escribir(tester, 'Correo', 'maria@ejemplo.com');
      await _escribir(tester, 'Contraseña', '123');

      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(auth.registros, isEmpty);
      expect(find.text('Usa al menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('muestra la falla del servidor sin tecnicismos', (
      tester,
    ) async {
      final conFalla = FakeAuth(
        falla: const FallaAuth(
          'Ese correo ya tiene una cuenta. Intenta entrar.',
        ),
      );
      addTearDown(conFalla.dispose);

      await _abrir(tester, CrearCuentaScreen(auth: conFalla));

      await _escribir(tester, 'Nombre', 'María');
      await _escribir(tester, 'Correo', 'maria@ejemplo.com');
      await _escribir(tester, 'Contraseña', 'secreta123');

      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ese correo ya tiene una cuenta. Intenta entrar.'),
        findsOneWidget,
      );
    });

    testWidgets('desde el login se llega a crear cuenta', (tester) async {
      await _abrir(tester, LoginScreen(auth: auth));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Crear una cuenta'));
      await tester.pumpAndSettle();

      expect(find.byType(CrearCuentaScreen), findsOneWidget);
    });

    testWidgets('al enviar la solicitud vuelve al login y lo avisa', (
      tester,
    ) async {
      await _abrir(tester, LoginScreen(auth: auth));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Crear una cuenta'));
      await tester.pumpAndSettle();

      await _escribir(tester, 'Nombre', 'María');
      await _escribir(tester, 'Correo', 'maria@ejemplo.com');
      await _escribir(tester, 'Contraseña', 'secreta123');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      // Vuelve al login, no queda "adentro" mirando una pantalla que no la
      // deja hacer nada.
      expect(find.byType(CrearCuentaScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(auth.autenticado, isFalse);
      expect(find.textContaining('Tu solicitud se envió'), findsOneWidget);
    });
  });

  group('eliminar la cuenta', () {
    testWidgets('se encuentra desde Mi cuenta y avisa qué se borra', (
      tester,
    ) async {
      await _abrir(tester, MiCuentaScreen(auth: auth));

      expect(find.text('Eliminar mi cuenta'), findsOneWidget);

      await tester.tap(find.text('Eliminar mi cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
      expect(find.textContaining('no se puede deshacer'), findsOneWidget);
      expect(find.textContaining('mapeo'), findsOneWidget);
    });

    testWidgets('cancelar no borra nada', (tester) async {
      await _abrir(tester, MiCuentaScreen(auth: auth));

      await tester.tap(find.text('Eliminar mi cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(auth.cuentaEliminada, isFalse);
    });

    testWidgets('confirmar borra y cierra la sesión', (tester) async {
      await _abrir(tester, MiCuentaScreen(auth: auth));

      await tester.tap(find.text('Eliminar mi cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sí, eliminar'));
      await tester.pumpAndSettle();

      expect(auth.cuentaEliminada, isTrue);
      expect(auth.autenticado, isFalse);
    });

    testWidgets('si falla, lo dice y no cierra la sesión', (tester) async {
      final conFalla = FakeAuth(
        falla: const FallaAuth('No pudimos eliminar la cuenta.'),
      );
      addTearDown(conFalla.dispose);

      await _abrir(tester, MiCuentaScreen(auth: conFalla));

      await tester.tap(find.text('Eliminar mi cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sí, eliminar'));
      await tester.pumpAndSettle();

      expect(conFalla.cuentaEliminada, isFalse);
      expect(find.text('No pudimos eliminar la cuenta.'), findsOneWidget);
    });
  });
}
