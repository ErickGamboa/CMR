"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { Campo } from "@/components/campo";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { TIPOS_PRESCRIPCION } from "@/lib/catalogos";

import { guardarPrescripcion, type Resultado } from "./acciones";

const SIN_ENVIAR: Resultado = { error: null, guardado: false };

export function FormularioPrescripcion({ paciente }: { paciente: string }) {
  const [estado, enviar] = useActionState(guardarPrescripcion, SIN_ENVIAR);

  return (
    <form action={enviar} className="space-y-6">
      <input type="hidden" name="paciente" value={paciente} />

      <div className="space-y-2">
        <Label htmlFor="tipo">Tipo</Label>
        {/* El tipo decide en qué módulo de la app aparece, así que se dice. */}
        <select
          id="tipo"
          name="tipo"
          defaultValue="suplemento"
          className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 md:text-sm"
        >
          {TIPOS_PRESCRIPCION.map((t) => (
            <option key={t.valor} value={t.valor}>
              {t.titulo} — sale en {t.donde}
            </option>
          ))}
        </select>
      </div>

      <Campo
        id="nombre"
        etiqueta="Nombre"
        placeholder="Vitamina D3"
        requerido
      />

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo id="dosis" etiqueta="Dosis" placeholder="2000 UI" requerido />
        <Campo
          id="frecuencia"
          etiqueta="Frecuencia"
          placeholder="Diario"
          requerido
        />
      </div>

      <Campo
        id="indicacion"
        etiqueta="Indicación"
        placeholder="Con el desayuno"
        ayuda="Opcional: cómo o cuándo tomarlo."
      />

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
          Agregado.
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
      {pending ? "Guardando…" : "Agregar"}
    </Button>
  );
}
