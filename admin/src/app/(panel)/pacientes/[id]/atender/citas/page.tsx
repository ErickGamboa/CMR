import { BorrarFila } from "@/components/borrar-fila";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LUGAR_POR_DEFECTO, TIPOS_CITA } from "@/lib/catalogos";
import { formatearFechaHora } from "@/lib/fechas";
import { clienteServidor } from "@/lib/supabase/servidor";

import { Paso } from "../paso";
import { borrarCita } from "./acciones";
import { FormularioCita } from "./formulario";

type Fila = {
  id: string;
  fecha: string;
  tipo: string;
  profesional: string;
  especialidad: string;
  lugar: string;
};

export default async function PasoCitas({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await clienteServidor();

  const { data } = await supabase
    .from("citas")
    .select("id, fecha, tipo, profesional, especialidad, lugar")
    .eq("paciente_id", id)
    .order("fecha", { ascending: false });

  const citas = (data ?? []) as Fila[];
  const ahora = new Date();

  // `fecha` viene sin zona: se compara armando la fecha local a partir del
  // texto, no con `new Date(texto)`, que la leería como UTC.
  const esFutura = (f: string) => {
    const [dia, hora = "00:00:00"] = f.split("T");
    const [a, m, d] = dia.split("-").map(Number);
    const [hh, mm] = hora.split(":").map(Number);
    return new Date(a, m - 1, d, hh, mm) > ahora;
  };

  const pendientes = citas.filter((c) => esFutura(c.fecha));
  const pasadas = citas.filter((c) => !esFutura(c.fecha));
  const titulo = (t: string) =>
    TIPOS_CITA.find((x) => x.valor === t)?.titulo ?? t;

  return (
    <Paso clave="citas" id={id}>
      <div className="grid gap-6 lg:grid-cols-[minmax(0,24rem)_minmax(0,1fr)] lg:items-start">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Agendar</CardTitle>
          </CardHeader>
          <CardContent>
            <FormularioCita paciente={id} lugar={LUGAR_POR_DEFECTO} />
          </CardContent>
        </Card>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">
                Pendientes
                {pendientes.length > 0 && (
                  <span className="ml-2 font-normal text-muted-foreground">
                    {pendientes.length}
                  </span>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {pendientes.length === 0 ? (
                <p className="py-4 text-center text-sm text-muted-foreground">
                  No tiene citas agendadas.
                </p>
              ) : (
                <Lista citas={pendientes} id={id} titulo={titulo} />
              )}
            </CardContent>
          </Card>

          {pasadas.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">
                  Anteriores
                  <span className="ml-2 font-normal text-muted-foreground">
                    {pasadas.length}
                  </span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Lista citas={pasadas} id={id} titulo={titulo} atenuadas />
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </Paso>
  );
}

function Lista({
  citas,
  id,
  titulo,
  atenuadas = false,
}: {
  citas: Fila[];
  id: string;
  titulo: (t: string) => string;
  atenuadas?: boolean;
}) {
  return (
    <ul className="divide-y">
      {citas.map((c) => (
        <li
          key={c.id}
          className="flex items-start gap-3 py-3 first:pt-0 last:pb-0"
        >
          <div
            className={`min-w-0 flex-1 space-y-0.5 ${atenuadas ? "opacity-60" : ""}`}
          >
            <p className="text-sm font-medium">{formatearFechaHora(c.fecha)}</p>
            <p className="text-sm text-muted-foreground">
              {titulo(c.tipo)} · {c.profesional} · {c.especialidad}
            </p>
            <p className="text-xs text-muted-foreground/80">{c.lugar}</p>
          </div>

          <BorrarFila
            que="esta cita"
            detalle={formatearFechaHora(c.fecha)}
            onBorrar={async () => {
              "use server";
              return borrarCita(id, c.id);
            }}
          />
        </li>
      ))}
    </ul>
  );
}
