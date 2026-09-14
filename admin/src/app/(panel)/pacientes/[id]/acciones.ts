"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { doctorActual } from "@/lib/doctor";
import { asignarClave, eliminarPaciente } from "@/lib/supabase/admin";
import type { EstadoPaciente } from "@/lib/pacientes";
import { clienteServidor } from "@/lib/supabase/servidor";

export type EstadoFicha = { error: string | null; guardado: boolean };

/** Un campo vacío se guarda como null, no como cadena vacía. */
function oNulo(valor: FormDataEntryValue | null) {
  const texto = String(valor ?? "").trim();
  return texto === "" ? null : texto;
}

/**
 * Guarda los datos de un paciente.
 *
 * No comprueba acá si quien llama es doctor: la política `pacientes_doctor` de
 * la base lo hace, y a un paciente este update simplemente no le afecta
 * ninguna fila. Duplicar la regla en el código sería tener dos fuentes de
 * verdad para lo mismo.
 *
 * `estado` no se toca desde acá: cambiarlo es aprobar o dar de baja, y eso es
 * una decisión, no un campo de formulario.
 */
export async function guardarPaciente(
  _anterior: EstadoFicha,
  datos: FormData,
): Promise<EstadoFicha> {
  const id = String(datos.get("id") ?? "");
  const nombre = String(datos.get("nombre") ?? "").trim();

  if (!id) return { error: "Falta el paciente.", guardado: false };
  if (!nombre) {
    return { error: "El nombre no puede quedar vacío.", guardado: false };
  }

  const supabase = await clienteServidor();
  const { data, error } = await supabase
    .from("pacientes")
    .update({
      nombre,
      apellidos: oNulo(datos.get("apellidos")),
      cedula: oNulo(datos.get("cedula")),
      telefono: oNulo(datos.get("telefono")),
      fecha_nacimiento: oNulo(datos.get("fecha_nacimiento")),
    })
    .eq("user_id", id)
    .select("user_id");

  if (error) {
    // 23505: la cédula ya es de otro paciente.
    if (error.code === "23505") {
      return {
        error: "Esa cédula ya está registrada en otro paciente.",
        guardado: false,
      };
    }
    return { error: "No pudimos guardar. Intenta de nuevo.", guardado: false };
  }

  // Sin filas afectadas no hubo error de SQL, pero tampoco cambio: es lo que
  // pasa cuando RLS deja pasar la consulta y no deja tocar la fila.
  if (!data || data.length === 0) {
    return {
      error: "No tienes permiso para editar este paciente.",
      guardado: false,
    };
  }

  revalidatePath("/pacientes");
  revalidatePath(`/pacientes/${id}`);

  return { error: null, guardado: true };
}

/**
 * Le asigna una contraseña nueva al paciente y la devuelve.
 *
 * `asignarClave` ya comprueba que quien llama sea doctor; esto solo la expone
 * como Server Action para que el botón de la ficha pueda llamarla.
 */
export async function nuevaClave(idPaciente: string) {
  return asignarClave(idPaciente);
}

/**
 * Aprueba, reactiva o da de baja a un paciente.
 *
 * Aprobar es lo que convierte una cuenta cualquiera en paciente de la clínica:
 * hasta que pasa, la persona no ve su plan, ni sus citas, ni el libro. Por eso
 * queda anotado quién aprobó y cuándo.
 */
export async function cambiarEstado(id: string, estado: EstadoPaciente) {
  const doctor = await doctorActual();
  if (!doctor) return { error: "Tu sesión no es de un doctor." };

  const supabase = await clienteServidor();
  const { data, error } = await supabase
    .from("pacientes")
    .update({
      estado,
      aprobado_en: estado === "activo" ? new Date().toISOString() : null,
      aprobado_por: estado === "activo" ? doctor.userId : null,
    })
    .eq("user_id", id)
    .select("user_id");

  if (error || !data || data.length === 0) {
    return { error: "No pudimos cambiar el estado." };
  }

  revalidatePath("/pacientes");
  revalidatePath(`/pacientes/${id}`);

  return { error: null };
}

/**
 * Rechaza a quien se registró: le borra la cuenta.
 *
 * No se deja en `inactivo` a propósito. Alguien a quien la clínica decidió que
 * no atiende no tiene por qué quedar guardado con su nombre y su cédula; y si
 * fue un error, la persona se vuelve a registrar en un minuto.
 *
 * Dar de baja es otra cosa: ese sí es paciente, y su expediente se conserva.
 */
export async function rechazarPaciente(idPaciente: string) {
  const r = await eliminarPaciente(idPaciente);
  if (!r.ok) return { error: r.error };

  revalidatePath("/pacientes");
  redirect("/pacientes");
}
