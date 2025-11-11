import { Card, CardContent } from "./ui/card";
import { ArrowRight } from "lucide-react";

const steps = [
  {
    title: "Imersão estratégica",
    description:
      "Entendimento profundo dos objetivos, perfil patrimonial, critérios de investimento e prazos desejados.",
  },
  {
    title: "Curadoria dedicada",
    description:
      "Seleção criteriosa de oportunidades on e off-market, com relatórios comparativos e visitas privativas.",
  },
  {
    title: "Negociação assistida",
    description:
      "Gestão completa de propostas, alinhamento entre partes, definição de cláusulas e condução transparente.",
  },
  {
    title: "Fechamento e pós-venda",
    description:
      "Suporte com escrituras, financiamentos, seguros e integração com serviços de arquitetura e facilities.",
  },
];

const AdvisoryProcess = () => (
  <section className="py-24 bg-background">
    <div className="container mx-auto px-4">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-10 items-start">
        <div className="lg:col-span-1 space-y-5">
          <p className="uppercase text-xs tracking-[0.4em] text-primary font-semibold">
            Método proprietário
          </p>
          <h2 className="text-4xl md:text-5xl font-semibold text-foreground leading-tight">
            Um processo consultivo transparente, pautado em dados e relacionamento.
          </h2>
          <p className="text-lg text-muted-foreground">
            Nossa atuação combina inteligência de mercado, negociação estratégica e acompanhamento jurídico para que
            cada decisão seja tomada com confiança, no tempo certo.
          </p>
        </div>

        <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-6">
          {steps.map((step, index) => (
            <Card
              key={step.title}
              className="relative overflow-hidden border border-border/60 rounded-2xl group bg-secondary/20 hover:bg-secondary/40 transition-colors"
            >
              <CardContent className="p-8 space-y-5">
                <div className="flex items-center justify-between">
                  <span className="text-sm uppercase tracking-[0.3em] text-muted-foreground">
                    Etapa {String(index + 1).padStart(2, "0")}
                  </span>
                  <ArrowRight className="h-5 w-5 text-primary opacity-0 group-hover:opacity-100 transition-opacity" />
                </div>
                <h3 className="text-xl font-semibold text-foreground">{step.title}</h3>
                <p className="text-sm leading-relaxed text-muted-foreground">{step.description}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </div>
  </section>
);

export default AdvisoryProcess;


