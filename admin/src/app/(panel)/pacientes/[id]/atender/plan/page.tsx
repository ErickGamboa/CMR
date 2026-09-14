import { Card, CardContent } from "@/components/ui/card";
import { escribirCelda } from "@/lib/plan";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import { TablaPlan, type PlanCargado } from "./tabla";

/** Postgres devuelve los `numeric` como texto. */
function num(valor: string | number) {
  const n = typeof valor === "number" ? valor : Number(valor);
  return Number.isFinite(n) ? n : 0;
}

export default async function PasoPlan({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await clienteServidor();

  const { data: plan } = await supabase
    .from("planes_alimentacion")
    .select("id, vigente_desde, notas")
    .eq("paciente_id", id)
    .eq("activo", true)
    .maybeSingle();

  const celdas: Record<string, string> = {};

  if (plan?.id) {
    const { data: filasReparto } = await supabase
      .from("plan_distribucion")
      .select("grupo, tiempo, cantidad, es_minimo")
      .eq("plan_id", plan.id);

    for (const f of filasReparto ?? []) {
      celdas[`${f.grupo}.${f.tiempo}`] = escribirCelda({
        cantidad: num(f.cantidad as string | number),
        esMinimo: (f.es_minimo as boolean) ?? false,
      });
    }
  }

  const hoy = new Date();
  const hoyIso = [
    hoy.getFullYear(),
    String(hoy.getMonth() + 1).padStart(2, "0"),
    String(hoy.getDate()).padStart(2, "0"),
  ].join("-");

  const cargado: PlanCargado = {
    vigenteDesde: (plan?.vigente_desde as string | undefined) ?? hoyIso,
    notas: (plan?.notas as string | undefined) ?? "",
    celdas,
  };

  return (
    <Paso clave="plan" id={id}>
      <Card>
        <CardContent>
          <TablaPlan paciente={id} plan={cargado} />
        </CardContent>
      </Card>
    </Paso>
  );
}
