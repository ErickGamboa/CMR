"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { Campo } from "@/components/campo";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";

import { guardarRecomendacion, type Resultado } from "./acciones";

const SIN_ENVIAR: Resultado = { error: null, guardado: false };

export type Icono = { nombre: string; etiqueta: string };

export function FormularioRecomendacion({
  paciente,
  hoy,
  iconos,
}: {
  paciente: string;
  hoy: string;
  iconos: Icono[];
}) {
  const [estado, enviar] = useActionState(guardarRecomendacion, SIN_ENVIAR);

  return (
    <form action={enviar} className="space-y-6">
      <input type="hidden" name="paciente" value={paciente} />

      <Campo
        id="titulo"
        etiqueta="Título"
        placeholder="Sube la proteína en el desayuno"
        requerido
      />

      <div className="space-y-2">
        <Label htmlFor="texto">Recomendación</Label>
        <textarea
          id="texto"
          name="texto"
          rows={4}
          required
          placeholder="Apunta a 30 g de proteína antes de las 10 a.m."
          className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 md:text-sm"
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="icono">Ícono</Label>
          {/* La lista sale de la tabla `iconos`, que es el espejo del catálogo
              cerrado de la app: un nombre que no esté ahí saldría genérico. */}
          <select
            id="icono"
            name="icono"
            defaultValue="consejo"
            className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 md:text-sm"
          >
            {iconos.map((i) => (
              <option key={i.nombre} value={i.nombre}>
                {i.etiqueta}
              </option>
            ))}
          </select>
        </div>

        <Campo id="fecha" etiqueta="Fecha" tipo="date" defaultValue={hoy} />
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
          Recomendación guardada.
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
      {pending ? "Guardando…" : "Agregar recomendación"}
    </Button>
  );
}
