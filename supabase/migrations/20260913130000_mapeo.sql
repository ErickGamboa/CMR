-- ---------------------------------------------------------------------------
-- Módulo Mapeo: presión arterial y glisemia del paciente
-- ---------------------------------------------------------------------------
--
-- El paciente anota lo que le da el aparato en casa. Los valores van como
-- texto y no como número a propósito: la gente escribe "120/80", "120-80",
-- "95 mg/dL" o "alta, me la repetí" y el doctor quiere leer exactamente eso.
-- Interpretarlo es tarea de quien lo revisa, no de la app.

-- ---------------------------------------------------------------------------
-- Qué módulos ve cada paciente
-- ---------------------------------------------------------------------------
--
-- Tabla genérica y no una columna por módulo: mañana el doctor va a querer
-- prender o apagar otra cosa y eso no debería pedir una migración. Un módulo
-- sin fila está apagado; el doctor lo prende desde el sitio admin (o, por
-- ahora, a mano desde el panel de Supabase).

create table if not exists pacientes_modulos (
  paciente_id  uuid not null references auth.users(id) on delete cascade,
  modulo       text not null,
  habilitado   boolean not null default true,
  creado_en    timestamptz not null default now(),

  primary key (paciente_id, modulo)
);

comment on table pacientes_modulos is
  'Módulos opcionales habilitados por paciente. Sin fila = apagado.';

-- ---------------------------------------------------------------------------
-- Registros
-- ---------------------------------------------------------------------------

create table if not exists mapeo_registros (
  id               uuid primary key default gen_random_uuid(),
  paciente_id      uuid not null default auth.uid()
                     references auth.users(id) on delete cascade,

  tipo             text not null check (tipo in ('presion', 'glisemia')),
  fecha            date not null default current_date,

  -- Las tres casillas del día, tal como en la hoja del doctor. La del medio
  -- no tiene nombre: en el papel es solo un "*", la medición suelta que el
  -- paciente se tomó a cualquier hora.
  ayunas           text,
  libre            text,
  antes_de_dormir  text,

  creado_en        timestamptz not null default now(),
  actualizado_en   timestamptz not null default now(),

  -- Una sola fila por día y por tipo: el paciente edita la del día, no
  -- acumula varias.
  constraint mapeo_registros_uno_por_dia unique (paciente_id, tipo, fecha),

  -- Guardar las tres casillas vacías es borrar, no registrar.
  constraint mapeo_registros_algo_anotado check (
    coalesce(ayunas, '') <> ''
    or coalesce(libre, '') <> ''
    or coalesce(antes_de_dormir, '') <> ''
  )
);

create index if not exists mapeo_registros_paciente_idx
  on mapeo_registros (paciente_id, tipo, fecha desc);

comment on table mapeo_registros is
  'Presión arterial y glisemia anotadas por el paciente, una fila por día.';

create or replace function mapeo_marcar_actualizado()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

drop trigger if exists mapeo_registros_actualizado on mapeo_registros;
create trigger mapeo_registros_actualizado
  before update on mapeo_registros
  for each row execute function mapeo_marcar_actualizado();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table pacientes_modulos enable row level security;
alter table mapeo_registros   enable row level security;

-- Qué módulos tiene prendidos lo decide el doctor; el paciente solo lo lee.
drop policy if exists pacientes_modulos_propios on pacientes_modulos;
create policy pacientes_modulos_propios on pacientes_modulos
  for select to authenticated using (paciente_id = auth.uid());

-- Los registros sí los escribe el paciente, y solo los suyos.
drop policy if exists mapeo_registros_propios on mapeo_registros;
create policy mapeo_registros_propios on mapeo_registros
  for all to authenticated
  using (paciente_id = auth.uid())
  with check (paciente_id = auth.uid());
