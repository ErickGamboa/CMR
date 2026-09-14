"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { Campo } from "@/components/campo";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { TIPOS_CITA } from "@/lib/catalogos";

import { guardarCita, type Resultado } from "./acciones";

const SIN_ENVIAR: Resultado = { error: null, guardado: false };

export function FormularioCita({
  paciente,
  lugar,
}: {
  paciente: string;
  lugar: string;
}) {
  const [estado, enviar] = useActionState(guardarCita, SIN_ENVIAR);

  return (
    <form action={enviar} className="space-y-6">
      <input type="hidden" name="paciente" value={paciente} />

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo id="fecha" etiqueta="Fecha" tipo="date" requerido />
        <Campo
          id="hora"
          etiqueta="Hora"
          tipo="time"
          requerido
          ayuda="La hora del reloj de la clínica."
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="tipo">Tipo</Label>
        <select
          id="tipo"
          name="tipo"
          defaultValue="medica"
          className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 md:text-sm"
        >
          {TIPOS_CITA.map((t) => (
            <option key={t.valor} value={t.valor}>
              {t.titulo}
            </option>
          ))}
        </select>
      </div>

      <Campo
        id="profesional"
        etiqueta="Quién la atiende"
        placeholder="Dr. Nombre Apellido"
        requerido
      />
      <Campo
        id="especialidad"
        etiqueta="De qué es"
        placeholder="Control metabólico"
        requerido
      />
      <Campo id="lugar" etiqueta="Lugar" defaultValue={lugar} requerido />

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
          Cita agendada.
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
      {pending ? "Guardando…" : "Agendar cita"}
    </Button>
  );
}
