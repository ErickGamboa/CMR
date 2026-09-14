import type { Metadata } from "next";

import { Volver } from "@/components/volver";
import { Card, CardContent } from "@/components/ui/card";

import { FormularioAlta } from "./formulario";

export const metadata: Metadata = { title: "Nuevo paciente · CMR" };

export default function PaginaNuevoPaciente() {
  return (
    <div className="animate-in fade-in duration-300 mx-auto max-w-2xl space-y-6">
      <header className="space-y-3">
        <Volver href="/pacientes">Pacientes</Volver>
        <h1 className="text-3xl font-semibold tracking-tight">
          Nuevo paciente
        </h1>
        <p className="max-w-prose text-sm leading-relaxed text-muted-foreground">
          Para pacientes que no van a crear la cuenta ellos mismos. Queda
          aprobada de una y con una contraseña temporal que le vas a poder
          dictar. El correo importa: es por donde el paciente recupera su
          contraseña si se le olvida.
        </p>
      </header>

      <Card>
        <CardContent>
          <FormularioAlta />
        </CardContent>
      </Card>
    </div>
  );
}
