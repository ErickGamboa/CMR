import 'package:flutter/material.dart';

/// Catálogo cerrado de íconos que el doctor puede elegir desde el sitio admin.
///
/// Los íconos no pueden venir libres de la base: un `IconData` es un punto de
/// código de una fuente compilada dentro de la app, así que un nombre nuevo no
/// dibujaría nada. El doctor elige de esta lista; cualquier otro valor cae en
/// el genérico y la pantalla igual se ve bien.
const _catalogo = <String, IconData>{
  // Recomendaciones
  'consejo': Icons.lightbulb_outline,
  'agua': Icons.water_drop_outlined,
  'ejercicio': Icons.directions_walk,
  'sueno': Icons.bedtime_outlined,
  'alimentacion': Icons.restaurant_outlined,
  'proteina': Icons.egg_outlined,
  'peso': Icons.monitor_weight_outlined,
  'corazon': Icons.favorite_outline,
  'ayuno': Icons.schedule_outlined,
  'sol': Icons.wb_sunny_outlined,

  // Categorías de suplementos
  'suplemento': Icons.medication_liquid_outlined,
  'proteina_polvo': Icons.fitness_center,
  'creatina': Icons.bolt_outlined,
  'omega': Icons.set_meal_outlined,
  'vitamina': Icons.wb_sunny_outlined,
  'magnesio': Icons.spa_outlined,
  'fibra': Icons.grass_outlined,
  'probiotico': Icons.biotech_outlined,
};

/// Los nombres que el sitio admin puede ofrecer en un desplegable.
List<String> get nombresDeIcono => _catalogo.keys.toList();

/// El ícono de ese nombre, o [fallback] si la base trae uno que la app no
/// conoce todavía.
IconData iconoPorNombre(
  String? nombre, {
  IconData fallback = Icons.circle_outlined,
}) => _catalogo[nombre] ?? fallback;
