"use server";

import { revalidatePath } from "next/cache";

import {
  GRUPOS,
  TIEMPOS,
  campoCelda,
  leerCelda,
  sumarFila,
  type Celda,
} from "@/lib/plan";
import { clienteServidor } from "@/lib/supabase/servidor";

// Un archivo "use server" solo puede exportar funciones async.
export type Resultado = { error: string | null; guardado: boolean };

/**
 * Guarda la tabla completa del plan.
 *
 * Se borra y se vuelve a escribir en vez de comparar celda por celda: la tabla
 * tiene treinta casillas como mucho, y un borrón y cuenta nueva no deja
 * huérfano lo que el doctor vació. Lo que quedó en blanco simplemente no se
 * inserta, que es como la tabla del papel pone un guion.
 */
export async function guardarPlan(
  _anterior: Resultado,
  datos: FormData,
): Promise<Resultado> {
  const paciente = String(datos.get("paciente") ?? "");
  if (!paciente) return { error: "Falta el paciente.", guardado: false };

  const desde = String(datos.get("vigente_desde") ?? "").trim();
  const notas = String(datos.get("notas") ?? "").trim();

  // 1. Leer y validar toda la tabla antes de tocar la base: si una celda está
  //    mal escrita, no se guarda nada a medias.
  const totales: { grupo: string; celda: Celda }[] = [];
  const reparto: { grupo: string; tiempo: string; celda: Celda }[] = [];

  for (const g of GRUPOS) {
    const fila: (Celda | null)[] = [];

    for (const t of TIEMPOS) {
      const crudoCelda = String(datos.get(campoCelda(g.valor, t.valor)) ?? "");
      const valor = leerCelda(crudoCelda);

      if (valor === undefined) {
        return {
          error: `${g.titulo} en ${t.titulo} no se entiende: "${crudoCelda.trim()}".`,
          guardado: false,
        };
      }
      fila.push(valor);
      if (valor) {
        reparto.push({ grupo: g.valor, tiempo: t.valor, celda: valor });
      }
    }

    // El total del día sale de la fila, no de un campo aparte: así no pueden
    // decir cosas distintas.
    const total = sumarFila(fila);
    if (total) totales.push({ grupo: g.valor, celda: total });
  }

  if (totales.length === 0 && reparto.length === 0) {
    return { error: "La tabla está vacía.", guardado: false };
  }

  const supabase = await clienteServidor();

  // 2. El plan activo. Solo puede haber uno por paciente (lo impone un índice
  //    único), así que se reusa el que haya en vez de crear otro.
  const { data: existente } = await supabase
    .from("planes_alimentacion")
    .select("id")
    .eq("paciente_id", paciente)
    .eq("activo", true)
    .maybeSingle();

  let planId = existente?.id as string | undefined;

  if (planId) {
    const { error } = await supabase
      .from("planes_alimentacion")
      .update({
        notas: notas || null,
        ...(desde ? { vigente_desde: desde } : {}),
      })
      .eq("id", planId);

    if (error) return { error: "No pudimos guardar el plan.", guardado: false };
  } else {
    const { data, error } = await supabase
      .from("planes_alimentacion")
      .insert({
        paciente_id: paciente,
        notas: notas || null,
        ...(desde ? { vigente_desde: desde } : {}),
      })
      .select("id")
      .single();

    if (error || !data) {
      return { error: "No pudimos crear el plan.", guardado: false };
    }
    planId = data.id as string;
  }

  // 3. Reemplazar las dos tablas hijas.
  await supabase.from("plan_totales").delete().eq("plan_id", planId);
  await supabase.from("plan_distribucion").delete().eq("plan_id", planId);

  if (totales.length > 0) {
    const { error } = await supabase.from("plan_totales").insert(
      totales.map((t) => ({
        plan_id: planId,
        grupo: t.grupo,
        total: t.celda.cantidad,
        es_minimo: t.celda.esMinimo,
      })),
    );
    if (error) {
      return { error: "No pudimos guardar los totales.", guardado: false };
    }
  }

  if (reparto.length > 0) {
    const { error } = await supabase.from("plan_distribucion").insert(
      reparto.map((r) => ({
        plan_id: planId,
        grupo: r.grupo,
        tiempo: r.tiempo,
        cantidad: r.celda.cantidad,
        es_minimo: r.celda.esMinimo,
      })),
    );
    if (error) {
      return { error: "No pudimos guardar el reparto.", guardado: false };
    }
  }

  revalidatePath(`/pacientes/${paciente}/atender/plan`);
  return { error: null, guardado: true };
}
