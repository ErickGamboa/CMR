-- ---------------------------------------------------------------------------
-- Catálogo de indicaciones: lo que el doctor receta, como plantillas
-- ---------------------------------------------------------------------------
--
-- Hasta acá recetar era escribir todo a mano en cuatro campos. Pero lo que el
-- doctor indica no es texto libre: es una lista corta de frases fijas con
-- huecos, y los huecos casi siempre tienen valores sugeridos.
--
--     Creatina Monohidratada ___g en cualquier momento del día  (5, 7.5, 10…)
--                            └hueco┘                            └─opciones─┘
--
-- Guardar esa estructura permite que atender sea tocar una ficha y apretar un
-- botón, en vez de escribir la misma frase por centésima vez.
--
-- Va en la base y no en el código para que el doctor pueda agregar un
-- suplemento nuevo sin que nadie publique una versión de la app.

-- ---------------------------------------------------------------------------
-- Las plantillas
-- ---------------------------------------------------------------------------

create table if not exists catalogo_indicaciones (
  id        text primary key,

  tipo      text not null check (tipo in (
              'recomendacion', 'suplemento', 'peptido', 'medicamento')),

  -- Con qué se busca y qué dice la ficha antes de abrirla.
  nombre    text not null,

  -- La frase, con los huecos entre llaves: "Creatina {dosis} g al día".
  -- Lo que no está entre llaves es texto fijo, incluidos los "o" que decide
  -- el paciente ("en ayunas o antes del ejercicio").
  plantilla text not null,

  -- Un objeto por hueco, en el orden en que se llenan:
  --   clave    cómo se llama dentro de la plantilla
  --   etiqueta lo que se lee arriba del control
  --   tipo     'numero' | 'texto' | 'opcion'
  --   unidad   se muestra al lado de los botones (g, mg, UI…)
  --   opciones los valores sugeridos; si no hay, es un campo libre
  --   valor    lo que viene escrito de entrada
  campos    jsonb not null default '[]'::jsonb,

  -- Solo para recomendaciones: la app las muestra con título e ícono.
  titulo    text,
  icono     text,

  -- El "espacio para otro no usual" de cada categoría: no tiene plantilla,
  -- abre los campos en blanco.
  libre     boolean not null default false,

  orden     smallint not null,
  activo    boolean not null default true
);

create index if not exists catalogo_indicaciones_tipo_idx
  on catalogo_indicaciones (tipo, orden) where activo;

comment on table catalogo_indicaciones is
  'Plantillas de lo que el doctor receta. El doctor elige una y llena los huecos.';

-- ---------------------------------------------------------------------------
-- Los analitos de laboratorio
-- ---------------------------------------------------------------------------
--
-- Nombre y unidad fijos: el doctor solo escribe el valor de los que tenga.
-- Sin rango de referencia, por decisión de la clínica.

create table if not exists catalogo_analitos (
  id      text primary key,
  nombre  text not null,
  unidad  text not null default '',
  orden   smallint not null,
  activo  boolean not null default true
);

comment on table catalogo_analitos is
  'Los analitos que la clínica mide. Sin rangos: la app no los muestra.';

-- ---------------------------------------------------------------------------
-- De qué plantilla salió cada cosa recetada
-- ---------------------------------------------------------------------------
--
-- Se guarda además del texto ya armado, no en su lugar: la app sigue leyendo
-- la frase y no se entera de nada. Esto es para poder reabrir una receta en el
-- sitio y corregir un número sin volver a escribirla.

alter table prescripciones
  add column if not exists plantilla_id text references catalogo_indicaciones(id),
  add column if not exists valores jsonb;

alter table recomendaciones
  add column if not exists plantilla_id text references catalogo_indicaciones(id),
  add column if not exists valores jsonb;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
--
-- El catálogo es herramienta del doctor: el paciente nunca lo lee, porque lo
-- que a él le llega es la frase ya armada dentro de su receta.

alter table catalogo_indicaciones enable row level security;
alter table catalogo_analitos     enable row level security;

drop policy if exists catalogo_indicaciones_doctor on catalogo_indicaciones;
create policy catalogo_indicaciones_doctor on catalogo_indicaciones
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists catalogo_analitos_doctor on catalogo_analitos;
create policy catalogo_analitos_doctor on catalogo_analitos
  for all to authenticated using (es_doctor()) with check (es_doctor());

-- ---------------------------------------------------------------------------
-- Un ícono más
-- ---------------------------------------------------------------------------
--
-- "No consumir embutidos" y "No consumir carnes procesadas" necesitan un
-- ícono de prohibido, que no existía. Va también en lib/core/iconos.dart: el
-- nombre sin el glifo del otro lado no dibuja nada.

insert into iconos (nombre, etiqueta, grupo, orden) values
  ('evitar', 'Evitar / no consumir', 'recomendacion', 11)
on conflict (nombre) do update
  set etiqueta = excluded.etiqueta,
      grupo    = excluded.grupo,
      orden    = excluded.orden;
