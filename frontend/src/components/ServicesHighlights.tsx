import { FileSignature, Briefcase, Compass, Building, Scale, Handshake } from "lucide-react";
import { Card, CardHeader, CardTitle, CardContent } from "./ui/card";

const services = [
  {
    icon: FileSignature,
    title: "Estruturação da venda",
    description:
      "Valuation detalhada, planejamento de estratégia comercial e posicionamento premium nas principais praças.",
  },
  {
    icon: Briefcase,
    title: "Gestão patrimonial",
    description:
      "Orientação para diversificação de portfólio, maximização de rentabilidade e compliance com metas financeiras.",
  },
  {
    icon: Compass,
    title: "Inteligência de mercado",
    description:
      "Relatórios personalizados com indicadores de demanda, valor agregado por região e tendências de consumo.",
  },
  {
    icon: Building,
    title: "Soluções corporativas",
    description:
      "Intermediação de lajes corporativas, escritórios boutique e hubs logísticos com negociações sob medida.",
  },
  {
    icon: Scale,
    title: "Due diligence completa",
    description:
      "Equipe jurídica especializada cuidando da análise documental, regularização e mitigação de riscos.",
  },
  {
    icon: Handshake,
    title: "Experiência concierge",
    description:
      "Visitas privativas, negociação assistida e suporte pós-venda para mudança, mobiliário e facilities.",
  },
];

const ServicesHighlights = () => (
  <section id="servicos" className="py-24 bg-muted/20">
    <div className="container mx-auto px-4">
      <div className="max-w-3xl mx-auto text-center space-y-4 mb-14">
        <p className="uppercase text-xs tracking-[0.4em] text-primary font-semibold">
          Soluções completas
        </p>
        <h2 className="text-4xl md:text-5xl font-semibold text-foreground leading-tight">
          Um portfólio de serviços pensado para cada etapa da jornada imobiliária.
        </h2>
        <p className="text-lg text-muted-foreground leading-relaxed">
          Do planejamento à assinatura final, acompanhamos nossos clientes com transparência, confidencialidade e
          know-how técnico em negociações de alta complexidade.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {services.map(({ icon: Icon, title, description }) => (
          <Card
            key={title}
            className="h-full border border-border/70 bg-background/80 hover:border-primary/40 transition-colors duration-300 rounded-2xl"
          >
            <CardHeader className="pb-2">
              <div className="h-12 w-12 rounded-full bg-primary/10 text-primary flex items-center justify-center mb-4">
                <Icon className="h-6 w-6" />
              </div>
              <CardTitle className="text-lg font-semibold">{title}</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground leading-relaxed">{description}</p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  </section>
);

export default ServicesHighlights;

