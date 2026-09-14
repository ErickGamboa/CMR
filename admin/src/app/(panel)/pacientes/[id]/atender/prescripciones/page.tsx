import { BorrarFila } from "@/components/borrar-fila";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { TIPOS_PRESCRIPCION } from "@/lib/catalogos";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import { borrarPrescripcion } from "./acciones";
import { FormularioPrescripcion } from "./formulario";
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

  const { data } = await supabase
    .from("prescripciones")
    .select("id, tipo, nombre, dosis, frecuencia, indicacion, activo")
    .eq("paciente_id", id)
    .order("orden", { ascending: true });

  const filas = (data ?? []) as Fila[];

  return (
    <Paso clave="prescripciones" id={id}>
      <div className="grid gap-6 lg:grid-cols-[minmax(0,24rem)_minmax(0,1fr)] lg:items-start">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Agregar</CardTitle>
          </CardHeader>
          <CardContent>
            <FormularioPrescripcion paciente={id} />
          </CardContent>
        </Card>

        <div className="space-y-6">
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
                </CardHeader>
                <CardContent>
                  {suyas.length === 0 ? (
                    <p className="py-4 text-center text-sm text-muted-foreground">
                      Nada indicado.
                    </p>
                  ) : (
                    <ul className="divide-y">
                      {suyas.map((p) => (
                        <li
                          key={p.id}
                          className="flex items-start gap-2 py-3 first:pt-0 last:pb-0"
                        >
                          <div
                            className={`min-w-0 flex-1 space-y-0.5 transition-opacity ${
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
                            <p className="text-sm text-muted-foreground">
                              {p.dosis} · {p.frecuencia}
                              {p.indicacion && ` · ${p.indicacion}`}
                            </p>
                          </div>

                          <Suspender
                            paciente={id}
                            id={p.id}
                            activo={p.activo}
                          />
                          <BorrarFila
                            que="esto"
                            detalle={p.nombre}
                            onBorrar={async () => {
                              "use server";
                              return borrarPrescripcion(id, p.id);
                            }}
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
