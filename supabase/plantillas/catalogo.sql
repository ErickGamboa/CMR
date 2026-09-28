-- Catálogo público: marcas de suplementos y videos.
--
-- Es el mismo para todos los pacientes, así que esto se corre una vez y se
-- corrige cuando el doctor cambie de opinión. No lleva `paciente_id`.
--
-- Mientras el sitio admin no exista, se pega en el SQL Editor de Supabase.

-- ---------------------------------------------------------------------------
-- Tipos de suplemento
-- ---------------------------------------------------------------------------
--
-- El `icono` sale del catálogo cerrado de lib/core/iconos.dart. Los que
-- aplican acá: suplemento, proteina_polvo, creatina, omega, vitamina,
-- magnesio, fibra, probiotico. Un nombre que no esté en la lista no rompe
-- nada: sale el ícono genérico.

insert into suplemento_categorias (id, nombre, icono, orden) values
  ('proteina',  'Proteína',    'proteina_polvo', 1),
  ('creatina',  'Creatina',    'creatina',       2),
  ('omega3',    'Omega 3',     'omega',          3),
  ('vitd3',     'Vitamina D3', 'vitamina',       4),
  ('magnesio',  'Magnesio',    'magnesio',       5)
on conflict (id) do update
  set nombre = excluded.nombre,
      icono  = excluded.icono,
      orden  = excluded.orden;

-- ---------------------------------------------------------------------------
-- Marcas recomendadas
-- ---------------------------------------------------------------------------
--
-- OJO: acá van marcas reales, y en la app se presentan como "recomendadas por
-- tu doctor". Poner una marca es respaldarla con el nombre de la clínica, así
-- que esta lista la define el doctor y nadie más.

delete from suplemento_marcas where categoria_id in
  ('proteina', 'creatina', 'omega3', 'vitd3', 'magnesio');

insert into suplemento_marcas (categoria_id, nombre, presentacion, orden) values
  ('proteina', 'MARCA PENDIENTE', 'Presentación pendiente', 1);
  -- ('proteina', 'Nombre real', 'Bote 900 g', 2),
  -- ('creatina', 'Nombre real', 'Bote 300 g', 1),
  -- ...

-- ---------------------------------------------------------------------------
-- Videos
-- ---------------------------------------------------------------------------
--
-- La app no los reproduce adentro: abre la URL en YouTube, en el navegador o
-- en lo que corresponda. Despublicar en vez de borrar conserva el enlace por
-- si se vuelve a usar.
--
-- Los que graba la clínica viven en el bucket público `videos` de Supabase
-- Storage. Antes de subirlos hay que convertirlos, porque lo que sale del
-- iPhone no sirve para esto: viene en HEVC dentro de un .mov y con el índice
-- al final del archivo, así que el teléfono del paciente lo baja completo
-- antes de mostrar el primer cuadro, y en varios Android no se ve del todo.
--
--   ffmpeg -i entrada.mov -c:v libx264 -preset slow -crf 23 \
--          -profile:v high -pix_fmt yuv420p -c:a aac -b:a 128k \
--          -movflags +faststart salida.mp4
--
-- `+faststart` es lo que pone el índice adelante. Para uno largo conviene dos
-- pasadas con `-b:v 2900k` en vez de `-crf`, que deja el tamaño predecible:
-- el plan gratis rechaza cualquier archivo de más de 50 MB.

insert into videos (titulo, descripcion, url, orden, publicado) values
  ('Video de prueba', 'Se reemplaza cuando lleguen los oficiales.',
   'https://www.youtube.com/watch?v=CAMBIAR', 1, true);

-- Despublicar uno:
-- update videos set publicado = false where titulo = 'Video de prueba';
