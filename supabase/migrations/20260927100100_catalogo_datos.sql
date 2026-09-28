-- ---------------------------------------------------------------------------
-- Las plantillas que usa la clínica
-- ---------------------------------------------------------------------------
--
-- Transcritas de la lista del doctor. Reglas de la transcripción:
--
--   * Lo que estaba entre paréntesis son las opciones del hueco anterior.
--   * Un hueco sin opciones es un campo libre.
--   * Los "o" quedan como texto fijo dentro de la frase: no los elige el
--     doctor, los decide el paciente ("en ayunas o antes del ejercicio").
--   * Cafeína, zinc, melatonina, retatrutide y AOD pasan a **mg**. La lista
--     original decía gramos; en todos los casos era mil veces la dosis real.
--   * Los magnesios y el zinc llevan el rango escrito de entrada
--     ("400-800"), porque el doctor lo ajusta a mano y no elige de una lista.
--
-- `on conflict do update` para poder correr este archivo otra vez cuando la
-- lista cambie.

insert into catalogo_indicaciones
  (id, tipo, nombre, plantilla, campos, titulo, icono, libre, orden)
values

-- ---------------------------------------------------------------------------
-- Recomendaciones
-- ---------------------------------------------------------------------------

('rec-agua', 'recomendacion', 'Agua al día',
 'Tomar {litros} litros de agua al día',
 '[{"clave":"litros","etiqueta":"Litros","tipo":"numero"}]',
 'Hidratación', 'agua', false, 1),

('rec-liquido-noche', 'recomendacion', 'Líquidos antes de dormir',
 'Suspender la ingesta de líquido 2 horas antes de irse a dormir',
 '[]', 'Líquidos antes de dormir', 'sueno', false, 2),

('rec-sueno', 'recomendacion', 'Horas de sueño',
 'Dormir en promedio 7 horas',
 '[]', 'Horas de sueño', 'sueno', false, 3),

('rec-tazas', 'recomendacion', 'Tazas medidoras',
 'Utilizar tazas medidoras para servir carbohidratos',
 '[]', 'Medir los carbohidratos', 'alimentacion', false, 4),

('rec-pesar-proteina', 'recomendacion', 'Pesar la proteína',
 'Pesar la proteína cocinada',
 '[]', 'Pesar la proteína', 'proteina', false, 5),

('rec-embutidos', 'recomendacion', 'Sin embutidos',
 'No consumir embutidos',
 '[]', 'Sin embutidos', 'evitar', false, 6),

('rec-procesadas', 'recomendacion', 'Sin carnes procesadas',
 'No consumir carnes procesadas',
 '[]', 'Sin carnes procesadas', 'evitar', false, 7),

('rec-aceite', 'recomendacion', 'Aceite para cocinar',
 'Idealmente utilizar aceite de aguacate para cocinar (igualmente siguiendo recomendación sobre uso correcto del aceite)',
 '[]', 'Aceite para cocinar', 'alimentacion', false, 8),

('rec-hidratacion-ejercicio', 'recomendacion', 'Hidratación en el ejercicio',
 'Durante el ejercicio hidratarse constantemente, aparte de su requerimiento diario',
 '[]', 'Hidratación en el ejercicio', 'ejercicio', false, 9),

('rec-otra', 'recomendacion', 'Otra recomendación', '', '[]', null, 'consejo', true, 99),

-- ---------------------------------------------------------------------------
-- Suplementos
-- ---------------------------------------------------------------------------

('sup-creatina', 'suplemento', 'Creatina monohidratada',
 'Creatina Monohidratada {dosis} g en cualquier momento del día',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"g","tipo":"numero","opciones":[5,7.5,10,15,20]}]',
 null, null, false, 1),

('sup-omega3', 'suplemento', 'Omega 3',
 'Omega 3 {dosis} g al día, siempre con comidas con grasa saludable',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"g","tipo":"numero","opciones":[1.5,2,2.5,3,4]}]',
 null, null, false, 2),

('sup-vitd-k2', 'suplemento', 'Vitamina D / Vitamina K2',
 'Vitamina D / Vitamina K2 {dosis} UI siempre con el desayuno',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"UI","tipo":"numero","opciones":[5000,10000]}]',
 null, null, false, 3),

('sup-beta-alanina', 'suplemento', 'Beta alanina',
 'Beta Alanina {dosis} g al día en cualquier momento del día',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"g","tipo":"numero","opciones":[2,4,6]}]',
 null, null, false, 4),

('sup-remolacha', 'suplemento', 'Extracto de remolacha',
 'Extracto de remolacha 2 tabletas al día',
 '[]', null, null, false, 5),

