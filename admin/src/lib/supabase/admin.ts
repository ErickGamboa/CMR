import "server-only";

import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import { doctorActual } from "@/lib/doctor";

import { entornoSupabase } from "./entorno";

/**
 * Las operaciones que exigen la llave secreta de Supabase.
 *
 * ============================================================================
 * ESTE ES EL ÚNICO ARCHIVO DEL SITIO QUE TOCA ESA LLAVE. Que siga así.
 * ============================================================================
 *
 * Crear cuentas y cambiar contraseñas es Admin API: no hay forma de hacerlo
 * con la sesión del doctor y RLS. Y la llave secreta **se salta RLS por
 * completo**, así que acá la base no protege nada: si una de estas funciones
 * se llama sin comprobar quién llama, cualquiera con una sesión cualquiera
 * podría crear cuentas o cambiarle la contraseña a otro paciente.
 *
 * Por eso las tres reglas de este archivo:
 *
 *   1. `server-only` arriba: si alguien lo importa desde un componente de
 *      cliente, la compilación falla en vez de mandar la llave al navegador.
 *   2. La variable NO lleva prefijo `NEXT_PUBLIC_`, así que Next nunca la
 *      inserta en el paquete del cliente.
 *   3. **Cada función exportada empieza llamando a `exigirDoctor()`.** No hay
 *      excepciones; si alguna vez hace falta una, no va en este archivo.
 */

let cache: SupabaseClient | null = null;

