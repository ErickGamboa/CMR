# CMR — Panel del doctor

Sitio de administración de la Clínica COSME - CMR. Desde acá el doctor maneja
lo que cada paciente ve en la app.

Next.js 16 (App Router) + TypeScript + Tailwind 4 + shadcn/ui, contra el mismo
Supabase que la app Flutter.

## Configuración

```bash
cp .env.example .env.local
```

Y poné ahí la URL y la clave publicable del proyecto — las mismas que usa la app
en `config/supabase.json`.

**Nunca pongas la clave `service_role`.** Se salta RLS por completo, y el sitio
está construido a propósito para no necesitarla: el doctor escribe con su
propia sesión y es la base la que decide qué puede tocar.

## Correr

```bash
npm install
npm run dev
```

Abre en http://localhost:3000 y redirige a `/ingresar`.

Para entrar hace falta una cuenta que **además** tenga fila en la tabla
`doctores`. Si entrás con una cuenta de paciente, el sitio lo dice en vez de
dejarte adentro sin datos. El alta se hace con
`supabase/plantillas/alta_doctor_y_pacientes.sql`.

## Cómo está armado

```
src/
  proxy.ts              refresca la sesión y manda al login a quien no la tenga
  lib/supabase/         clientes de servidor y de navegador
  lib/doctor.ts         quién es el doctor de la sesión
  app/
    ingresar/           login (no hay registro: las cuentas las crea el doctor)
    (panel)/            todo lo que exige ser doctor
      pacientes/        la lista
```

Dos puertas, a propósito:

1. **`proxy.ts`** corre antes de cada petición, refresca el token de Supabase
   —si no, el doctor quedaría deslogueado a media jornada— y manda al login a
   quien no tenga sesión. Es un chequeo optimista, nada más.
2. **`app/(panel)/layout.tsx`** es la puerta de verdad: comprueba contra la
   base que quien entró es doctor. Va en el layout y no en cada página para que
   una página nueva quede protegida por existir dentro de `(panel)`, sin que
   nadie se tenga que acordar del chequeo.

Los datos se leen siempre desde el servidor, donde la sesión está verificada
con `getUser()` (nunca `getSession()`, que lee la cookie sin comprobarla).

Las consultas **no filtran por paciente ni por doctor**: eso lo decide RLS en
la base. Repetir la regla en el código sería tener que mantenerla en dos
lugares, y que se contradigan es cuestión de tiempo.

## Desplegar

Vercel, con **Root Directory = `admin`** (el repo tiene también la app Flutter).
Las dos variables de `.env.example` van en Environment Variables del proyecto.
