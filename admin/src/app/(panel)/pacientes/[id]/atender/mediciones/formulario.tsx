"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { Campo } from "@/components/campo";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";

import { guardarMedicion, type Resultado } from "./acciones";

const SIN_ENVIAR: Resultado = { error: null, guardado: false };

export function FormularioMedicion({
  paciente,
  hoy,
}: {
  paciente: string;
  hoy: string;
}) {
  const [estado, enviar] = useActionState(guardarMedicion, SIN_ENVIAR);

  return (
    <form action={enviar} className="space-y-6">
      <input type="hidden" name="paciente" value={paciente} />

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo
          id="fecha"
          etiqueta="Fecha"
          tipo="date"
          defaultValue={hoy}
          max={hoy}
          requerido
          ayuda="Una medición por día: si ya hay una, se corrige."
        />
        <Campo
          id="peso"
          etiqueta="Peso"
          sufijo="kg"
          inputMode="decimal"
          placeholder="88.9"
          requerido
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo
          id="porcentaje_grasa"
          etiqueta="Grasa corporal"
          sufijo="%"
          inputMode="decimal"
          placeholder="28.4"
          requerido
        />
        <Campo
          id="grasa_visceral"
          etiqueta="Grasa visceral"
          inputMode="decimal"
          placeholder="9"
          requerido
          ayuda="El índice que da el equipo."
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo
          id="grasa_perdida"
          etiqueta="Grasa perdida"
          sufijo="kg"
          inputMode="decimal"
          placeholder="0"
          ayuda="Acumulada desde que empezó el plan."
        />
        <Campo
          id="musculo_ganado"
          etiqueta="Músculo ganado"
          sufijo="kg"
          inputMode="decimal"
          placeholder="0"
          ayuda="Acumulado, no contra la medición anterior."
        />
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
          Medición guardada.
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
      {pending ? "Guardando…" : "Guardar medición"}
    </Button>
  );
}
