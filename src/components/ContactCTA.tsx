import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";
import ContactForm from "./ContactForm";
import { Phone, CalendarDays } from "lucide-react";

const ContactCTA = () => (
  <section id="contato" className="py-24 bg-gradient-to-br from-secondary/40 via-secondary/20 to-background">
    <div className="container mx-auto px-4">
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-10 items-start">
        <div className="lg:col-span-2 space-y-6">
          <p className="uppercase text-xs tracking-[0.2em] text-primary font-semibold">
            Contato personalizado
          </p>
          <h2 className="text-4xl md:text-5xl font-semibold text-foreground leading-tight">
            Vamos desenhar juntos sua próxima conquista imobiliária.
          </h2>
          <p className="text-lg text-muted-foreground leading-relaxed">
            Envie suas informações ou agende um horário para conhecer nosso portfólio reservado. Garantimos
            confidencialidade, atendimento consultivo e acompanhamento em todas as etapas.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm text-muted-foreground">
            <Card className="border border-border/70 bg-background/80">
              <CardContent className="p-6 space-y-3">
                <div className="flex items-center gap-3">
                  <Phone className="h-5 w-5 text-primary" />
                  <span className="uppercase tracking-[0.15em] text-primary font-semibold">Central exclusiva</span>
                </div>
                <div>
                  <p className="text-foreground font-semibold text-lg">(11) 3333-4444</p>
                  <p>Seg a sex — 9h às 19h | Sáb — 9h às 14h</p>
                </div>
              </CardContent>
            </Card>
            <Card className="border border-border/70 bg-background/80">
              <CardContent className="p-6 space-y-3">
                <div className="flex items-center gap-3">
                  <CalendarDays className="h-5 w-5 text-primary" />
                  <span className="uppercase tracking-[0.15em] text-primary font-semibold">Visitas privativas</span>
                </div>
                <div>
                  <p>Atendimento presencial em São Paulo, Rio de Janeiro e Belo Horizonte mediante agendamento.</p>
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="flex flex-col sm:flex-row gap-3">
            <Button className="px-6 py-6 bg-primary hover:bg-primary/90 text-white font-semibold">
              Agendar consultoria
            </Button>
            <Button variant="outline" className="px-6 py-6 border-primary text-primary hover:bg-primary/10 font-semibold">
              Receber portfólio reservado
            </Button>
          </div>
        </div>

        <div className="lg:col-span-3">
          <ContactForm />
        </div>
      </div>
    </div>
  </section>
);

export default ContactCTA;

