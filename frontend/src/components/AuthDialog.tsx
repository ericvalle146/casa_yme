import { useEffect, useState, type FormEvent } from "react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "./ui/dialog";
import { Input } from "./ui/input";
import { Button } from "./ui/button";
import { useToast } from "@/hooks/use-toast";
import { API_BASE_URL } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";

type AuthDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
};

const AuthDialog = ({ open, onOpenChange }: AuthDialogProps) => {
  const [form, setForm] = useState({ email: "", password: "" });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { toast } = useToast();
  const { login } = useAuth();

  useEffect(() => {
    if (!open) {
      setForm({ email: "", password: "" });
      setIsSubmitting(false);
    }
  }, [open]);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();

    if (isSubmitting) return;

    const endpoint = "/api/auth/login";
    const payload = { email: form.email.trim(), password: form.password };

    setIsSubmitting(true);

    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        const message = data?.error || "Não foi possível autenticar. Verifique os dados e tente novamente.";
        throw new Error(message);
      }

      if (!data?.accessToken || !data?.refreshToken || !data?.user) {
        throw new Error("Resposta inválida do servidor de autenticação.");
      }

      login({
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
        user: data.user,
      });
      onOpenChange(false);

      toast({
        title: "Login realizado",
        description: `Bem-vindo(a), ${data.user.name}.`,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Erro inesperado ao autenticar.";
      toast({
        title: "Falha na autenticação",
        description: message,
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Área de acesso</DialogTitle>
          <DialogDescription>Entre com suas credenciais para acessar o painel administrativo.</DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="sr-only">E-mail</label>
            <Input
              type="email"
              placeholder="E-mail"
              value={form.email}
              onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
              autoComplete="email"
              required
            />
          </div>
          <div>
            <label className="sr-only">Senha</label>
            <Input
              type="password"
              placeholder="Senha"
              value={form.password}
              onChange={(event) => setForm((prev) => ({ ...prev, password: event.target.value }))}
              autoComplete="current-password"
              required
            />
          </div>
          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting ? "Entrando..." : "Entrar"}
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default AuthDialog;
