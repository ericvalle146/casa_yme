import { useLocation, useNavigate } from "react-router-dom";
import { useEffect } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { Button } from "@/components/ui/button";

const NotFound = () => {
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    console.error("404 Error: User attempted to access non-existent route:", location.pathname);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [location.pathname]);

  const handleHomeClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    e.preventDefault();
    window.scrollTo({ top: 0, behavior: "smooth" });
    navigate("/");
  };

  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col">
      <Header />
      <main className="flex-1 flex items-center justify-center py-24">
        <div className="container mx-auto px-4">
          <div className="max-w-xl mx-auto text-center space-y-6">
            <p className="text-sm uppercase tracking-[0.2em] text-primary">Erro 404</p>
            <h1 className="text-4xl md:text-5xl font-semibold">
              A página que você procura não está disponível ou foi deslocada para outro endereço.
            </h1>
            <p className="text-lg text-muted-foreground leading-relaxed">
              Verifique se o link foi digitado corretamente ou utilize o botão abaixo para retornar à página inicial e
              conhecer nossas soluções imobiliárias.
            </p>
            <Button asChild className="h-12 px-8 text-sm font-semibold">
              <a href="/" onClick={handleHomeClick}>Voltar para a Casa YME</a>
            </Button>
          </div>
      </div>
      </main>
      <Footer />
    </div>
  );
};

export default NotFound;
