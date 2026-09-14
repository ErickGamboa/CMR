import { Paso, PasoPendiente } from "../paso";

export default async function PasoLaboratorios({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  return (
    <Paso clave="laboratorios" id={id}>
      <PasoPendiente detalle="Cargar un examen con sus analitos, cada uno con valor, unidad, referencia y si salió fuera de rango." />
    </Paso>
  );
}