function admin() {
  if (cache) return cache;

  const { url } = entornoSupabase();
  const secreta = process.env.SUPABASE_SECRET_KEY;

  if (!secreta) {
    throw new Error(
      "Falta SUPABASE_SECRET_KEY. Es la llave secreta del proyecto " +
        "(Supabase → Project Settings → API Keys → Secret keys), y va SOLO " +
        "en el servidor: nunca con prefijo NEXT_PUBLIC_.",
    );
  }

  cache = createClient(url, secreta, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  return cache;
}

/** El portón. Todas las funciones de abajo pasan por acá primero. */
async function exigirDoctor() {
  const doctor = await doctorActual();
  if (!doctor) throw new Error("Solo un doctor puede hacer esto.");
  return doctor;
}

/**
 * Contraseña temporal legible: dos palabras y cuatro dígitos.
 *
 * Pensada para dictarse por teléfono o leerse en voz alta a un adulto mayor,
 * que es el caso que motivó todo esto. Una cadena aleatoria de 16 caracteres
 * sería más fuerte y no serviría de nada: nadie la escribe bien a la primera.
 *
 * El paciente la puede cambiar después; mientras tanto, ~40 bits contra un
 * inicio de sesión con límite de intentos es suficiente.
 */
const PALABRAS = [
  "roble",
  "cedro",
  "guaria",
  "colibri",
  "quetzal",
  "yiguirro",
  "manglar",
  "poas",
  "arenal",
  "coco",
  "mango",
  "papaya",
  "jocote",
  "guanabana",
  "tortuga",
  "perezoso",
  "danta",
  "lapa",
  "garza",
  "tucan",
];

export function claveTemporal() {
  const palabra = () => PALABRAS[Math.floor(Math.random() * PALABRAS.length)];
  const numero = Math.floor(1000 + Math.random() * 9000);
  return `${palabra()}-${palabra()}-${numero}`;
}

export type ResultadoAlta =
  { ok: true; id: string; clave: string } | { ok: false; error: string };

/**
 * Crea la cuenta de un paciente y devuelve la contraseña temporal.
 *
 * La cuenta queda con el correo ya confirmado: la aprobación del doctor es la
 * verificación de que esta persona es paciente de la clínica, y pedirle además
 * que abra un correo sería un trámite de más para alguien que está sentado al
 * frente del doctor.
 *
 * La ficha en `pacientes` la crea el disparador `al_crear_usuario`; acá solo
 * se completa lo que el doctor llenó y se deja aprobada de una, porque la creó
 * él mismo.
 */
export async function crearPaciente(datos: {
  correo: string;
  nombre: string;
  apellidos: string | null;
  cedula: string | null;
  telefono: string | null;
}): Promise<ResultadoAlta> {
  const doctor = await exigirDoctor();
  const clave = claveTemporal();

  const { data, error } = await admin().auth.admin.createUser({
    email: datos.correo,
    password: clave,
    email_confirm: true,
    user_metadata: {
      nombre: datos.nombre,
      apellidos: datos.apellidos,
      cedula: datos.cedula,
    },
  });

  if (error || !data.user) {
    const mensaje = error?.message ?? "";
    if (/already|registered|exists/i.test(mensaje)) {
      return { ok: false, error: "Ese correo ya tiene una cuenta." };
    }
    if (/cédula|cedula/i.test(mensaje)) {
      return { ok: false, error: "Esa cédula ya tiene una cuenta." };
    }
    return { ok: false, error: "No pudimos crear la cuenta." };
  }

  // La creó el doctor, así que no tiene que aprobarse a sí misma.
  const { error: fallaFicha } = await admin()
    .from("pacientes")
    .update({
      telefono: datos.telefono,
      estado: "activo",
      aprobado_en: new Date().toISOString(),
      aprobado_por: doctor.userId,
    })
    .eq("user_id", data.user.id);

  if (fallaFicha) {
    return {
      ok: false,
      error: "La cuenta se creó, pero no quedó aprobada. Aprobala a mano.",
    };
  }

  return { ok: true, id: data.user.id, clave };
}

/**
 * Le pone una contraseña nueva a un paciente y la devuelve.
 *
 * Es la respuesta a "quiero ver la contraseña del paciente", que no se puede:
 * Supabase guarda un hash, no la contraseña. El doctor no la lee, la pone; y
 * la sabe porque acaba de ponerla, no porque estuviera guardada en algún lado.
 */
export async function asignarClave(
  idPaciente: string,
): Promise<{ ok: true; clave: string } | { ok: false; error: string }> {
  await exigirDoctor();

  // Un doctor no le cambia la contraseña a otro doctor.
  const esDoctor = await admin()
    .from("doctores")
    .select("user_id")
    .eq("user_id", idPaciente)
    .maybeSingle();

  if (esDoctor.data) {
    return { ok: false, error: "Esa cuenta no es de un paciente." };
  }

  const clave = claveTemporal();
  const { error } = await admin().auth.admin.updateUserById(idPaciente, {
    password: clave,
  });

  if (error) return { ok: false, error: "No pudimos cambiar la contraseña." };

  return { ok: true, clave };
}

/** Cambia el correo con que el paciente entra, y lo refleja en su ficha. */
export async function cambiarCorreo(
  idPaciente: string,
  correo: string,
): Promise<{ ok: true } | { ok: false; error: string }> {
  await exigirDoctor();

  const { error } = await admin().auth.admin.updateUserById(idPaciente, {
    email: correo,
    email_confirm: true,
  });

  if (error) {
    if (/already|registered|exists/i.test(error.message)) {
      return { ok: false, error: "Ese correo ya tiene una cuenta." };
    }
    return { ok: false, error: "No pudimos cambiar el correo." };
  }

  await admin().from("pacientes").update({ correo }).eq("user_id", idPaciente);

  return { ok: true };
}

/**
 * Borra la cuenta de un paciente y todo lo suyo.
 *
 * Es lo que pasa al rechazar a alguien que se registró: dejarlo en `inactivo`
 * sería conservar el nombre y la cédula de una persona que la clínica decidió
 * que no es su paciente. Si no es paciente, no hay razón para guardarle nada.
 *
 * Las llaves foráneas `on delete cascade` se llevan la ficha y todo lo que
 * cuelgue de ella.
 */
export async function eliminarPaciente(
  idPaciente: string,
): Promise<{ ok: true } | { ok: false; error: string }> {
  await exigirDoctor();

  // Un doctor no se borra por accidente desde la pantalla de un paciente.
  const esDoctor = await admin()
    .from("doctores")
    .select("user_id")
    .eq("user_id", idPaciente)
    .maybeSingle();

  if (esDoctor.data) {
    return { ok: false, error: "Esa cuenta no es de un paciente." };
  }

  const { error } = await admin().auth.admin.deleteUser(idPaciente);
  if (error) return { ok: false, error: "No pudimos eliminar la cuenta." };

  return { ok: true };
}
