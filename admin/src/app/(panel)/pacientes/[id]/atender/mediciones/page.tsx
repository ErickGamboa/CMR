import { BorrarFila } from "@/components/borrar-fila";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatearFechaCorta } from "@/lib/fechas";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import { borrarMedicion } from "./acciones";
import { FormularioMedicion } from "./formulario";

type Fila = {
  id: string;
  fecha: string;
  peso: string | number;
  porcentaje_grasa: string | number;
  grasa_visceral: string | number;
  grasa_perdida: string | number;
  musculo_ganado: string | number;
};

/** Postgres devuelve los `numeric` como texto. */
function num(valor: string | number) {
  const n = typeof valor === "number" ? valor : Number(valor);
  return Number.isFinite(n) ? n : 0;
}

export default async function PasoMediciones({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await clienteServidor();

  const { data } = await supabase
    .from("mediciones")
    .select(
      "id, fecha, peso, porcentaje_grasa, grasa_visceral, grasa_perdida, musculo_ganado",
    )
    .eq("paciente_id", id)
    .order("fecha", { ascending: false });

  const mediciones = (data ?? []) as Fila[];

  // La fecha del navegador del doctor, no la del servidor: el servidor corre
  // en UTC y de noche propondría el día siguiente.
  const hoy = new Date();
  const hoyIso = [
    hoy.getFullYear(),
    String(hoy.getMonth() + 1).padStart(2, "0"),
    String(hoy.getDate()).padStart(2, "0"),
  ].join("-");

  return (
    <Paso clave="mediciones" id={id}>
      <div className="grid gap-6 lg:grid-cols-[minmax(0,22rem)_minmax(0,1fr)] lg:items-start">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Nueva medición</CardTitle>
          </CardHeader>
          <CardContent>
            <FormularioMedicion paciente={id} hoy={hoyIso} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              Historial
              {mediciones.length > 0 && (
                <span className="ml-2 font-normal text-muted-foreground">
                  {mediciones.length}
                </span>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {mediciones.length === 0 ? (
              <p className="py-6 text-center text-sm text-muted-foreground">
                Todavía no tiene mediciones.
              </p>
            ) : (
              <ul className="divide-y">
                {mediciones.map((m) => (
                  <li
                    key={m.id}
                    className="flex items-start gap-3 py-3 first:pt-0 last:pb-0"
                  >
                    <div className="min-w-0 flex-1 space-y-1">
                      <p className="text-sm font-medium">
                        {formatearFechaCorta(m.fecha)}
                      </p>
                      <dl className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                        <Dato etiqueta="Peso" valor={`${num(m.peso)} kg`} />
                        <Dato
                          etiqueta="Grasa"
                          valor={`${num(m.porcentaje_grasa)} %`}
                        />
                        <Dato
                          etiqueta="Visceral"
                          valor={String(num(m.grasa_visceral))}
                        />
                        <Dato
                          etiqueta="Perdida"
                          valor={`${num(m.grasa_perdida)} kg`}
                        />
                        <Dato
                          etiqueta="Músculo"
                          valor={`${num(m.musculo_ganado)} kg`}
                        />
                      </dl>
                    </div>

                    <BorrarFila
                      que="esta medición"
                      detalle={`La del ${formatearFechaCorta(m.fecha)}`}
                      onBorrar={async () => {
                        "use server";
                        return borrarMedicion(id, m.id);
                      }}
                    />
                  </li>
                ))}
              </ul>
            )}
          </CardContent>
        </Card>
      </div>
    </Paso>
  );
}

function Dato({ etiqueta, valor }: { etiqueta: string; valor: string }) {
  return (
    <div className="flex gap-1">
      <dt>{etiqueta}</dt>
      <dd className="font-medium tabular-nums text-foreground">{valor}</dd>
    </div>
  );
}
