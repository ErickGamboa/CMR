import { BorrarFila } from "@/components/borrar-fila";
import { LimpiarTodo } from "@/components/limpiar-todo";
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { formatearFechaCorta } from "@/lib/fechas";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import { borrarLaboratorio, limpiarLaboratorios } from "./acciones";
import { FormularioLaboratorio, type Analito } from "./formulario";

type Fila = {
  id: string;
  fecha: string;
  nombre: string;
  laboratorio_analisis: {
    nombre: string;
    valor: string;
    unidad: string;
    orden: number;
  }[];
};

export default async function PasoLaboratorios({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await clienteServidor();

  const [{ data: analitos }, { data: filas }] = await Promise.all([
    supabase
      .from("catalogo_analitos")
      .select("id, nombre, unidad")
      .eq("activo", true)
      .order("orden", { ascending: true }),
    supabase
      .from("laboratorios")
      .select(
        "id, fecha, nombre, laboratorio_analisis(nombre, valor, unidad, orden)",
      )
      .eq("paciente_id", id)
      .order("fecha", { ascending: false }),
  ]);

  const laboratorios = (filas ?? []) as Fila[];
  const hoy = new Date();
  const hoyIso = [
    hoy.getFullYear(),
    String(hoy.getMonth() + 1).padStart(2, "0"),
    String(hoy.getDate()).padStart(2, "0"),
  ].join("-");

  return (
    <Paso clave="laboratorios" id={id}>
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Cargar un examen</CardTitle>
          </CardHeader>
          <CardContent>
            <FormularioLaboratorio
              paciente={id}
              hoy={hoyIso}
              analitos={(analitos ?? []) as Analito[]}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              Los que ya tiene
              {laboratorios.length > 0 && (
                <span className="ml-2 font-normal text-muted-foreground">
                  {laboratorios.length}
                </span>
              )}
            </CardTitle>
            <CardAction>
              <LimpiarTodo
                que="los exámenes"
                cuantos={laboratorios.length}
                advertencia="Se van también todos sus resultados."
                onLimpiar={async () => {
                  "use server";
                  return limpiarLaboratorios(id);
                }}
              />
            </CardAction>
          </CardHeader>
          <CardContent>
            {laboratorios.length === 0 ? (
              <p className="py-6 text-center text-sm text-muted-foreground">
                Todavía no le cargaste ninguno.
              </p>
            ) : (
              <ul className="divide-y">
                {laboratorios.map((l) => (
                  <li key={l.id} className="py-4 first:pt-0 last:pb-0">
                    <div className="flex items-start gap-3">
                      <div className="min-w-0 flex-1">
                        <p className="font-medium leading-snug">{l.nombre}</p>
                        <p className="text-xs text-muted-foreground">
                          {formatearFechaCorta(l.fecha)} ·{" "}
                          {l.laboratorio_analisis.length} resultado
                          {l.laboratorio_analisis.length === 1 ? "" : "s"}
                        </p>
                      </div>

                      <BorrarFila
                        que="este examen"
                        detalle={`${l.nombre}, ${formatearFechaCorta(l.fecha)}`}
                        onBorrar={async () => {
                          "use server";
                          return borrarLaboratorio(id, l.id);
                        }}
                      />
                    </div>

                    <div className="mt-3 flex flex-wrap gap-1.5">
                      {[...l.laboratorio_analisis]
                        .sort((a, b) => a.orden - b.orden)
                        .map((a, i) => (
                          <span
                            key={i}
                            className="rounded-md border px-2.5 py-1 text-xs text-muted-foreground"
                          >
                            {a.nombre}{" "}
                            <span className="text-sm font-semibold tabular-nums text-foreground">
                              {a.valor}
                            </span>{" "}
                            {a.unidad}
                          </span>
                        ))}
                    </div>
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
