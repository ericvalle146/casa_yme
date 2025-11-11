import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Avatar, AvatarFallback } from "./ui/avatar";

const testimonials = [
  {
    name: "Mariana Azevedo",
    role: "Family Office • São Paulo",
    initial: "MA",
    testimonial:
      "A ImóvelPro tratou nossa família com discrição e entregou oportunidades que não estavam disponíveis publicamente. O nível de diligência e a capacidade de negociação impressionam.",
  },
  {
    name: "Eduardo Henrique",
    role: "Empresário • Rio de Janeiro",
    initial: "EH",
    testimonial:
      "Experiência impecável do início ao fim. Recebi análises completas, suporte jurídico e um serviço concierge que tornou todo o processo muito mais ágil.",
  },
  {
    name: "Juliana Costa",
    role: "Diretora Financeira • Belo Horizonte",
    initial: "JC",
    testimonial:
      "O time entende profundamente o mercado. Conseguimos reestruturar nosso portfólio imobiliário com foco em rentabilidade e redução de riscos.",
  },
];

const Testimonials = () => (
  <section id="depoimentos" className="py-24 bg-secondary/40">
    <div className="container mx-auto px-4">
      <div className="max-w-2xl mx-auto text-center space-y-4 mb-14">
        <p className="uppercase text-xs tracking-[0.4em] text-primary font-semibold">
          Depoimentos reais
        </p>
        <h2 className="text-4xl md:text-5xl font-semibold text-foreground leading-tight">
          Reconhecimento de quem confia em nossa consultoria.
        </h2>
        <p className="text-lg text-muted-foreground leading-relaxed">
          Clientes corporativos e familiares que contam com nossa assessoria exclusiva para transformar projetos
          imobiliários em ativos estratégicos.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {testimonials.map((item) => (
          <Card
            key={item.name}
            className="h-full border border-border/70 bg-background/90 backdrop-blur rounded-2xl"
          >
            <CardHeader className="flex flex-col items-center gap-4">
              <Avatar className="h-12 w-12">
                <AvatarFallback className="bg-primary/10 text-primary font-semibold">{item.initial}</AvatarFallback>
              </Avatar>
              <div>
                <CardTitle className="text-lg font-semibold text-foreground text-center">{item.name}</CardTitle>
                <p className="text-xs uppercase tracking-[0.3em] text-muted-foreground text-center mt-1">
                  {item.role}
                </p>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-sm leading-relaxed text-muted-foreground text-center">
                “{item.testimonial}”
              </p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  </section>
);

export default Testimonials;


