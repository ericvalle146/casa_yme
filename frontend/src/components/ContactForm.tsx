





























import { useState, useEffect } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Textarea } from "./ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { useToast } from "@/hooks/use-toast";
import { Mail, Phone } from "lucide-react";

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

  // Novo estado para método de contato
  const [contactMethod, setContactMethod] = useState<"whatsapp" | "email">("whatsapp");

  useEffect(() => {
    setFormData((prev) => ({ ...prev, message: defaultMessage }));
  }, [defaultMessage]);

  // Ícone WhatsApp (restaurado para a versão anterior)
  const WhatsAppIcon = ({ className = "w-4 h-4" }: { className?: string }) => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      aria-hidden
    >
      <path d="M20.52 3.48A11.93 11.93 0 0012 0C5.373 0 .021 4.818.001 11.395-.005 13.58.548 15.69 1.593 17.562L0 24l6.61-1.73A11.953 11.953 0 0012 24c6.627 0 11.98-4.818 12-11.395.02-3.263-1.285-6.282-3.48-8.125zM12 21.5c-1.762 0-3.48-.47-4.98-1.356l-.356-.205-3.918 1.02 1.06-3.82-.233-.38A9.5 9.5 0 1121.5 11.999 9.47 9.47 0 0112 21.5z" />
      <path d="M17.207 14.083l-1.108-.316a.75.75 0 00-.78.212l-.645.707a6.64 6.64 0 01-3.058-3.058l.706-.645a.75.75 0 00.212-.78l-.316-1.108A1.125 1.125 0 0010.5 7.5H9.375A1.125 1.125 0 008.25 8.625C8.25 14.1 13.9 19.75 19.375 19.75c1.238 0 1.875-.375 1.875-1.125V17.5c0-.494-.544-1.06-1.943-1.417z" />
      <path d="M15 9.5c-.1-.1-.3-.2-.5-.1-.6.2-1.3.6-1.8 1-.3.2-.6.5-.9.7-.2.2-.4.4-.6.6-.2.2-.4.3-.6.3-.2 0-.4-.1-.6-.2-.2-.1-.4-.2-.6-.3-.2-.1-.3-.1-.5 0-.2.1-.3.3-.4.5-.1.4-.1.8.1 1.1.3.6.8 1.1 1.4 1.6.6.5 1.3.9 2 1.2.6.3 1.3.4 1.9.3.2 0 .4-.1.6-.2.2-.1.4-.2.6-.4.2-.2.4-.4.5-.6.1-.3.1-.6 0-.9-.1-.3-.3-.6-.5-.9-.2-.3-.4-.6-.6-.8-.2-.2-.3-.3-.4-.4z" stroke="none" fill="white" opacity="0.001" />
    </svg>
  );

  const handleSubmit = async (e: React.FormEvent) => {
    // Prevent default navigation and stop other handlers from running
    e.preventDefault();
    e.stopPropagation();
    // In case any native listeners are present, try to stop them as well
    try {
      const ne = (e as unknown as { nativeEvent?: Event }).nativeEvent;
      if (ne && typeof (ne as Event).stopImmediatePropagation === "function") {
        (ne as Event).stopImmediatePropagation();
      }
    } catch (err) {
      // ignore
    }

    if (isSubmitting) {
      return;
    }

    const webhookUrl = (import.meta.env.VITE_WEBHOOK_URL as string | undefined) ||
      "https://webhook.locusup.shop/webhook/mariana_imobiliaria";

    try {
      // validação simples conforme método de contato
      if (contactMethod === "whatsapp") {
        if (!formData.phone.trim()) {
          toast({ title: "Por favor, informe o número de WhatsApp.", variant: "destructive" });
          return;
        }
      } else {
        if (!formData.email.trim()) {
          toast({ title: "Por favor, informe o e-mail.", variant: "destructive" });
          return;
        }
      }

      setIsSubmitting(true);

      const formTitle = "Fale com um especialista";

      // Tipagem do payload para evitar 'any'
      type WhatsappPayload = {
        number: string;
        display: string;
        prefilledMessage: string;
        note: string;
      };

      type EmailPayload = {
        address: string;
        subject: string;
        priority: string;
        note: string;
      };

      type FormPayload = {
        formTitle: string;
        name: string;
        message: string;
        contactMethod: "whatsapp" | "email";
        submittedAt: string;
        whatsapp?: WhatsappPayload | string | null;
        email?: EmailPayload | string | null;
        [key: string]: unknown;
      };

      const payloadBase: Partial<FormPayload> = {
        formTitle,
        name: formData.name.trim(),
        message: formData.message.trim(),
        contactMethod,
        submittedAt: new Date().toISOString(),
      };

      let payload: FormPayload;

      if (contactMethod === "whatsapp") {
        const cleaned = formData.phone.replace(/\D/g, "");
        payload = {
          ...payloadBase,
          whatsapp: {
            number: cleaned,
            display: formData.phone.trim(),
            prefilledMessage: formData.message.trim() || `Olá, tenho interesse.`,
            note: "Contato via WhatsApp solicitado pelo formulário",
          },
          email: formData.email.trim() || null,
        } as FormPayload;
      } else {
        payload = {
          ...payloadBase,
          email: {
            address: formData.email.trim(),
            subject: `Solicitação - ${formTitle}`,
            priority: "normal",
            note: "Contato via e-mail solicitado pelo formulário",
          },
          whatsapp: formData.phone.trim() || null,
        } as FormPayload;
      }

      // Always send to webhook only. Do not open external links or change location.
      const response = await fetch(webhookUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(30000),
      });

      if (!response.ok) {
        const errorText = await response.text().catch(() => "Erro desconhecido");
        throw new Error(`Falha ao enviar mensagem (${response.status}): ${errorText}`);
      }

      toast({ title: "Solicitação recebida", description: "Agradecemos. Entraremos em contato em breve." });

      // Explicitly avoid opening WhatsApp or navigating away
      // (no window.open, no location.assign)

      setFormData({ name: "", email: "", phone: "", message: defaultMessage });
    } catch (error) {
      const err = error as Error;
      let errorMessage = "Erro ao enviar mensagem. Verifique sua conexão.";

      if (err.message.includes("ERR_NAME_NOT_RESOLVED") || err.message.includes("Failed to fetch")) {
        errorMessage = "Não foi possível conectar ao servidor. Verifique se o domínio do webhook está configurado corretamente.";
      } else if (err.message.includes("timeout") || err.name === "TimeoutError") {
        errorMessage = "Tempo de espera esgotado. Tente novamente.";
      } else if (err.message) {
        errorMessage = err.message;
      }

      console.error("Erro ao enviar formulário:", err);
      toast({ title: "Não foi possível enviar", description: errorMessage, variant: "destructive" });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Card className="shadow-lg border border-border/70 bg-background/90 backdrop-blur rounded-2xl">
      <CardHeader className="pb-4">
        <div className="flex flex-col">
          <CardTitle className="text-2xl font-semibold text-foreground">Fale com um especialista</CardTitle>
          <span className="text-sm text-muted-foreground mt-1">Preencha seus dados e escolha o canal preferencial de contato. Responderemos o mais breve possível.</span>
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-4">
          <div className="flex gap-3">
            <button
              type="button"
              onClick={() => setContactMethod("whatsapp")}
              className={`flex items-center gap-2 px-3 py-2 rounded-md border text-sm ${contactMethod === "whatsapp" ? "bg-green-50 border-green-200 text-green-800" : "bg-transparent border-border/50"}`}
              aria-pressed={contactMethod === "whatsapp"}
              aria-label="Selecionar WhatsApp como canal de contato"
            >
              <WhatsAppIcon className="w-4 h-4" />
              <span>WhatsApp</span>
            </button>

            <button
              type="button"
              onClick={() => setContactMethod("email")}
              className={`flex items-center gap-2 px-3 py-2 rounded-md border text-sm ${contactMethod === "email" ? "bg-sky-50 border-sky-200 text-sky-800" : "bg-transparent border-border/50"}`}
              aria-pressed={contactMethod === "email"}
              aria-label="Selecionar E-mail como canal de contato"
            >
              <Mail className="w-4 h-4" />
              <span>E-mail</span>
            </button>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="sr-only">Nome completo</label>
              <Input
                placeholder="Nome completo"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
                className="h-12"
                aria-label="Nome completo"
              />
            </div>

            <div>
              {contactMethod === "whatsapp" ? (
                <>
                  <label className="sr-only">Número para contato (WhatsApp)</label>
                  <Input
                    // use text + inputMode to avoid some browsers turning the value into a clickable tel link
                    type="text"
                    inputMode="tel"
                    pattern="[0-9+ ]*"
                    autoComplete="tel"
                    placeholder="Número WhatsApp"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    onKeyDown={(e) => {
                      // Prevent Enter from triggering unexpected navigation in some environments
                      if (e.key === "Enter") {
                        e.preventDefault();
                        // submit via form handler instead
                        const form = (e.target as HTMLElement).closest("form");
                        if (form) form.dispatchEvent(new Event("submit", { cancelable: true, bubbles: true }));
                      }
                    }}
                    required
                    className="h-12"
                    aria-label="Número de WhatsApp"
                  />
                  <p className="text-xs text-muted-foreground mt-1">Ex.: 5511999999999 (código do país + DDD + número)</p>
                </>
              ) : (
                <>
                  <label className="sr-only">Endereço de e-mail corporativo</label>
                  <Input
                    type="email"
                    placeholder="E-mail corporativo"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    required
                    className="h-12"
                    aria-label="E-mail corporativo"
                  />
                  <p className="text-xs text-muted-foreground mt-1">Preferimos e-mails corporativos para comunicações formais.</p>
                </>
              )}
            </div>
          </div>

          <div>
            <label className="sr-only">Mensagem</label>
            <Textarea
              placeholder="Descreva brevemente o interesse ou o imóvel desejado"
              value={formData.message}
              onChange={(e) => setFormData({ ...formData, message: e.target.value })}
              className="resize-none"
              rows={4}
              required
              aria-label="Mensagem"
            />
          </div>

          <p className="text-xs text-muted-foreground leading-relaxed">
            Ao submeter este formulário, você concorda com nossa Política de Privacidade. Seus dados serão utilizados exclusivamente para atendimento e pré-qualificação.
          </p>

          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <Button type="submit" className="w-full sm:w-auto h-12 text-sm font-semibold" disabled={isSubmitting}>
              {isSubmitting ? "Enviando..." : "Solicitar contato"}
            </Button>

            <div className="text-xs text-muted-foreground">
              <div className="flex items-center gap-2">
                <Phone className="w-4 h-4 text-muted-foreground" />
                <span>Atendimento de segunda a sexta, 9h–18h</span>
              </div>
            </div>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}

export default ContactForm;
