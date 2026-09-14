"use server";

import { revalidatePath } from "next/cache";

import { clienteServidor } from "@/lib/supabase/servidor";

// OJO: un archivo "use server" solo puede exportar funciones async. Todo lo
// que exporta queda expuesto como punto de entrada que el navegador puede
// invocar por la red, y por eso Next prohibe exportar cualquier otra cosa.
// Los tipos sí (se borran al compilar); las constantes NO: van en el
// componente de cliente que las usa.
export type Resultado = { error: string | null; guardado: boolean };

/** Acepta coma o punto: en Costa Rica se escriben las dos formas. */
function aNumero(valor: FormDataEntryValue | null) {
  const texto = String(valor ?? "")
    .trim()
    .replace(",", ".");
  if (texto === "") return null;

  const n = Number(texto);
  return Number.isFinite(n) ? n : null;
}

/**
 * Guarda la medición de un día.
 *
 * Va con `upsert` sobre `(paciente_id, fecha)`: la tabla solo admite una
 * medición por día, y volver a pesar al paciente en la misma consulta tiene
 * que corregir la de hoy, no fallar con un error de llave repetida.
 */
export async function guardarMedicion(
  _anterior: Resultado,
  datos: FormData,
): Promise<Resultado> {
  const paciente = String(datos.get("paciente") ?? "");
  const fecha = String(datos.get("fecha") ?? "").trim();

  const peso = aNumero(datos.get("peso"));
  const grasa = aNumero(datos.get("porcentaje_grasa"));
  const visceral = aNumero(datos.get("grasa_visceral"));
  const perdida = aNumero(datos.get("grasa_perdida")) ?? 0;
  const ganado = aNumero(datos.get("musculo_ganado")) ?? 0;

  if (!paciente) return { error: "Falta el paciente.", guardado: false };
  if (!fecha) return { error: "Elegí la fecha.", guardado: false };

  if (peso === null || peso <= 0) {
    return {
      error: "El peso tiene que ser un número mayor que cero.",
      guardado: false,
    };
  }
  if (grasa === null || grasa < 0) {
    return { error: "Escribí el porcentaje de grasa.", guardado: false };
  }
  if (visceral === null || visceral < 0) {
    return { error: "Escribí la grasa visceral.", guardado: false };
  }

  const supabase = await clienteServidor();
  const { data, error } = await supabase
    .from("mediciones")
    .upsert(
      {
        paciente_id: paciente,
        fecha,
        peso,
        porcentaje_grasa: grasa,
        grasa_visceral: visceral,
        grasa_perdida: perdida,
        musculo_ganado: ganado,
      },
      { onConflict: "paciente_id,fecha" },
    )
    .select("id");

  if (error || !data || data.length === 0) {
    return {
      error: "No pudimos guardar la medición. Intenta de nuevo.",
      guardado: false,
    };
  }

  revalidatePath(`/pacientes/${paciente}/atender/mediciones`);
  return { error: null, guardado: true };
}

export async function borrarMedicion(paciente: string, id: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase.from("mediciones").delete().eq("id", id);

  if (error) return { error: "No pudimos borrar la medición." };

  revalidatePath(`/pacientes/${paciente}/atender/mediciones`);
  return { error: null };
}