('sup-mct', 'suplemento', 'Aceite MCT',
 'Aceite MCT {dosis} g al día en ayuno o preentrenamiento',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"g","tipo":"numero","opciones":[3,4,5,6]}]',
 null, null, false, 6),

('sup-mg-treonato', 'suplemento', 'L-Treonato de magnesio',
 'L-Treonato de Magnesio {dosis} mg antes de dormir',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"texto","valor":"400-800"}]',
 null, null, false, 7),

('sup-mg-glicinato', 'suplemento', 'Glicinato de magnesio',
 'Glicinato o Bisglicinato de Magnesio {dosis} mg antes de dormir',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"texto","valor":"400-800"}]',
 null, null, false, 8),

('sup-mg-citrato', 'suplemento', 'Citrato de magnesio',
 'Citrato de Magnesio {dosis} mg antes de dormir',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"texto","valor":"400-800"}]',
 null, null, false, 9),

('sup-probioticos', 'suplemento', 'Probióticos Synbiotic+',
 'Probióticos Synbiotic+ {capsulas} cápsula(s) 2 veces al día siempre con comidas',
 '[{"clave":"capsulas","etiqueta":"Cápsulas","tipo":"numero","opciones":[1,2]}]',
 null, null, false, 10),

('sup-melatonina', 'suplemento', 'Melatonina',
 'Melatonina {dosis} mg antes de dormir',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero","opciones":[10,15,20]}]',
 null, null, false, 11),

('sup-gaba', 'suplemento', 'GABA',
 'GABA 500 mg antes de dormir',
 '[]', null, null, false, 12),

('sup-ashwagandha', 'suplemento', 'Ashwagandha',
 'Ashwagandha {dosis} g antes de dormir',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"g","tipo":"numero","opciones":[0.5,1]}]',
 null, null, false, 13),

('sup-cafeina', 'suplemento', 'Cafeína',
 'Cafeína {dosis} mg antes del ejercicio',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero","opciones":[150,200,250,300]}]',
 null, null, false, 14),

('sup-curcuma', 'suplemento', 'Cúrcuma / pimienta negra',
 'Cúrcuma / pimienta negra 2 tabletas/cápsulas en la mañana',
 '[]', null, null, false, 15),

('sup-triptofano', 'suplemento', 'Triptófano',
 'Triptófano 1 g en cualquier momento del día',
 '[]', null, null, false, 16),

('sup-alfalipoico', 'suplemento', 'Ácido alfalipoico',
 'Ácido alfalipoico 1 g en cualquier momento del día',
 '[]', null, null, false, 17),

('sup-psyllium', 'suplemento', 'Fibra hidrosoluble (Psyllium)',
 'Fibra hidrosoluble (Psyllium) {dosis} g 2 veces al día',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"g","tipo":"numero","opciones":[5,10,15]}]',
 null, null, false, 18),

('sup-zinc', 'suplemento', 'Glicinato de zinc',
 'Glicinato de Zinc, zinc elemental {dosis} mg con comida',
 '[{"clave":"dosis","etiqueta":"Zinc elemental","unidad":"mg","tipo":"texto","valor":"15-30"}]',
 null, null, false, 19),

('sup-nac', 'suplemento', 'NAC',
 'NAC 600 mg {veces} veces al día, en cualquier momento del día',
 '[{"clave":"veces","etiqueta":"Veces al día","tipo":"numero","opciones":[2,3]}]',
 null, null, false, 20),

('sup-proteina', 'suplemento', 'Proteína en polvo',
 'Proteína en polvo de cualquier sabor {scoops} scoop al día',
 '[{"clave":"scoops","etiqueta":"Scoops","tipo":"numero","opciones":[1,1.5,2]}]',
 null, null, false, 21),

('sup-otro', 'suplemento', 'Otro suplemento', '', '[]', null, null, true, 99),

-- ---------------------------------------------------------------------------
-- Péptidos
-- ---------------------------------------------------------------------------

('pep-semaglutide', 'peptido', 'Semaglutide',
 'Semaglutide {dosis} mg a la semana',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero","opciones":[0.15,0.25,0.35,0.5,0.75,1,1.5,2,2.4]}]',
 null, null, false, 1),

('pep-tirzepatide', 'peptido', 'Tirzepatide',
 'Tirzepatide {dosis} mg a la semana',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero","opciones":[1,1.5,2.5,3.5,5,6,7.5,10,12.5,15]}]',
 null, null, false, 2),

