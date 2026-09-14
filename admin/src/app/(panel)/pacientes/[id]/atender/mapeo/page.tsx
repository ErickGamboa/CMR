import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatearFechaCorta } from "@/lib/fechas";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import { Interruptor } from "./interruptor";

type Registro = {
  tipo: "presion" | "glisemia";
  fecha: string;
  ayunas: string | null;
  libre: string | null;
  antes_de_dormir: string | null;
};

const MOMENTOS = [
  { columna: "ayunas", etiqueta: "En ayunas" },
  { columna: "libre", etiqueta: "*" },
  { columna: "antes_de_dormir", etiqueta: "Antes de dormir" },
] as const;

const TIPOS = [
  { valor: "presion", titulo: "Presión arterial" },
  { valor: "glisemia", titulo: "Glisemia" },
] as const;

export default async function PasoMapeo({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await clienteServidor();

  const [{ data: modulo }, { data: registros }] = await Promise.all([
    supabase
      .from("pacientes_modulos")
      .select("habilitado")
      .eq("paciente_id", id)
      .eq("modulo", "mapeo")
      .maybeSingle(),
    supabase
      .from("mapeo_registros")
      .select("tipo, fecha, ayunas, libre, antes_de_dormir")
      .eq("paciente_id", id)
      .order("fecha", { ascending: false })
      .limit(60),
  ]);

  const habilitado = (modulo?.habilitado as boolean | undefined) ?? false;
  const filas = (registros ?? []) as Registro[];

  return (
    <Paso clave="mapeo" id={id}>
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Módulo en la app</CardTitle>
          </CardHeader>
          <CardContent>
            <Interruptor paciente={id} habilitado={habilitado} />
          </CardContent>
        </Card>

        {/* Este paso es el único donde el doctor solo lee: las mediciones las
            toma el paciente en su casa, y corregírselas sería falsear su
            registro. */}
        <div className="grid gap-6 lg:grid-cols-2">
          {TIPOS.map((t) => {
            const suyos = filas.filter((f) => f.tipo === t.valor);

            return (
              <Card key={t.valor}>
                <CardHeader>
                  <CardTitle className="text-base">
                    {t.titulo}
                    {suyos.length > 0 && (
                      <span className="ml-2 font-normal text-muted-foreground">
                        {suyos.length}
                      </span>
                    )}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {suyos.length === 0 ? (
                    <p className="py-6 text-center text-sm text-muted-foreground">
                      {habilitado
                        ? "Todavía no ha anotado nada."
                        : "El módulo está apagado."}
                    </p>
                  ) : (
                    <ul className="divide-y">
                      {suyos.map((r) => (
                        <li
                          key={`${r.tipo}-${r.fecha}`}
                          className="space-y-2 py-3 first:pt-0 last:pb-0"
                        >
                          <p className="text-sm font-medium">
                            {formatearFechaCorta(r.fecha)}
                          </p>
                          <dl className="space-y-1">
                            {MOMENTOS.map((m) => {
                              const valor = r[m.columna];
                              if (!valor) return null;

                              return (
                                <div
                                  key={m.columna}
                                  className="flex gap-3 text-sm"
                                >
                                  <dt className="w-28 shrink-0 text-muted-foreground">
                                    {m.etiqueta}
                                  </dt>
                                  <dd className="font-medium tabular-nums">
                                    {valor}
                                  </dd>
                                </div>
                              );
                            })}
                          </dl>
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
