"use client";

import { useActionState, useState } from "react";
import { useFormStatus } from "react-dom";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { Paciente } from "@/lib/pacientes";

import { guardarPaciente, type EstadoFicha } from "./acciones";

const inicial: EstadoFicha = { error: null, guardado: false };

/** Solo los campos que este formulario edita. */
type Campos = {
  nombre: string;
  apellidos: string;
  cedula: string;
  telefono: string;
  fecha_nacimiento: string;
};

function aCampos(p: Paciente): Campos {
  return {
    nombre: p.nombre,
    apellidos: p.apellidos ?? "",
    cedula: p.cedula ?? "",
    telefono: p.telefono ?? "",
    fecha_nacimiento: p.fecha_nacimiento ?? "",
  };
}

/**
 * Los valores en una sola cadena, para saber si de verdad cambiaron.
 *
 * `JSON.stringify` y no un `join` con separador: cualquier caracter que se
 * elija como separador puede aparecer dentro de un dato, y ahi dos fichas
 * distintas darian la misma firma.
 */
function firmaDe(c: Campos) {
  return JSON.stringify([
    c.nombre,
    c.apellidos,
    c.cedula,
    c.telefono,
    c.fecha_nacimiento,
  ]);
}

/**
 * Los campos van controlados, no con `defaultValue`.
 *
 * Al guardar, la acción llama a `revalidatePath` y el servidor vuelve a
 * mandar la ficha. Con campos no controlados eso cambia el `defaultValue`
 * después de que el input ya se montó, y Base UI avisa —con razón— de que
 * nadie sabe cuál de los dos valores manda.
 *
 * El estado se vuelve a sincronizar solo cuando los datos que llegan del
 * servidor son distintos a los que se mostraron la última vez. Comparando el
 * contenido y no la identidad del objeto: el servidor manda un objeto nuevo en
 * cada render, y comparar identidades borraría lo que el doctor esté
 * escribiendo en ese momento.
 */
export function FormularioFicha({ paciente }: { paciente: Paciente }) {
  const [estado, enviar] = useActionState(guardarPaciente, inicial);

  const delServidor = aCampos(paciente);
  const [campos, setCampos] = useState(delServidor);
  const [ultimaFirma, setUltimaFirma] = useState(() => firmaDe(delServidor));

  const firmaNueva = firmaDe(delServidor);
  if (firmaNueva !== ultimaFirma) {
    setUltimaFirma(firmaNueva);
    setCampos(delServidor);
  }

  const cambiar = (id: keyof Campos) => (valor: string) =>
    setCampos((previos) => ({ ...previos, [id]: valor }));

  return (
    <form action={enviar} className="space-y-6">
      <input type="hidden" name="id" value={paciente.user_id} />

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo
          id="nombre"
          etiqueta="Nombre"
          valor={campos.nombre}
          onCambio={cambiar("nombre")}
          requerido
        />
        <Campo
          id="apellidos"
          etiqueta="Apellidos"
          valor={campos.apellidos}
          onCambio={cambiar("apellidos")}
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo
          id="cedula"
          etiqueta="Cédula"
          valor={campos.cedula}
          onCambio={cambiar("cedula")}
          ayuda="No se puede repetir entre pacientes."
        />
        <Campo
          id="telefono"
          etiqueta="Teléfono"
          valor={campos.telefono}
          onCambio={cambiar("telefono")}
          tipo="tel"
        />
      </div>

      <Campo
        id="fecha_nacimiento"
        etiqueta="Fecha de nacimiento"
        valor={campos.fecha_nacimiento}
        onCambio={cambiar("fecha_nacimiento")}
        tipo="date"
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
          Guardado.
        </p>
      )}

      <Guardar />
    </form>
  );
}

function Campo({
  id,
  etiqueta,
  valor,
  onCambio,
  tipo = "text",
  ayuda,
  requerido = false,
}: {
  id: string;
  etiqueta: string;
  valor: string;
  onCambio: (valor: string) => void;
  tipo?: string;
  ayuda?: string;
  requerido?: boolean;
}) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>{etiqueta}</Label>
      <Input
        id={id}
        name={id}
        type={tipo}
        value={valor}
        onChange={(e) => onCambio(e.target.value)}
        required={requerido}
        aria-describedby={ayuda ? `${id}-ayuda` : undefined}
      />
      {ayuda && (
        <p id={`${id}-ayuda`} className="text-xs text-muted-foreground">
          {ayuda}
        </p>
      )}
    </div>
  );
}

function Guardar() {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending}>
      {pending ? "Guardando…" : "Guardar"}
    </Button>
  );
}
