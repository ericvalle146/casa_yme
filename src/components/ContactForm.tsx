import { useState, useEffect } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Textarea } from "./ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { useToast } from "@/hooks/use-toast";

interface ContactFormProps {
  defaultMessage?: string;
}

const ContactForm = ({ defaultMessage = "" }: ContactFormProps) => {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    message: defaultMessage,
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    setFormData((prev) => ({ ...prev, message: defaultMessage }));
  }, [defaultMessage]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (isSubmitting) {
      return;
    }

    // Webhook do N8N - pode ser configurado via variável de ambiente
    const webhookUrl = (import.meta.env.VITE_WEBHOOK_URL as string | undefined) || 
                       "https://webhook.locusp.shop/webhook/mariana_imobiliaria";

    try {
      setIsSubmitting(true);

      const response = await fetch(webhookUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name: formData.name.trim(),
          email: formData.email.trim(),
          phone: formData.phone.trim(),
          message: formData.message.trim(),
          submittedAt: new Date().toISOString(),
        }),
      });

      if (!response.ok) {
        throw new Error("Falha ao enviar mensagem. Tente novamente.");
      }

      toast({
        title: "Mensagem enviada!",
        description: "Entraremos em contato em breve.",
      });
      setFormData({ name: "", email: "", phone: "", message: defaultMessage });
    } catch (error) {
      const err = error as Error;
      toast({
        title: "Não foi possível enviar",
        description: err.message || "Erro ao enviar mensagem. Verifique sua conexão.",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Card className="shadow-lg border border-border/70 bg-background/90 backdrop-blur rounded-2xl">
      <CardHeader className="pb-4">
        <CardTitle className="text-2xl font-semibold text-foreground">Converse com um especialista</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input
              placeholder="Nome completo"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
              className="h-12"
            />
            <Input
              type="tel"
              placeholder="Telefone"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              required
              className="h-12"
            />
          </div>
          <Input
            type="email"
            placeholder="E-mail corporativo"
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            required
            className="h-12"
          />
          <Textarea
            placeholder="Conte-nos sobre o imóvel desejado ou patrimônio a ser comercializado"
            value={formData.message}
            onChange={(e) => setFormData({ ...formData, message: e.target.value })}
            className="resize-none"
            rows={4}
            required
          />
          <p className="text-xs text-muted-foreground leading-relaxed">
            Ao enviar, você concorda com nossa Política de Privacidade e autoriza o contato por telefone, e-mail ou
            WhatsApp. Tratamos seus dados com confidencialidade.
          </p>
          <Button type="submit" className="w-full h-12 text-sm font-semibold" disabled={isSubmitting}>
            {isSubmitting ? "Enviando..." : "Enviar mensagem"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
};

export default ContactForm;
