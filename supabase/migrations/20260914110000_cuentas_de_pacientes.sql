-- ---------------------------------------------------------------------------
-- Cuentas de pacientes: registro propio + aprobación del doctor
-- ---------------------------------------------------------------------------
--
-- Hasta acá las cuentas las creaba alguien a mano en el panel de Supabase y
-- toda cuenta con sesión era, por definición, un paciente de la clínica.
--
-- Ahora el paciente se registra solo desde la app. Eso rompe esa suposición:
-- entre "tiene cuenta" y "es paciente de la clínica" ya no hay igualdad, y la
-- diferencia la marca el doctor aprobando.
--
-- De ahí salen las tres piezas de este archivo:
--
--   1. `pacientes.estado`: pendiente → activo, y el doctor decide.
--   2. Un disparador sobre `auth.users` que le crea la ficha a quien se
--      registre, para que aparezca en la bandeja del doctor sin que la app
--      tenga que acordarse de avisar.
--   3. El catálogo deja de ser "para cualquiera con sesión" y pasa a ser para
--      pacientes aprobados. Si no, registrarse sería suficiente para llevarse
--      el libro de intercambios completo.

-- ---------------------------------------------------------------------------
-- 1. La ficha: nombre y apellidos aparte, correo, y estado
-- ---------------------------------------------------------------------------

-- El índice viejo depende de las dos columnas que van a cambiar.
drop index if exists pacientes_activos_idx;

alter table pacientes
  -- Separados porque una clínica ordena y busca por apellido, no por nombre.
  add column if not exists nombre      text,
  add column if not exists apellidos   text,

  -- Denormalizado a propósito: `auth.users` no se puede consultar desde el
  -- cliente, así que sin esto la lista del doctor no podría mostrar el correo
  -- sin pasar por la Admin API en cada carga. Lo mantiene sincronizado el
  -- disparador de abajo y el sitio cuando cambia un correo.
  add column if not exists correo      text,

  add column if not exists estado      text not null default 'pendiente'
    check (estado in ('pendiente', 'activo', 'inactivo')),

  add column if not exists aprobado_en  timestamptz,
  add column if not exists aprobado_por uuid references auth.users(id);

-- Lo que ya existe lo creó el doctor a mano, así que ya está aprobado. El
-- nombre viejo era el correo entero; queda como nombre provisional.
update pacientes
   set nombre = coalesce(nombre, nombre_completo),
       estado = case when activo then 'activo' else 'inactivo' end,
       aprobado_en = coalesce(aprobado_en, creado_en)
 where nombre is null;

alter table pacientes alter column nombre set not null;

-- `nombre_completo` pasa de columna escrita a columna calculada: tenerla a
-- mano se presta a que quede diciendo algo distinto que nombre + apellidos.
alter table pacientes drop column if exists nombre_completo;
alter table pacientes
  add column nombre_completo text
  generated always as (
    trim(both ' ' from nombre || ' ' || coalesce(apellidos, ''))
  ) stored;

alter table pacientes drop column if exists activo;

create index if not exists pacientes_por_estado_idx
  on pacientes (estado, apellidos, nombre);

comment on column pacientes.estado is
  'pendiente = se registró solo y espera al doctor. activo = aprobado.';

-- ---------------------------------------------------------------------------
-- 2. Quién es un paciente aprobado
-- ---------------------------------------------------------------------------

create or replace function es_paciente_activo()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from pacientes p
     where p.user_id = auth.uid() and p.estado = 'activo'
  );
$$;

comment on function es_paciente_activo() is
  'True si la sesión es de un paciente aprobado por el doctor.';

-- ---------------------------------------------------------------------------
-- 3. La ficha se crea sola al registrarse
-- ---------------------------------------------------------------------------
--
-- Va en un disparador y no en la app a propósito: si dependiera de que la app
-- llame a algo después del registro, una app que se cierre en el momento justo
-- dejaría una cuenta sin ficha, invisible para el doctor y sin forma de
-- aprobarla.
--
-- Los datos vienen del `options.data` del `signUp`, que Supabase guarda en
-- `raw_user_meta_data`.

create or replace function registrar_paciente()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Un doctor no es paciente de sí mismo.
  if exists (select 1 from doctores d where d.user_id = new.id) then
    return new;
  end if;

  insert into pacientes (user_id, nombre, apellidos, cedula, correo, estado)
  values (
    new.id,
    -- Sin nombre en el registro, el correo sirve de provisional: mejor que
    -- una fila en blanco que el doctor no sabe a quién pertenece.
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'nombre'), ''), new.email),
    nullif(trim(new.raw_user_meta_data ->> 'apellidos'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'cedula'), ''),
    new.email,
    'pendiente'
  )
  on conflict (user_id) do nothing;

  return new;

exception
  when unique_violation then
    -- Solo puede ser la cédula: alguien que ya tiene cuenta intentando abrir
    -- otra. Cortar el registro es lo correcto, pero con un mensaje que la app
    -- pueda mostrar en vez de un error de Postgres.
    raise exception 'Esa cédula ya tiene una cuenta registrada.'
      using errcode = 'unique_violation';
end;
$$;

drop trigger if exists al_crear_usuario on auth.users;
create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function registrar_paciente();

-- ---------------------------------------------------------------------------
-- 4. El paciente aprueba su propia ficha: no
-- ---------------------------------------------------------------------------
--
-- La política de lectura del paciente ya existe. Lo que NO hay —ni va a
-- haber— es una de escritura para él: si el paciente pudiera hacer `update`
-- sobre su fila, se aprobaría solo y la aprobación no serviría de nada.
-- Escribir `pacientes` es exclusivo del doctor, por `pacientes_doctor`.

-- ---------------------------------------------------------------------------
-- 5. El catálogo, solo para pacientes aprobados
-- ---------------------------------------------------------------------------
--
-- Antes era `using (true)`: cualquiera con sesión lo leía. Cuando las cuentas
-- las creaba la clínica eso era lo mismo que "cualquier paciente". Con
-- registro abierto ya no: bastaría con registrarse para llevarse el libro de
-- intercambios completo, que es trabajo de la clínica.

drop policy if exists libro_secciones_lectura on libro_secciones;
create policy libro_secciones_lectura on libro_secciones
  for select to authenticated
  using (es_paciente_activo() or es_doctor());

drop policy if exists libro_alimentos_lectura on libro_alimentos;
create policy libro_alimentos_lectura on libro_alimentos
  for select to authenticated
  using (estado = 'publicado' and (es_paciente_activo() or es_doctor()));

drop policy if exists suplemento_categorias_lectura on suplemento_categorias;
create policy suplemento_categorias_lectura on suplemento_categorias
  for select to authenticated
  using (es_paciente_activo() or es_doctor());

drop policy if exists suplemento_marcas_lectura on suplemento_marcas;
create policy suplemento_marcas_lectura on suplemento_marcas
  for select to authenticated
  using (es_paciente_activo() or es_doctor());

drop policy if exists videos_lectura on videos;
create policy videos_lectura on videos
  for select to authenticated
  using (publicado and (es_paciente_activo() or es_doctor()));

-- El catálogo de íconos se queda abierto: son nombres de ícono, no contenido
-- de la clínica, y el sitio los necesita para dibujar sus desplegables.
