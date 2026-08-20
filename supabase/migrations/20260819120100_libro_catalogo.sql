-- Catálogo del libro de intercambios: 234 alimentos con conteo + 50 alimentos
-- libres, transcritos de "Lista de Intercambios de Alimentos" (CMR).
--
-- Correcciones aplicadas sobre el PDF (erratas de digitación, no de conteo):
--   "azúcar regulas" → azúcar regular          "boja en grasa" → bajo en grasa
--   "Aceite de suya" → Aceite de soya          "Cuarto de libre" → de libra
--   "3 tasas" → 3 tazas                        "½ tasa" → ½ taza
--   "petit poas" → petit pois                  "mani" → maní
--   "Spaguetti Napolinato" → Spaghetti Napolitano
--   "Daikiri" → Daiquirí                       "Mozarella" → mozzarella
--   "Crunchywrap supreme" → Crunchwrap Supreme "Pop corn Chicken" → Popcorn
--   "Tender Grill classic" → TenderGrill Classic
--   "(San PellegrinoI:" → (San Pellegrino):    "Aceites es spray" → en spray
--   "Kellogg”s"/"Kelloggs" → Kellogg's         "Jacks" → Jack's
--   "Lays" → Lay's                             "Hersheys" → Hershey's
--   "Te frío/negro/verde/chai" → Té            "0 15g" → o 15 g
--
-- Además se corrigieron cuatro conteos que en el PDF están en la columna
-- equivocada o incompletos (garbanzos, salsa de tomate embotellada, yogurt
-- griego y quesoburguesa) y se completaron las porciones que el PDF no anota.
-- Cada cambio va comentado en su fila y explicado en LIBRO_REVISION.md.
--
-- Queda una sola fila con estado 'por_revisar', que NO se muestra en la app:
-- la del subtítulo "Ensaladas" de McDonald's, que no tiene nombre de platillo.

-- ---------------------------------------------------------------------------
-- Secciones
-- ---------------------------------------------------------------------------

insert into libro_secciones (id, nombre, tipo, grupo, nota, orden) values
  ('carbohidratos',    'Carbohidratos',          'grupo',       'carbohidratos', null, 1),
  ('vegetales',        'Vegetales',              'grupo',       'vegetales',     null, 2),
  ('frutas',           'Frutas',                 'grupo',       'frutas',        null, 3),
  ('lacteos',          'Lácteos',                'grupo',       'lacteos',       null, 4),
  ('proteinas',        'Proteínas',              'grupo',       'proteinas',
   '30 g de carne, pollo, cerdo o pescado equivalen a 1 proteína.',                    5),
  ('grasas',           'Grasas',                 'grupo',       'grasas',        null, 6),
  ('bebidas-alco',     'Bebidas alcohólicas',    'bebidas',     null,
   'El alcohol se cuenta como grasa: por eso estas bebidas gastan intercambios de grasa.', 7),
  ('bebidas-sin-alco', 'Bebidas no alcohólicas', 'bebidas',     null,            null, 8),
  ('subway',           'Subway',                 'restaurante', null,            null, 9),
  ('pizza-hut',        'Pizza Hut',              'restaurante', null,            null, 10),
  ('japonesa',         'Comida japonesa',        'restaurante', null,            null, 11),
  ('taco-bell',        'Taco Bell',              'restaurante', null,            null, 12),
  ('burger-king',      'Burger King',            'restaurante', null,            null, 13),
  ('kfc',              'KFC',                    'restaurante', null,            null, 14),
  ('mcdonalds',        'McDonald''s',            'restaurante', null,            null, 15),
  ('libres',           'Alimentos libres',       'libres',      null,
   'No gastan intercambios. Los que traen condición la tienen anotada.',               16)
