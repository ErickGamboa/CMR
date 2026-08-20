import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmr_app/features/plan/mi_plan_screen.dart';
import 'package:cmr_app/features/plan/modelo_plan.dart';
import 'package:cmr_app/features/plan/plan_alimentacion_vista.dart';
import 'package:cmr_app/features/plan/repositorio_plan.dart';
import 'package:cmr_app/theme/app_theme.dart';

class _FuenteFalsa implements FuentePlan {
  _FuenteFalsa(this.plan);

  final PlanAlimentacion? plan;

  @override
  Future<PlanAlimentacion?> cargar() async => plan;

  @override
  Future<PlanAlimentacion?> recargar() async => plan;
}

/// El plan de alimentación de ejemplo del doctor, tal como está en el papel:
/// carbohidratos (6), proteínas (11), lácteos (2), vegetales (4+), frutas (2)
/// y grasas (3), repartidos en cinco tiempos de comida.
PlanAlimentacion _planDeEjemplo() {
  return PlanAlimentacion(
    vigenteDesde: DateTime(2026, 8, 14),
    notas: null,
    totales: const {
      GrupoIntercambio.carbohidratos: Asignacion(6),
      GrupoIntercambio.proteinas: Asignacion(11),
      GrupoIntercambio.lacteos: Asignacion(2),
      GrupoIntercambio.vegetales: Asignacion(4, esMinimo: true),
      GrupoIntercambio.frutas: Asignacion(2),
      GrupoIntercambio.grasas: Asignacion(3),
    },
    distribucion: const {
      TiempoComida.desayuno: {
        GrupoIntercambio.carbohidratos: Asignacion(1),
        GrupoIntercambio.proteinas: Asignacion(2),
        GrupoIntercambio.lacteos: Asignacion(1),
        GrupoIntercambio.vegetales: Asignacion(2, esMinimo: true),
        GrupoIntercambio.grasas: Asignacion(1),
      },
      TiempoComida.almuerzo: {
        GrupoIntercambio.carbohidratos: Asignacion(2),
        GrupoIntercambio.proteinas: Asignacion(4),
        GrupoIntercambio.vegetales: Asignacion(2, esMinimo: true),
        GrupoIntercambio.frutas: Asignacion(1),
        GrupoIntercambio.grasas: Asignacion(1),
      },
      TiempoComida.meriendaTarde: {
        GrupoIntercambio.carbohidratos: Asignacion(1),
        GrupoIntercambio.lacteos: Asignacion(1),
        GrupoIntercambio.frutas: Asignacion(1),
      },
      TiempoComida.cena: {
        GrupoIntercambio.carbohidratos: Asignacion(2),
        GrupoIntercambio.proteinas: Asignacion(5),
        GrupoIntercambio.vegetales: Asignacion(2, esMinimo: true),
        GrupoIntercambio.grasas: Asignacion(1),
      },
    },
  );
}

Future<void> _abrirPlan(WidgetTester tester, {PlanAlimentacion? plan}) async {
  tester.view.physicalSize = const Size(1600, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PlanAlimentacionVista(fuente: _FuenteFalsa(plan)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('modelo del plan', () {
    test('el total del día puede no ser la suma de los tiempos de comida', () {
      final plan = _planDeEjemplo();

      // En el papel los vegetales dicen "4+" al día pero reparten "2+" en tres
      // tiempos, que suma seis: el total va guardado aparte a propósito.
      expect(plan.totales[GrupoIntercambio.vegetales]!.cantidad, 4);
      final repartido = TiempoComida.values.fold<double>(
        0,
        (suma, t) =>
            suma + (plan.de(t)[GrupoIntercambio.vegetales]?.cantidad ?? 0),
      );
      expect(repartido, 6);
    });

    test('el mínimo se escribe con "+", como en el papel', () {
      expect(const Asignacion(4, esMinimo: true).texto, '4+');
      expect(const Asignacion(2).texto, '2');
      expect(const Asignacion(0.5).texto, '½');
    });

    test('solo lista los grupos y los tiempos que el plan usa', () {
      final plan = _planDeEjemplo();

      expect(plan.grupos.length, 6);
      // La merienda de la mañana no lleva nada en este plan.
      expect(
        plan.tiemposConIntercambios.contains(TiempoComida.meriendaManana),
        isFalse,
      );
      expect(plan.tiemposConIntercambios.length, 4);
    });
  });

  group('pantalla del plan', () {
    testWidgets('el día completo va primero, con sus totales', (tester) async {
      await _abrirPlan(tester, plan: _planDeEjemplo());

      expect(find.text('Tu día'), findsOneWidget);
      expect(find.text('Vigente desde el 14 de agosto, 2026'), findsOneWidget);
      expect(find.text('6 carbohidratos'), findsOneWidget);
      expect(find.text('11 proteínas'), findsOneWidget);
      // El "+" de los vegetales se conserva y se explica.
      expect(find.text('4+ vegetales'), findsOneWidget);
      expect(
        find.textContaining('quiere decir al menos esa cantidad'),
        findsOneWidget,
      );
    });

    testWidgets('hay una tarjeta por tiempo de comida con sus cantidades',
        (tester) async {
      await _abrirPlan(tester, plan: _planDeEjemplo());

      for (final tiempo in TiempoComida.values) {
        expect(find.text(tiempo.etiqueta), findsOneWidget, reason: tiempo.name);
      }

      // Almuerzo: 2 carbos, 4 proteínas, 2+ vegetales, 1 fruta, 1 grasa.
      expect(find.text('4 P'), findsOneWidget);
      expect(find.text('2+ V'), findsNWidgets(3));
    });

    testWidgets('el tiempo de comida sin nada asignado lo dice',
        (tester) async {
      await _abrirPlan(tester, plan: _planDeEjemplo());

      expect(find.text('Sin intercambios asignados'), findsOneWidget);
    });

    testWidgets('tocar un grupo abre el libro filtrado por ese grupo',
        (tester) async {
      await _abrirPlan(tester, plan: _planDeEjemplo());

      await tester.tap(find.text('11 proteínas'));
      await tester.pumpAndSettle();

      // El libro abre en su propia pantalla; sin Supabase no trae datos, pero
      // el filtro ya viaja puesto y las secciones están ahí.
      expect(find.widgetWithText(Tab, 'Restaurantes'), findsOneWidget);
    });

    testWidgets('sin plan cargado lo explica en vez de quedarse en blanco',
        (tester) async {
      await _abrirPlan(tester);

      expect(find.text('Todavía no tenés un plan cargado'), findsOneWidget);
      expect(find.textContaining('Tu doctor lo asigna'), findsOneWidget);
    });
  });

  group('módulo Mi plan', () {
    testWidgets('la pestaña de alimentos muestra el plan', (tester) async {
      tester.view.physicalSize = const Size(1600, 4000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MiPlanScreen(fuentePlan: _FuenteFalsa(_planDeEjemplo())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tu día'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Suplementos'), findsOneWidget);
    });
  });
}
