-- Catálogo del libro, parte 3: proteínas, grasas y bebidas.

-- ---------------------------------------------------------------------------
-- Proteínas
--
-- El "*" del libro en las comidas compuestas queda como grasa_variable: la
-- grasa depende de cómo se cocinó el platillo, así que no hay número fijo.
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, p, v, g, grasa_variable, orden) values
  ('prot-001', 'proteinas', null, 'Pescados blancos (corvina, tilapia, pargo)', '{}', '120 g',            0, 3, 0, 0, false,  1),
  ('prot-002', 'proteinas', null, 'Salmón, trucha y atún fresco',              '{}', '90 g',             0, 3, 0, 0, false,  2),
  ('prot-003', 'proteinas', null, 'Camarones jumbo',                           '{}', '4 unidades',       0, 3, 0, 0, false,  3),
  ('prot-004', 'proteinas', null, 'Camarones, mejillones pequeños',            '{}', '4 unidades',       0, 1, 0, 0, false,  4),
  -- "1 unidad" en el PDF: son latas. Una sardina suelta no da 60 g de
  -- proteína, y las dos filas de atún vienen con la misma abreviatura.
  ('prot-005', 'proteinas', null, 'Sardinas',                                  '{}', '1 lata',           0, 2, 0, 1, false,  5),
  ('prot-006', 'proteinas', null, 'Ceviche de pescado, camarones, pulpo',      '{}', '1 taza',           0, 3, 0, 0, false,  6),
  ('prot-007', 'proteinas', null, 'Atún en agua',                              '{}', '1 lata',           0, 3, 0, 0, false,  7),
  ('prot-008', 'proteinas', null, 'Atún en aceite',                            '{}', '1 lata',           0, 3, 0, 1, false,  8),
  ('prot-009', 'proteinas', null, 'Res, pollo y cerdo',                        '{}', '30 g',             0, 1, 0, 0, false,  9),

  ('prot-010', 'proteinas', 'Comidas compuestas', 'Arroz con pollo o mariscos', '{}', '1 taza',          2, 1, 0, 0, true,  10),
  ('prot-011', 'proteinas', 'Comidas compuestas', 'Garbanzos con pollo o cerdo', '{}', '½ taza',       0.5, 0.5, 0, 0, false, 11),
  ('prot-012', 'proteinas', 'Comidas compuestas', 'Picadillo de vegetales no harinosos con carne', '{}', '½ taza', 0, 1, 1, 0, true, 12),
  ('prot-013', 'proteinas', 'Comidas compuestas', 'Picadillo de vegetales harinosos con carne', '{}', '½ taza', 1, 1, 0, 0, true, 13),
  ('prot-014', 'proteinas', 'Comidas compuestas', 'Tamal regular',             '{}', '1 unidad',         3, 1, 0, 4, false, 14),
  ('prot-015', 'proteinas', 'Comidas compuestas', 'Huevo',                     '{}', '1 unidad',         0, 1, 0, 0, false, 15),
  ('prot-016', 'proteinas', 'Comidas compuestas', 'Jamón de pollo, cerdo o pavo 98% bajo en grasa', '{}', '30 g', 0, 1, 0, 0, false, 16)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, v = excluded.v, g = excluded.g,
  grasa_variable = excluded.grasa_variable, orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Grasas
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, g, nota, orden) values
  ('grasa-001', 'grasas', null, 'Aceite de oliva',        array['Salat'], '1 cucharadita',                        1, null,  1),
  ('grasa-002', 'grasas', null, 'Aguacate',               '{}',           '1 cucharada (pequeño ¼, grande 1/8)',  1, null,  2),
  ('grasa-003', 'grasas', null, 'Semillas mixtas',        '{}',           'La medida del puño',                   1, null,  3),
  ('grasa-004', 'grasas', null, 'Aceite de cocina',       '{}',           'Más de 3 segundos',                    1,
   '1 grasa o más, según cuánto se use.',                                                                                  4),
  ('grasa-005', 'grasas', null, 'Mantequilla de maní',    '{}',           '2 cucharaditas',                       1, null,  5),
  ('grasa-006', 'grasas', null, 'Almendras enteras',      '{}',           '7 unidades',                           1, null,  6),

  ('grasa-007', 'grasas', 'Grasas poliinsaturadas', 'Aceite de soya y girasol',            '{}', '1 cucharadita',  1, null,  7),
  ('grasa-008', 'grasas', 'Grasas poliinsaturadas', 'Aderezo regular',                     '{}', '2 cucharaditas', 1, null,  8),
  ('grasa-009', 'grasas', 'Grasas poliinsaturadas', 'Aderezo reducido en grasa',           '{}', '1 cucharada',    1, null,  9),
  ('grasa-010', 'grasas', 'Grasas poliinsaturadas', 'Margarina light',                     '{}', '1 cucharada',    1, null, 10),
  ('grasa-011', 'grasas', 'Grasas poliinsaturadas', 'Mayonesa light',                      '{}', '1.5 cucharadas', 1, null, 11),
  ('grasa-012', 'grasas', 'Grasas poliinsaturadas', 'Mayonesa regular',                    '{}', '1 cucharadita',  1, null, 12),
  ('grasa-013', 'grasas', 'Grasas poliinsaturadas', 'Queso crema regular o deslactosado',  '{}', '1 cucharada',    1, null, 13),
  ('grasa-014', 'grasas', 'Grasas poliinsaturadas', 'Queso crema light',                   '{}', '5 cucharaditas', 1, null, 14),
  ('grasa-015', 'grasas', 'Grasas poliinsaturadas', 'Natilla regular',                     '{}', '2 cucharadas',   1, null, 15),
  ('grasa-016', 'grasas', 'Grasas poliinsaturadas', 'Tocino cocido',                       '{}', '1 rebanada',     1, null, 16),
  ('grasa-017', 'grasas', 'Grasas poliinsaturadas', 'Paté',                                '{}', '1 cucharada',    1, null, 17),
  ('grasa-018', 'grasas', 'Grasas poliinsaturadas', 'Dips',                    array['Dos Pinos'], '1 cucharada',  2, null, 18)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  g = excluded.g, nota = excluded.nota, orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Bebidas alcohólicas
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, nombre, marcas, porcion, c, f, g, orden) values
  ('alco-001', 'bebidas-alco', 'Cerveza light',                                        '{}',           '350 ml',      0.5, 0, 1.5,  1),
  ('alco-002', 'bebidas-alco', 'Cerveza Ultra',                          array['Imperial'],           '350 ml',        0, 0,   2,  2),
  ('alco-003', 'bebidas-alco', 'Cerveza Cero',                           array['Imperial'],           '350 ml',      0.5, 0,   0,  3),
  ('alco-004', 'bebidas-alco', 'Adán y Eva, cualquier sabor',                          '{}',         '1 unidad',        1, 0,   1,  4),
  ('alco-005', 'bebidas-alco', 'Cerveza regular',                                      '{}',           '350 ml',        1, 0,   2,  5),
  ('alco-006', 'bebidas-alco', 'Cerveza artesanal',                                    '{}',           '350 ml',        1, 0, 2.5,  6),
  ('alco-007', 'bebidas-alco', 'Smirnoff Ice',                                         '{}',           '350 ml',        2, 0,   2,  7),
  ('alco-008', 'bebidas-alco', 'Baileys',                                              '{}',            '60 ml',        1, 0,   2,  8),
  ('alco-009', 'bebidas-alco', 'Piña colada',                                          '{}',           '120 ml',        2, 0,   1,  9),
  ('alco-010', 'bebidas-alco', 'Daiquirí',                                             '{}',            '75 ml',      1.5, 0.5, 2, 10),
  ('alco-011', 'bebidas-alco', 'Martini',                                              '{}',           '1 copa',        1, 0,   2, 11),
  ('alco-012', 'bebidas-alco', 'Champagne',                                            '{}',           '180 ml',        0, 0,   2, 12),
  ('alco-013', 'bebidas-alco', 'Gin tonic',                                            '{}',           '1 vaso',        1, 0,   2, 13),
  ('alco-014', 'bebidas-alco', 'Whisky, vodka, ginebra, ron, guaro, tequila',          '{}',            '45 ml',        0, 0,   2, 14),
  ('alco-015', 'bebidas-alco', 'Vino tinto o blanco',                                  '{}',           '150 ml',        0, 0,   2, 15),
  ('alco-016', 'bebidas-alco', 'Sangría, margarita, mojito, tequila sunrise, caipiriña, bloody mary', '{}', '150 ml',   1, 0,   2, 16),
  ('alco-017', 'bebidas-alco', 'Vino espumante',                                       '{}',           '150 ml',        0, 0,   2, 17),
  -- El PDF no les pone medida, pero las otras tres filas de vino son de 150 ml.
  ('alco-018', 'bebidas-alco', 'Vino chardonnay',                                      '{}',           '150 ml',        0, 0,   2, 18),
  ('alco-019', 'bebidas-alco', 'Vino rosado',                                          '{}',           '150 ml',        0, 0,   2, 19)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, nombre = excluded.nombre,
  marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, f = excluded.f, g = excluded.g, orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Bebidas no alcohólicas
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, nombre, marcas, porcion, c, f, orden) values
  ('sinalco-001', 'bebidas-sin-alco', 'Hi-C',                                     '{}',                          '250 ml',   2,   0, 1),
  ('sinalco-002', 'bebidas-sin-alco', 'Bebidas energéticas y gaseosas regulares',  '{}',                          '250 ml', 1.5,   0, 2),
  ('sinalco-003', 'bebidas-sin-alco', 'Agua mineral saborizada',   array['San Pellegrino'],                     '1 unidad',   2,   0, 3),
  ('sinalco-004', 'bebidas-sin-alco', 'Té blanco, rojo y negro',        array['Dos Pinos'],                        '500 ml', 0.5,   0, 4),
  ('sinalco-005', 'bebidas-sin-alco', 'Té frío limón o melocotón',      array['Dos Pinos'],                        '500 ml',   1,   0, 5),
  ('sinalco-006', 'bebidas-sin-alco', 'Bebidas de té',                   array['Tropical'],                       '500 ml', 1.5,   0, 6),
  ('sinalco-007', 'bebidas-sin-alco', 'Té limón, melocotón y herbal',    array['Fuze Tea'],                        '500 ml',   2,   0, 7),
  ('sinalco-008', 'bebidas-sin-alco', 'Bebida de frutas',                array['Tropical'],                        '350 ml', 0.5, 0.5, 8),
  ('sinalco-009', 'bebidas-sin-alco', 'Bebida de aloe',      array['Dos Pinos', 'Vita Aloe'],                      '250 ml',   1,   0, 9)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, nombre = excluded.nombre,
  marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, f = excluded.f, orden = excluded.orden;
