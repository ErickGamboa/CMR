import { BorrarFila } from "@/components/borrar-fila";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatearFechaCorta } from "@/lib/fechas";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import { borrarRecomendacion } from "./acciones";
import { FormularioRecomendacion, type Icono } from "./formulario";

type Fila = {
  id: string;
  fecha: string;
  titulo: string;
  texto: string;
  icono: string;
};

export default async function PasoRecomendaciones({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await clienteServidor();

  const [{ data: filas }, { data: iconos }] = await Promise.all([
    supabase
      .from("recomendaciones")
      .select("id, fecha, titulo, texto, icono")
      .eq("paciente_id", id)
      .order("fecha", { ascending: false }),
    supabase
      .from("iconos")
      .select("nombre, etiqueta")
      .eq("grupo", "recomendacion")
      .order("orden", { ascending: true }),
  ]);

  const recomendaciones = (filas ?? []) as Fila[];
  const hoy = new Date();
  const hoyIso = [
    hoy.getFullYear(),
    String(hoy.getMonth() + 1).padStart(2, "0"),
    String(hoy.getDate()).padStart(2, "0"),
  ].join("-");

  return (
    <Paso clave="recomendaciones" id={id}>
      <div className="grid gap-6 lg:grid-cols-[minmax(0,24rem)_minmax(0,1fr)] lg:items-start">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Nueva recomendación</CardTitle>
          </CardHeader>
          <CardContent>
            <FormularioRecomendacion
              paciente={id}
              hoy={hoyIso}
              iconos={(iconos ?? []) as Icono[]}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              Las que ya tiene
              {recomendaciones.length > 0 && (
                <span className="ml-2 font-normal text-muted-foreground">
                  {recomendaciones.length}
                </span>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {recomendaciones.length === 0 ? (
              <p className="py-6 text-center text-sm text-muted-foreground">
                Todavía no le dejaste ninguna.
              </p>
            ) : (
              <ul className="divide-y">
                {recomendaciones.map((r) => (
                  <li
                    key={r.id}
                    className="flex items-start gap-3 py-4 first:pt-0 last:pb-0"
                  >
                    <div className="min-w-0 flex-1 space-y-1">
                      <p className="font-medium leading-snug">{r.titulo}</p>
                      <p className="text-sm leading-relaxed text-muted-foreground">
                        {r.texto}
                      </p>
                      <p className="text-xs text-muted-foreground/80">
                        {formatearFechaCorta(r.fecha)}
                      </p>
                    </div>

                    <BorrarFila
                      que="esta recomendación"
                      detalle={`“${r.titulo}”`}
                      onBorrar={async () => {
                        "use server";
                        return borrarRecomendacion(id, r.id);
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
