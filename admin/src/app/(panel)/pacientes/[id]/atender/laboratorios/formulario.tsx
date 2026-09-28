"use client";

import { useActionState, useState } from "react";
import { useFormStatus } from "react-dom";

import { Campo } from "@/components/campo";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import { guardarLaboratorio, type Resultado } from "./acciones";

const SIN_ENVIAR: Resultado = { error: null, guardado: false };

export type Analito = { id: string; nombre: string; unidad: string };

const LIBRES = ["1", "2", "3"] as const;

/**
 * Cargar un examen.
 *
 * Los 21 analitos que mide la clínica ya están escritos con su unidad: lo
 * único que se llena es el número de los que el laboratorio reportó. Lo que
 * quede en blanco no se guarda, así que un hemograma y un perfil completo se
 * cargan con el mismo formulario.
 */
export function FormularioLaboratorio({
  paciente,
  hoy,
  analitos,
}: {
  paciente: string;
  hoy: string;
  analitos: Analito[];
}) {
  const [estado, enviar] = useActionState(guardarLaboratorio, SIN_ENVIAR);
  const [otros, setOtros] = useState(0);

  // Los campos se vacían al guardar. Sin esto quedan escritos los valores del
  // examen anterior y el siguiente se carga con números que no son suyos. La
  // llave va en un div de adentro: en el <form> desmontaría la acción.
  const [ronda, setRonda] = useState(0);
  const [ultimo, setUltimo] = useState(estado);

  if (ultimo !== estado) {
    setUltimo(estado);
    if (estado.guardado) {
      setRonda((r) => r + 1);
      setOtros(0);
    }
  }

  return (
    <form action={enviar} className="space-y-6">
      <input type="hidden" name="paciente" value={paciente} />

      <div key={ronda} className="space-y-6">
        <div className="grid gap-4 sm:grid-cols-2">
          <Campo
            id="fecha"
            etiqueta="Fecha del examen"
            tipo="date"
            defaultValue={hoy}
            requerido
          />
          <Campo
            id="nombre"
            etiqueta="Qué examen es"
            defaultValue="Perfil metabólico"
            requerido
          />
        </div>

        <div className="space-y-3">
          <p className="text-sm text-muted-foreground">
            Escribí solo los que trae el reporte. Lo que quede en blanco no se
            guarda.
          </p>

          <div className="grid gap-x-6 gap-y-3 sm:grid-cols-2 xl:grid-cols-3">
            {analitos.map((a) => (
              <div
                key={a.id}
                className="flex items-center gap-3 rounded-lg border px-3 py-2 transition-colors focus-within:border-primary/50"
              >
                <Label
                  htmlFor={`valor.${a.id}`}
                  className="min-w-0 flex-1 text-sm font-normal leading-snug"
                >
                  {a.nombre}
                </Label>
                <Input
                  id={`valor.${a.id}`}
                  name={`valor.${a.id}`}
                  inputMode="decimal"
                  autoComplete="off"
                  placeholder="–"
                  className="h-8 w-20 shrink-0 border-0 bg-muted/50 text-center tabular-nums shadow-none"
                />
                <span className="w-14 shrink-0 text-xs text-muted-foreground">
                  {a.unidad}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Lo que el laboratorio reportó y no está en el catálogo. Aparece
            solo si se pide: tres filas vacías arriba nada más estorban. */}
        {otros > 0 && (
          <div className="space-y-3">
            {LIBRES.slice(0, otros).map((n) => (
              <div key={n} className="grid gap-3 sm:grid-cols-[1fr_6rem_6rem]">
                <Input
                  name={`libre.nombre.${n}`}
                  placeholder="Nombre del analito"
                  aria-label={`Nombre del analito ${n}`}
                />
                <Input
                  name={`libre.valor.${n}`}
                  placeholder="Valor"
                  aria-label={`Valor del analito ${n}`}
                  className="text-center tabular-nums"
                />
                <Input
                  name={`libre.unidad.${n}`}
                  placeholder="Unidad"
                  aria-label={`Unidad del analito ${n}`}
                />
              </div>
            ))}
          </div>
        )}

        {otros < LIBRES.length && (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={() => setOtros((n) => n + 1)}
            className="-ml-2"
          >
            Agregar otro analito
          </Button>
        )}
      </div>

      {estado.error && (
        <Alert variant="destructive" className="animate-in fade-in">
          <AlertDescription>{estado.error}</AlertDescription>
        </Alert>
      )}
      {estado.guardado && !estado.error && (
        <p
          role="status"
          className="animate-in fade-in text-sm text-muted-foreground"
        >
          Examen cargado.
        </p>
      )}

      <Guardar />
    </form>
  );
}

function Guardar() {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending}>
      {pending ? "Guardando…" : "Cargar examen"}
    </Button>
  );
}