on conflict (id) do update set
  nombre = excluded.nombre, tipo = excluded.tipo, grupo = excluded.grupo,
  nota = excluded.nota, orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Carbohidratos
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, p, l, g, nota, orden) values
  ('carbo-001', 'carbohidratos', 'Tortillas', 'Tortillas de maíz',                        array['Erica'],                     '3 unidades',           1,   0, 0, 0,   null,  1),
  ('carbo-002', 'carbohidratos', 'Tortillas', 'Tortillas gruesitas',                      array['Erica'],                     '2 unidades',           1,   0, 0, 0,   null,  2),
  ('carbo-003', 'carbohidratos', 'Tortillas', 'Tortillas de maíz',                        array['Las Perseguidas'],           '2 unidades',           1,   0, 0, 0,   null,  3),
  ('carbo-004', 'carbohidratos', 'Tortillas', 'Tortillas pequeñas',                       array['TortiRicas','Las Maiceras'], '2 unidades',           1,   0, 0, 0,   null,  4),
  ('carbo-005', 'carbohidratos', 'Tortillas', 'Tortillas de maíz sabor a queso',          array['TortiRicas'],                '1 unidad',             1,   0, 0, 0,   null,  5),
  ('carbo-006', 'carbohidratos', 'Tortillas', 'Tortilla wrap regular',                    array['Mission','Bimbo'],           '1 unidad',             1,   0, 0, 1,   null,  6),
  ('carbo-007', 'carbohidratos', 'Tortillas', 'Tortilla wrap integral',                   array['Mission'],                   '1 unidad',           1.5,   0, 0, 1,   null,  7),
  ('carbo-008', 'carbohidratos', 'Tortillas', 'Tortilla clásica, light',                  array['Bimbo','Mission'],           '1 unidad',             1,   0, 0, 0,   null,  8),
  ('carbo-009', 'carbohidratos', 'Tortillas', 'Tortillas burritos',                       array['Mission'],                   '1 unidad',           2.5,   0, 0, 1,   null,  9),
  ('carbo-010', 'carbohidratos', 'Tortillas', 'Tortillas Rapiditas clásicas',             '{}',                               '2 unidades',           1,   0, 0, 0,   null, 10),
  ('carbo-011', 'carbohidratos', 'Tortillas', 'Tortillas Rapiditas 0% grasa o integrales', '{}',                              '2 unidades',         1.5,   0, 0, 0,   null, 11),
  ('carbo-012', 'carbohidratos', 'Tortillas', 'Tortillas de maíz',                        array['Campesinas Gruesitas'],      '2 unidades',           1,   0, 0, 0,   null, 12),
  ('carbo-013', 'carbohidratos', 'Tortillas', 'Tortillas grandes',                        array['Del Fogón'],                 '2 unidades',           1,   0, 0, 0,   null, 13),
  ('carbo-014', 'carbohidratos', 'Tortillas', 'Tortillas minis',                          array['Del Fogón'],                 '4 unidades',           1,   0, 0, 0,   null, 14),
  ('carbo-015', 'carbohidratos', 'Tortillas', 'Tortilla casera palmeada pequeña',         '{}',                               '1 unidad',             1,   0, 0, 0,   null, 15),
  ('carbo-016', 'carbohidratos', 'Tortillas', 'Tortillas tostadas de taco o chalupa',     '{}',                               '2 unidades',           1,   0, 0, 0.5, null, 16),
  ('carbo-017', 'carbohidratos', 'Tortillas', 'Harina de maíz o trigo',                   '{}',                               '3 cucharadas',         1,   0, 0, 0,   null, 17),

  ('carbo-018', 'carbohidratos', 'Panes', 'Pita micro bocas',                             array['Mr Pita'],                   '3 unidades',           1,   0, 0, 0,   null, 18),
  ('carbo-019', 'carbohidratos', 'Panes', 'Pita micro delgado blanco',                    array['Pura Pita'],                 '3 unidades',           1,   0, 0, 0,   null, 19),
  ('carbo-020', 'carbohidratos', 'Panes', 'Pita micro delgado blanco',                    array['Pura Pita'],                 '2 unidades',         1.5,   0, 0, 0,   null, 20),
  ('carbo-021', 'carbohidratos', 'Panes', 'Pan masa madre o baguette',                    '{}',                               '4 dedos de la mano',   1,   0, 0, 0,   null, 21),
  ('carbo-022', 'carbohidratos', 'Panes', 'Pan cuadrado blanco o integral',               '{}',                               '1 unidad',             1,   0, 0, 0,   null, 22),
  ('carbo-023', 'carbohidratos', 'Panes', 'Pan light, 0% grasa o tostado doble fibra',    '{}',                               '2 unidades',           1,   0, 0, 0,   null, 23),
  ('carbo-024', 'carbohidratos', 'Panes', 'Pan Vital',                                    array['Bimbo'],                     '1 unidad',             1,   0, 0, 0,   null, 24),
  ('carbo-025', 'carbohidratos', 'Panes', 'Thins integral o multigrano',                  '{}',                               '1 unidad',             1,   0, 0, 0,   null, 25),
  ('carbo-026', 'carbohidratos', 'Panes', 'Bollitos europeos deli',                       array['Bimbo'],                     '1 unidad',             2,   0, 0, 1,   null, 26),
  ('carbo-027', 'carbohidratos', 'Panes', 'Pan para hamburguesa grande',                  array['Bimbo'],                     '1 unidad',           2.5,   0, 0, 1,   null, 27),
  ('carbo-028', 'carbohidratos', 'Panes', 'Pan cuadrado integral',                        '{}',                               '1 unidad',             1,   0, 0, 0,   null, 28),

  ('carbo-029', 'carbohidratos', 'Granos', 'Frijoles',                                    '{}',                               '½ taza',               1,   0, 0, 0,   null, 29),
  ('carbo-030', 'carbohidratos', 'Granos', 'Frijoles molidos comprados',                  '{}',                               '1/3 taza',             1,   0, 0, 1,   null, 30),
  -- El PDF pone el segundo 1 en la columna de grasas. Las leguminosas hervidas
  -- no traen grasa y el propio libro cuenta las demás (hummus, gallo pinto)
  -- con proteína, así que el valor iba una columna a la izquierda.
  ('carbo-031', 'carbohidratos', 'Granos', 'Garbanzos, lentejas',                         '{}',                               '½ taza',               1,   1, 0, 0,   null, 31),
  ('carbo-032', 'carbohidratos', 'Granos', 'Gallo pinto sin grasa',                       '{}',                               '1/3 taza',             1,   0, 0, 0,   null, 32),
  ('carbo-033', 'carbohidratos', 'Granos', 'Gallo pinto contado como proteína',           '{}',                               '1/3 taza',           0.5, 0.5, 0, 0,   null, 33),
  ('carbo-034', 'carbohidratos', 'Granos', 'Arroz blanco o integral',                     '{}',                               '1/3 taza',             1,   0, 0, 0,   null, 34),
  ('carbo-035', 'carbohidratos', 'Granos', 'Hummus',                                      '{}',                               '1/3 taza o 5 cucharadas', 0.5, 0.5, 0, 1, null, 35),

  ('carbo-036', 'carbohidratos', 'Pastas', 'Pasta cocida, integral o corriente',          '{}',                               '½ taza',               1,   0, 0, 0,   null, 36),
  ('carbo-037', 'carbohidratos', 'Pastas', 'Canelones pequeños',                          '{}',                               '2.5 unidades',         1,   0, 0, 0,   null, 37),
  ('carbo-038', 'carbohidratos', 'Pastas', 'Pasta con salsa de queso',                    array['Prince'],                    '½ taza',               1,   0, 0, 1.5, null, 38),

  ('carbo-039', 'carbohidratos', 'Vegetales harinosos', 'Guisantes, maíz dulce, petit pois', '{}',                            '½ taza',               1,   0, 0, 0,   null, 39),
  ('carbo-040', 'carbohidratos', 'Vegetales harinosos', 'Camote, tiquisque, yuca y papa', '{}',                               '½ taza',               1,   0, 0, 0,   null, 40),
  ('carbo-041', 'carbohidratos', 'Vegetales harinosos', 'Ayote, arracache y ñampí',       '{}',                               '½ taza',               1,   0, 0, 0,   null, 41),
  ('carbo-042', 'carbohidratos', 'Vegetales harinosos', 'Papa hervida o al horno',        '{}',                               '1 pequeña',            1,   0, 0, 0,   null, 42),
  ('carbo-043', 'carbohidratos', 'Vegetales harinosos', 'Plátano maduro o verde',         '{}',                               '¼ unidad',             1,   0, 0, 0,   null, 43),
  ('carbo-044', 'carbohidratos', 'Vegetales harinosos', 'Elote',                          '{}',                               '15 cm',                1,   0, 0, 0,   null, 44),
  ('carbo-045', 'carbohidratos', 'Vegetales harinosos', 'Pejibaye',                       '{}',                               '1 unidad mediana',     1,   0, 0, 0,   null, 45),
  ('carbo-046', 'carbohidratos', 'Vegetales harinosos', 'Puré de papa, plátano u otro',   '{}',                               '½ taza',               1,   0, 0, 0,   null, 46),
  ('carbo-047', 'carbohidratos', 'Vegetales harinosos', 'Papas fritas',                   '{}',                               '16 unidades pequeñas', 1,   0, 0, 2,   null, 47),

  ('carbo-048', 'carbohidratos', 'Granolas', 'Granola en general, diferentes marcas',     '{}',                               '¼ taza',               1,   0, 0, 1,   null, 48),

  ('carbo-049', 'carbohidratos', 'Avenas', 'Avena tradicional o integral',                '{}',                               '¼ taza',               1,   0, 0, 0,   null, 49),
  ('carbo-050', 'carbohidratos', 'Avenas', 'Avena integral con proteína',                 array['Quaker'],                    '1/3 taza',             1,   0, 0, 0,   null, 50),
  ('carbo-051', 'carbohidratos', 'Avenas', 'Avena instantánea, cualquiera',               array['Quaker'],                    '45 g',               1.5,   0, 0.5, 0, null, 51),

  ('carbo-052', 'carbohidratos', 'Cereales', 'Cereal All Inklusive sin azúcar',           '{}',                               '¾ taza',               1,   0, 0, 0,   null, 52),
  ('carbo-053', 'carbohidratos', 'Cereales', 'Cereal Corn Flakes',                        array['Kellogg''s'],                '¾ taza',               1,   0, 0, 0,   null, 53),
  ('carbo-054', 'carbohidratos', 'Cereales', 'Cereales azucarados en general',            '{}',                               '½ taza',               1,   0, 0, 0,   null, 54),
  ('carbo-055', 'carbohidratos', 'Cereales', 'Cereales, diferentes variedades',           array['Special K'],                 '½ taza',               1,   0, 0, 0,   null, 55),

  ('carbo-056', 'carbohidratos', 'Dulces y chocolates', 'Miel de abeja o sirope de maple regular', '{}',                      '1 cucharada',          1,   0, 0, 0,   null, 56),
  ('carbo-057', 'carbohidratos', 'Dulces y chocolates', 'Jalea regular, azúcar regular',  '{}',                               '2 cucharadas',         1,   0, 0, 0,   null, 57),
  ('carbo-058', 'carbohidratos', 'Dulces y chocolates', 'Cocoa dulce',                    '{}',                               '2 cucharadas',         1,   0, 0, 0,   null, 58),
  ('carbo-059', 'carbohidratos', 'Dulces y chocolates', 'Leche condensada',               '{}',                               '2 cucharadas',         1,   0, 0, 0.5, null, 59),
  ('carbo-060', 'carbohidratos', 'Dulces y chocolates', 'Sirope de maple light',          array['Aunt Jemima'],               '2 cucharadas',         1,   0, 0, 0,   null, 60),
  ('carbo-061', 'carbohidratos', 'Dulces y chocolates', 'Marshmallows',                   '{}',                               '3 unidades',           1,   0, 0, 0,   null, 61),
  ('carbo-062', 'carbohidratos', 'Dulces y chocolates', 'Nutella',                        '{}',                               '1 cucharada',          1,   0, 0, 1,   null, 62),

  ('carbo-063', 'carbohidratos', 'Galletas', 'Galleta María',                             '{}',                               '1 paquete',            1,   0, 0, 0,   null, 63),
  ('carbo-064', 'carbohidratos', 'Galletas', 'Galletas Club',                             array['Gama'],                      '1 paquete',          1.5,   0, 0, 1,   null, 64),
  ('carbo-065', 'carbohidratos', 'Galletas', 'Galleta soda',                              '{}',                               '1 paquete',            1,   0, 0, 0,   null, 65),
  ('carbo-066', 'carbohidratos', 'Galletas', 'Galletas Club Social o boquitas',           array['Pozuelo'],                   '1 paquete',            1,   0, 0, 1,   null, 66),
  ('carbo-067', 'carbohidratos', 'Galletas', 'Galleta Club Social integral',              '{}',                               '1 paquete',            1,   0, 0, 0.5, null, 67),
  ('carbo-068', 'carbohidratos', 'Galletas', 'Galleta Yipy',                              array['Pozuelo'],                   '1 paquete',            1,   0, 0, 2,   null, 68),
  ('carbo-069', 'carbohidratos', 'Galletas', 'Galletas Canasta',                          array['Pozuelo'],                   '1 paquete',            1,   0, 0, 0.5, null, 69),
  ('carbo-070', 'carbohidratos', 'Galletas', 'Galletas Chiky, cremitas y mantequilla',    array['Pozuelo'],                   '1 paquete',          1.5,   0, 0, 1,   null, 70),
  ('carbo-071', 'carbohidratos', 'Galletas', 'Galletas de arroz integral',                array['Sanissimo'],                 '2 galletas',         0.5,   0, 0, 0,   null, 71),

  ('carbo-072', 'carbohidratos', 'Alimentos salados', 'Papas tostadas de bolsa',          array['Lay''s','Doritos'],          '1 bolsa pequeña',      1,   0, 0, 2,   null, 72),
  ('carbo-073', 'carbohidratos', 'Alimentos salados', 'Plátano verde con sal',            array['Pro'],                       '1 bolsita de 20 g',  0.5,   0, 0, 1,   null, 73),
  ('carbo-074', 'carbohidratos', 'Alimentos salados', 'Palomitas de maíz caseras sin grasa', '{}',                            '3 tazas',              1,   0, 0, 0,   null, 74),

  ('carbo-075', 'carbohidratos', 'Barras', 'Barra Protein Snack',                         array['Kellogg''s'],                '1 unidad',             1,   1, 0, 1,   null, 75),
  ('carbo-076', 'carbohidratos', 'Barras', 'Barra de cereal',                             array['Jack''s'],                   '1 unidad',             1,   0, 0, 0,   null, 76),
  ('carbo-077', 'carbohidratos', 'Barras', 'Barra de cereal Fruttal, naranja o dulce de leche', '{}',                         '1 unidad',             1,   0, 0, 0,   null, 77)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, l = excluded.l, g = excluded.g,
  nota = excluded.nota, orden = excluded.orden;
