import { redirect } from "next/navigation";

import { PRIMER_PASO } from "@/lib/pasos";

/** Atender siempre empieza por el primer paso. */
export default async function AtenderRaiz({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  redirect(`/pacientes/${id}/atender/${PRIMER_PASO}`);
}