('pep-retatrutide', 'peptido', 'Retatrutide',
 'Retatrutide {dosis} mg a la semana',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero","opciones":[1,2,3,4,5,6,7,8,9,10,11,12]}]',
 null, null, false, 3),

('pep-cjc-noche', 'peptido', 'CJC/Ipa — antes de dormir',
 'CJC/Ipa 10 unidades antes de dormir',
 '[]', null, null, false, 4),

('pep-cjc-dos-veces', 'peptido', 'CJC/Ipa — ayunas y noche',
 'CJC/Ipa 10 unidades en ayunas y 10 unidades antes de dormir',
 '[]', null, null, false, 5),

('pep-mots', 'peptido', 'MOTS',
 'MOTS {unidades} unidades {veces} veces por semana antes de entrenar o en la mañana por 4 semanas, dosis de {dosis} mg',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"},
   {"clave":"veces","etiqueta":"Veces por semana","tipo":"numero","opciones":[2,3]},
   {"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero","opciones":[2,3,5]}]',
 null, null, false, 6),

('pep-aod', 'peptido', 'AOD-9654',
 'AOD-9654 {unidades} U o {dosis} mg diaria en ayunas o antes del ejercicio por {semanas} semanas',
 '[{"clave":"unidades","etiqueta":"Unidades","unidad":"U","tipo":"numero"},
   {"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero","opciones":[0.25,0.5]},
   {"clave":"semanas","etiqueta":"Semanas","tipo":"numero","opciones":[4,8,12]}]',
 null, null, false, 7),

('pep-bpc157', 'peptido', 'BPC-157',
 'BPC-157 10 U en cualquier momento por día por 12 semanas',
 '[]', null, null, false, 8),

('pep-epithalon', 'peptido', 'Epithalon',
 'Epithalon {unidades} unidades antes de dormir por {dias} días, dosis de {dosis} mg',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"},
   {"clave":"dias","etiqueta":"Días","tipo":"numero","opciones":[10,20]},
   {"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero","opciones":[5,10]}]',
 null, null, false, 9),

('pep-ghk-cu', 'peptido', 'GHK-cu',
 'GHK-cu {unidades} unidades por día por {semanas} semanas, dosis de {dosis} mg',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"},
   {"clave":"semanas","etiqueta":"Semanas","tipo":"numero","opciones":[4,6,8]},
   {"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero"}]',
 null, null, false, 10),

('pep-glow', 'peptido', 'Glow',
 'Glow {unidades} unidades por día por 8 semanas, dosis de {dosis} mg',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"},
   {"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero"}]',
 null, null, false, 11),

('pep-pt141', 'peptido', 'PT-141',
 'PT-141 {disparos} disparo(s) por fosa nasal al menos 2 horas antes del acto sexual, no más de 1 uso en 24 h ni tampoco más de 3 usos por semana',
 '[{"clave":"disparos","etiqueta":"Disparos por fosa","tipo":"numero","opciones":[1,2]}]',
 null, null, false, 12),

('pep-tb500', 'peptido', 'TB-500',
 'TB-500 {unidades} unidades al día por {semanas} semanas, dosis de {dosis} mg',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"},
   {"clave":"semanas","etiqueta":"Semanas","tipo":"numero"},
   {"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"numero"}]',
 null, null, false, 13),

('pep-tesamorelin', 'peptido', 'Tesamorelin',
 'Tesamorelin {unidades} unidades por día por 10 días, descanso de 10 días, y continúa por otros 10 días',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"}]',
 null, null, false, 14),

('pep-thymosin', 'peptido', 'Thymosin alfa-1',
 'Thymosin alfa-1 {unidades} unidades por día por {semanas} semanas',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"},
   {"clave":"semanas","etiqueta":"Semanas","tipo":"numero"}]',
 null, null, false, 15),

('pep-semax', 'peptido', 'Semax',
 'Semax {unidades} unidades por día por 4 semanas',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"}]',
 null, null, false, 16),

('pep-selank', 'peptido', 'Selank',
 'Selank {unidades} unidades por día por 4 semanas',
 '[{"clave":"unidades","etiqueta":"Unidades","tipo":"numero"}]',
 null, null, false, 17),

('pep-semax-selank', 'peptido', 'Semax / Selank',
 'Semax/Selank {disparos} disparo(s) por fosa nasal por {semanas} semanas',
 '[{"clave":"disparos","etiqueta":"Disparos por fosa","tipo":"numero","opciones":[1,2]},
   {"clave":"semanas","etiqueta":"Semanas","tipo":"numero","opciones":[4,6,8,12]}]',
 null, null, false, 18),

