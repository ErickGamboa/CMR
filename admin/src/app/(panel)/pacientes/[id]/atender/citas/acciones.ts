"use server";

import { revalidatePath } from "next/cache";

import { clienteServidor } from "@/lib/supabase/servidor";

export type Resultado = { error: string | null; guardado: boolean };

export async function guardarCita(
  _anterior: Resultado,
  datos: FormData,
): Promise<Resultado> {
  const paciente = String(datos.get("paciente") ?? "");
  const fecha = String(datos.get("fecha") ?? "").trim();
  const hora = String(datos.get("hora") ?? "").trim();
  const tipo = String(datos.get("tipo") ?? "medica");
  const profesional = String(datos.get("profesional") ?? "").trim();
  const especialidad = String(datos.get("especialidad") ?? "").trim();
  const lugar = String(datos.get("lugar") ?? "").trim();

  if (!paciente) return { error: "Falta el paciente.", guardado: false };
  if (!fecha) return { error: "Elegí la fecha.", guardado: false };
  if (!hora) return { error: "Elegí la hora.", guardado: false };
  if (!profesional)
    return { error: "Escribí quién la atiende.", guardado: false };
  if (!especialidad)
    return { error: "Escribí de qué es la cita.", guardado: false };
  if (!lugar) return { error: "Escribí el lugar.", guardado: false };

  const supabase = await clienteServidor();
  const { data, error } = await supabase
    .from("citas")
    // Sin zona horaria: la columna es `timestamp` y guarda la hora del reloj
    // de la clínica. Mandar un ISO con Z la correría seis horas.
    .insert({
      paciente_id: paciente,
      fecha: `${fecha}T${hora}:00`,
      tipo,
      profesional,
      especialidad,
      lugar,
    })
    .select("id");

  if (error || !data || data.length === 0) {
    return {
      error: "No pudimos guardar la cita. Intenta de nuevo.",
      guardado: false,
    };
  }

  revalidatePath(`/pacientes/${paciente}/atender/citas`);
  return { error: null, guardado: true };
}

export async function borrarCita(paciente: string, id: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase.from("citas").delete().eq("id", id);

  if (error) return { error: "No pudimos borrar la cita." };

  revalidatePath(`/pacientes/${paciente}/atender/citas`);
  return { error: null };
}
