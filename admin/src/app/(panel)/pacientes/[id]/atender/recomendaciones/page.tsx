import { BorrarFila } from "@/components/borrar-fila";
import { SelectorIndicaciones } from "@/components/indicaciones/selector";
import { LimpiarTodo } from "@/components/limpiar-todo";
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { cargarPlantillas } from "@/lib/catalogo";
import { formatearFechaCorta } from "@/lib/fechas";
import type { DatosAgregar } from "@/lib/indicaciones";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import {
  agregarRecomendacion,
  borrarRecomendacion,
  limpiarRecomendaciones,
} from "./acciones";

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

  const [plantillas, { data: filas }, { data: iconos }] = await Promise.all([
    cargarPlantillas(["recomendacion"]),
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

  return (
    <Paso clave="recomendaciones" id={id}>
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Dejarle una</CardTitle>
          </CardHeader>
          <CardContent>
            <SelectorIndicaciones
              modo="recomendacion"
              grupos={[
                {
                  clave: "recomendacion",
                  titulo: "Recomendaciones",
                  plantillas,
                },
              ]}
              camposLibres={[
                { clave: "titulo", etiqueta: "Título" },
                {
                  clave: "icono",
                  etiqueta: "Ícono",
                  // La lista sale de la tabla `iconos`, espejo del catálogo
                  // cerrado de la app: un nombre que no esté ahí sale
                  // genérico.
                  opciones: (
                    (iconos ?? []) as { nombre: string; etiqueta: string }[]
                  ).map((i) => ({ valor: i.nombre, etiqueta: i.etiqueta })),
                },
                { clave: "texto", etiqueta: "Recomendación", largo: true },
              ]}
              accion={async (datos: DatosAgregar) => {
                "use server";
                return agregarRecomendacion(id, datos);
              }}
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
            <CardAction>
              <LimpiarTodo
                que="las recomendaciones"
                cuantos={recomendaciones.length}
                onLimpiar={async () => {
                  "use server";
                  return limpiarRecomendaciones(id);
                }}
              />
            </CardAction>
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