('pep-dsip', 'peptido', 'DSIP',
 'DSIP {disparos} disparo(s) por fosa nasal por {semanas} semanas',
 '[{"clave":"disparos","etiqueta":"Disparos por fosa","tipo":"numero","opciones":[1,2]},
   {"clave":"semanas","etiqueta":"Semanas","tipo":"numero","opciones":[4,6,8,12]}]',
 null, null, false, 19),

('pep-nad', 'peptido', 'NAD+',
 'NAD+ {disparos} disparo(s) por fosa nasal por {semanas} semanas',
 '[{"clave":"disparos","etiqueta":"Disparos por fosa","tipo":"numero","opciones":[1,2]},
   {"clave":"semanas","etiqueta":"Semanas","tipo":"numero","opciones":[2,4,6,8,12]}]',
 null, null, false, 20),

('pep-otro', 'peptido', 'Otro péptido', '', '[]', null, null, true, 99),

-- ---------------------------------------------------------------------------
-- Medicamentos
-- ---------------------------------------------------------------------------

('med-femoston', 'medicamento', 'Femoston conti',
 'Femoston conti {dosis} mg 1 tableta por día a la misma hora',
 '[{"clave":"dosis","etiqueta":"Dosis","unidad":"mg","tipo":"opcion","opciones":["0.5/2.5","1/5","2/10","1/10"]}]',
 null, null, false, 1),

('med-metformina', 'medicamento', 'Metformina',
 'Metformina {indicacion}',
 '[{"clave":"indicacion","etiqueta":"Indicación","tipo":"texto"}]',
 null, null, false, 2),

('med-levotiroxina', 'medicamento', 'Levotiroxina',
 'Levotiroxina {indicacion}',
 '[{"clave":"indicacion","etiqueta":"Indicación","tipo":"texto"}]',
 null, null, false, 3),

('med-ibp', 'medicamento', 'Omeprazol / Esomeprazol / Lansoprazol',
 '{farmaco} 1 tableta en ayunas por {dias} días',
 '[{"clave":"farmaco","etiqueta":"Cuál","tipo":"opcion","opciones":["Omeprazol","Esomeprazol","Lansoprazol"]},
   {"clave":"dias","etiqueta":"Días","tipo":"numero"}]',
 null, null, false, 4),

('med-otro', 'medicamento', 'Otro medicamento', '', '[]', null, null, true, 99)

on conflict (id) do update
  set tipo      = excluded.tipo,
      nombre    = excluded.nombre,
      plantilla = excluded.plantilla,
      campos    = excluded.campos,
      titulo    = excluded.titulo,
      icono     = excluded.icono,
      libre     = excluded.libre,
      orden     = excluded.orden,
      activo    = true;

-- ---------------------------------------------------------------------------
-- Analitos
-- ---------------------------------------------------------------------------

insert into catalogo_analitos (id, nombre, unidad, orden) values
  ('lab-hemoglobina',    'Hemoglobina',         'g/dl',    1),
  ('lab-hematocrito',    'Hematocrito',         '%',       2),
  ('lab-glucosa',        'Glucosa en ayunas',   'mg/dl',   3),
  ('lab-glicada',        'Hemoglobina glicada',  '%',       4),
  ('lab-creatinina',     'Creatinina sérica',   'mg/dl',   5),
  ('lab-nitrogeno',      'Nitrógeno ureico',    'mg/dl',   6),
  ('lab-ast',            'AST',                 'UI/L',    7),
  ('lab-alt',            'ALT',                 'UI/L',    8),
  ('lab-ggt',            'GGT',                 'U/L',     9),
  ('lab-fosfatasa',      'Fosfatasa alcalina',  'U/L',    10),
  ('lab-trigliceridos',  'Triglicéridos',       'mg/dl',  11),
  ('lab-colesterol',     'Colesterol total',    'mg/dl',  12),
  ('lab-ldl',            'LDL',                 'mg/dl',  13),
  ('lab-hdl',            'HDL',                 'mg/dl',  14),
  ('lab-apo-a1',         'Apo A1',              '',       15),
  ('lab-apo-b',          'Apo B',               '',       16),
  ('lab-tsh',            'TSH',                 'uUI/ml', 17),
  ('lab-vitamina-d',     'Vitamina D',          'ng/ml',  18),
  ('lab-homocisteina',   'Homocisteína',        'umol/L', 19),
  ('lab-ferritina',      'Ferritina',           'ng/ml',  20),
  ('lab-vitamina-b12',   'Vitamina B12',        'pg/ml',  21)
on conflict (id) do update
  set nombre = excluded.nombre,
      unidad = excluded.unidad,
      orden  = excluded.orden,
      activo = true;
