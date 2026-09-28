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
import { TIPOS_PRESCRIPCION } from "@/lib/catalogos";
import type { DatosAgregar } from "@/lib/indicaciones";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import {
  agregarPrescripcion,
  borrarPrescripcion,
  limpiarPrescripciones,
} from "./acciones";
import { Suspender } from "./suspender";

type Fila = {
  id: string;
  tipo: string;
  nombre: string;
  dosis: string;
  frecuencia: string;
  indicacion: string | null;
  activo: boolean;
};

export default async function PasoPrescripciones({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await clienteServidor();

  const [plantillas, { data }] = await Promise.all([
    cargarPlantillas(["suplemento", "peptido", "medicamento"]),
    supabase
      .from("prescripciones")
      .select("id, tipo, nombre, dosis, frecuencia, indicacion, activo")
      .eq("paciente_id", id)
      .order("orden", { ascending: true }),
  ]);

  const filas = (data ?? []) as Fila[];

  return (
    <Paso clave="prescripciones" id={id}>
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Indicar</CardTitle>
          </CardHeader>
          <CardContent>
            <SelectorIndicaciones
              modo="prescripcion"
              grupos={TIPOS_PRESCRIPCION.map((t) => ({
                clave: t.valor,
                titulo: `${t.titulo}s`,
                plantillas: plantillas.filter((p) => p.tipo === t.valor),
              }))}
              camposLibres={[
                { clave: "nombre", etiqueta: "Nombre" },
                { clave: "dosis", etiqueta: "Dosis" },
                { clave: "frecuencia", etiqueta: "Frecuencia" },
                {
                  clave: "indicacion",
                  etiqueta: "Indicación",
                  largo: true,
                  opcional: true,
                },
              ]}
              accion={async (datos: DatosAgregar) => {
                "use server";
                return agregarPrescripcion(id, datos);
              }}
            />
          </CardContent>
        </Card>

        <div className="grid gap-6 lg:grid-cols-3 lg:items-start">
          {TIPOS_PRESCRIPCION.map((t) => {
            const suyas = filas.filter((f) => f.tipo === t.valor);

            return (
              <Card key={t.valor}>
                <CardHeader>
                  <CardTitle className="text-base">
                    {t.titulo}s
                    {suyas.length > 0 && (
                      <span className="ml-2 font-normal text-muted-foreground">
                        {suyas.length}
                      </span>
                    )}
                  </CardTitle>
                  {/* Uno por tipo: replantear la suplementación no tiene por
                      qué llevarse los medicamentos que toma por otra cosa. */}
                  <CardAction>
                    <LimpiarTodo
                      que={`los ${t.titulo.toLowerCase()}s`}
                      cuantos={suyas.length}
                      onLimpiar={async () => {
                        "use server";
                        return limpiarPrescripciones(id, t.valor);
                      }}
                    />
                  </CardAction>
                </CardHeader>
                <CardContent>
                  {suyas.length === 0 ? (
                    <p className="py-4 text-center text-sm text-muted-foreground">
                      Nada indicado.
                    </p>
                  ) : (
                    <ul className="divide-y">
                      {suyas.map((p) => (
                        <li key={p.id} className="py-3 first:pt-0 last:pb-0">
                          <div className="flex items-start gap-2">
                            <div
                              className={`min-w-0 flex-1 space-y-1.5 transition-opacity ${
                                p.activo ? "" : "opacity-50"
                              }`}
                            >
                              <p className="font-medium leading-snug">
                                {p.nombre}
                                {!p.activo && (
                                  <span className="ml-2 text-xs font-normal text-muted-foreground">
                                    suspendido
                                  </span>
                                )}
                              </p>

                              {/* La misma forma que la tarjeta de la app, para
                                  que lo que se revisa acá sea lo que el
                                  paciente tiene en pantalla. */}
                              {(p.dosis || p.frecuencia) && (
                                <div className="flex flex-wrap items-center gap-1.5">
                                  {p.dosis && (
                                    <span className="rounded-md bg-primary px-2 py-0.5 text-xs font-semibold text-primary-foreground">
                                      {p.dosis}
                                    </span>
                                  )}
                                  {p.frecuencia && (
                                    <span className="rounded-md border px-2 py-0.5 text-xs font-medium text-muted-foreground">
                                      {p.frecuencia}
                                    </span>
                                  )}
                                </div>
                              )}

                              {p.indicacion && (
                                <p className="text-xs leading-relaxed text-muted-foreground">
                                  {p.indicacion}
                                </p>
                              )}
                            </div>

                            <BorrarFila
                              que="esto"
                              detalle={p.nombre}
                              onBorrar={async () => {
                                "use server";
                                return borrarPrescripcion(id, p.id);
                              }}
                            />
                          </div>

                          <Suspender
                            paciente={id}
                            id={p.id}
                            activo={p.activo}
                          />
                        </li>
                      ))}
                    </ul>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>
    </Paso>
  );
}
