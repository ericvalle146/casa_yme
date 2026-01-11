import { useNavigate } from "react-router-dom";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import PropertyCard from "@/components/PropertyCard";
import { useFavoritesList } from "@/hooks/useFavorites";
import { useAuth } from "@/context/AuthContext";
import { Button } from "@/components/ui/button";
import { Heart, ArrowLeft } from "lucide-react";

const Favorites = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { data: favorites = [], isLoading, isError } = useFavoritesList();

  // Se não está logado, redirecionar ou mostrar mensagem
  if (!user) {
    return (
      <div className="min-h-screen bg-background">
        <Header />
        <main className="pt-32 pb-24">
          <div className="container mx-auto px-4">
            <div className="flex flex-col items-center justify-center min-h-[50vh] text-center">
              <Heart className="h-16 w-16 text-muted-foreground mb-4" />
              <h1 className="text-3xl font-bold text-foreground mb-4">
                Faça login para ver seus favoritos
              </h1>
              <p className="text-muted-foreground mb-8">
                Você precisa estar logado para acessar seus imóveis favoritos.
              </p>
              <Button onClick={() => navigate("/")}>
                Voltar para o início
              </Button>
            </div>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="pt-32 pb-24">
        <div className="container mx-auto px-4">
          {/* Breadcrumb / Voltar */}
          <button
            onClick={() => navigate("/")}
            className="inline-flex items-center gap-2 text-primary hover:text-primary/80 transition-colors mb-8"
          >
            <ArrowLeft className="h-4 w-4" />
            Voltar para o portfólio
          </button>

          {/* Header da página */}
          <div className="mb-10">
            <div className="flex items-center gap-3 mb-3">
              <Heart className="h-8 w-8 text-primary fill-primary" />
              <h1 className="text-4xl md:text-5xl font-bold text-foreground">
                Meus Favoritos
              </h1>
            </div>
            <p className="text-muted-foreground text-lg">
              {isLoading
                ? "Carregando seus favoritos..."
                : favorites.length > 0
                  ? `Você tem ${favorites.length} ${favorites.length === 1 ? "imóvel favorito" : "imóveis favoritos"}`
                  : "Você ainda não tem imóveis favoritos"}
            </p>
          </div>

          {/* Loading state */}
          {isLoading && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {[1, 2, 3, 4, 5, 6].map((i) => (
                <div
                  key={i}
                  className="h-96 bg-muted/30 animate-pulse rounded-xl"
                />
              ))}
            </div>
          )}

          {/* Error state */}
          {isError && (
            <div className="flex flex-col items-center justify-center min-h-[40vh] text-center">
              <p className="text-muted-foreground mb-4">
                Erro ao carregar favoritos. Tente novamente.
              </p>
              <Button onClick={() => window.location.reload()}>
                Recarregar
              </Button>
            </div>
          )}

          {/* Empty state */}
          {!isLoading && !isError && favorites.length === 0 && (
            <div className="flex flex-col items-center justify-center min-h-[40vh] text-center">
              <Heart className="h-16 w-16 text-muted-foreground mb-4" />
              <h2 className="text-2xl font-semibold text-foreground mb-2">
                Nenhum favorito ainda
              </h2>
              <p className="text-muted-foreground mb-8 max-w-md">
                Explore nosso portfólio e favorite os imóveis que você mais gostou
                clicando no ícone de coração.
              </p>
              <Button onClick={() => navigate("/")}>
                Explorar imóveis
              </Button>
            </div>
          )}

          {/* Grid de favoritos */}
          {!isLoading && !isError && favorites.length > 0 && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {favorites.map((property: any) => (
                <PropertyCard key={property.id} {...property} />
              ))}
            </div>
          )}
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default Favorites;
