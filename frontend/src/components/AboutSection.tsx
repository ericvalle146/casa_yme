import { ShieldCheck, Award, Users2 } from "lucide-react";
import { Card, CardContent } from "./ui/card";

const AboutSection = () => {
  const highlights = [
    {
      icon: ShieldCheck,
      title: "Governança e diligência",
      description:
        "Processos rigorosos de compliance, análise documental e avaliação jurídica em cada negociação.",
    },
    {
      icon: Award,
      title: "Atendimento consultivo",
      description:
        "Especialistas dedicados aos segmentos residencial, corporativo e investimentos com atendimento personalizado.",
    },
    {
      icon: Users2,
      title: "Rede de relacionamento",
      description:
        "Parcerias estratégicas com incorporadoras, escritórios de arquitetura e private bankers para oportunidades exclusivas.",
    },
  ];

  return (
    <section id="sobre" className="py-24 bg-background">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="space-y-6">
            <p className="uppercase text-xs tracking-[0.4em] text-primary font-semibold">
              Sobre a Casa YME
            </p>
            <h2 className="text-4xl md:text-5xl font-semibold leading-tight text-foreground">
              Consultoria imobiliária boutique comprometida com resultados consistentes.
            </h2>
            <p className="text-lg text-muted-foreground leading-relaxed">
              Atuamos como parceiros estratégicos na aquisição, venda e locação de imóveis de alto padrão,
              oferecendo análise de mercado precisa, curadoria de oportunidades e acompanhamento completo até a
              conclusão da transação. Nossa abordagem é centrada na confidencialidade, eficiência e na criação de
              patrimônio sólido.
            </p>
            <div className="grid grid-cols-2 gap-6 text-sm text-muted-foreground">
              <div>
                <p className="uppercase tracking-[0.35em] text-primary font-semibold">Missão</p>
                <p className="mt-3 leading-relaxed">
                  Reconhecer o verdadeiro valor de cada projeto e conectar pessoas a espaços que refletem seus
                  ideais.
                </p>
              </div>
              <div>
                <p className="uppercase tracking-[0.35em] text-primary font-semibold">Visão</p>
                <p className="mt-3 leading-relaxed">
                  Ser referência em excelência consultiva, elevando a experiência imobiliária com inovação e ética.
                </p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {highlights.map(({ icon: Icon, title, description }) => (
              <Card key={title} className="bg-muted/20 border border-border/60 rounded-2xl">
                <CardContent className="p-6 space-y-4">
                  <div className="h-12 w-12 rounded-full bg-primary/10 text-primary flex items-center justify-center">
                    <Icon className="h-6 w-6" />
                  </div>
                  <div className="space-y-2">
                    <h3 className="text-base font-semibold text-foreground">{title}</h3>
                    <p className="text-sm leading-relaxed text-muted-foreground">{description}</p>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default AboutSection;

