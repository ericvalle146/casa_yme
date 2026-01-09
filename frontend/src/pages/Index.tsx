import Header from "@/components/Header";
import Hero from "@/components/Hero";
import FeaturedProperties from "@/components/FeaturedProperties";
import Footer from "@/components/Footer";
import ContactCTA from "@/components/ContactCTA";
import SearchForm from "@/components/SearchForm";
import { useEffect, useMemo, useState } from "react";
import { Property, TransactionType } from "@/data/properties";
import { useToast } from "@/hooks/use-toast";
import { API_BASE_URL } from "@/lib/api";

const Index = () => {
  const [properties, setProperties] = useState<Property[]>([]);
  const [filteredProperties, setFilteredProperties] = useState<Property[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const { toast } = useToast();

  const cities = useMemo(() => {
    const cityEntries = Array.from(
      new Set(properties.map((property) => `${property.city}__${property.state}`)),
    );

    return cityEntries.map((entry) => {
      const [city, state] = entry.split("__");
      return { label: `${city} - ${state}`, city, state };
    });
  }, []);

  const neighborhoodsByCity = useMemo(() => {
    const map = new Map<string, string[]>();
    properties.forEach((property) => {
      const key = `${property.city}__${property.state}`;
      const existing = map.get(key) ?? [];
      if (!existing.includes(property.neighborhood)) {
        existing.push(property.neighborhood);
        map.set(key, existing);
      }
    });
    return map;
  }, []);

  const propertyTypes = useMemo(
    () => Array.from(new Set(properties.map((property) => property.type))),
    [properties],
  );

  const bedroomOptions = useMemo(
    () =>
      Array.from(new Set(properties.map((property) => property.bedrooms)))
        .sort((a, b) => a - b)
        .map((value) => value.toString()),
    [properties],
  );

  useEffect(() => {
    let active = true;

    const fetchProperties = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/api/properties`);
        const data = await response.json().catch(() => []);
        if (!response.ok) {
          throw new Error("Falha ao carregar imoveis.");
        }
        if (active) {
          setProperties(Array.isArray(data) ? data : []);
          setFilteredProperties(Array.isArray(data) ? data : []);
        }
      } catch (error) {
        if (active) {
          toast({
            title: "Nao foi possivel carregar os imoveis",
            description: "Verifique a conexao com a API e tente novamente.",
            variant: "destructive",
          });
        }
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    };

    fetchProperties();

    return () => {
      active = false;
    };
  }, [toast]);

  const handleSearch = (filters: {
    transaction?: TransactionType | "INVESTIMENTO" | "";
    city?: string;
    state?: string;
    neighborhood?: string;
    type?: string;
    bedrooms?: number;
    minValue?: number;
    maxValue?: number;
  }) => {
    const results = properties.filter((property) => {
      if (filters.transaction && filters.transaction !== "INVESTIMENTO") {
        if (property.transaction !== filters.transaction) {
          return false;
        }
      }

      if (filters.city && filters.state) {
        if (property.city !== filters.city || property.state !== filters.state) {
          return false;
        }
      }

      if (filters.neighborhood && property.neighborhood !== filters.neighborhood) {
        return false;
      }

      if (filters.type && property.type !== filters.type) {
        return false;
      }

      if (filters.bedrooms && property.bedrooms < filters.bedrooms) {
        return false;
      }

      if (typeof filters.minValue === "number" && property.price < filters.minValue) {
        return false;
      }

      if (typeof filters.maxValue === "number" && property.price > filters.maxValue) {
        return false;
      }

      return true;
    });

    setFilteredProperties(results);

    if (results.length === 0) {
      toast({
        title: "Nenhum imóvel encontrado",
        description:
          "Ajuste os filtros ou solicite um portfólio reservado para receber opções exclusivas.",
      });
    } else {
      toast({
        title: "Busca atualizada",
        description: `${results.length} ${
          results.length === 1 ? "opção encontrada" : "opções encontradas"
        }`,
      });
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground">
      <Header />
      <main>
        <Hero
          renderSearchForm={() => (
            <SearchForm
              cities={cities}
              neighborhoodsByCity={neighborhoodsByCity}
              propertyTypes={propertyTypes}
              bedroomOptions={bedroomOptions}
              onSearch={handleSearch}
            />
          )}
        />
        <FeaturedProperties properties={filteredProperties} />
        {isLoading && (
          <div className="container mx-auto px-4 -mt-12">
            <div className="rounded-2xl border border-dashed border-border/70 bg-card/80 p-6 text-center text-muted-foreground">
              Carregando imoveis...
            </div>
          </div>
        )}
        <ContactCTA />
      </main>
      <Footer />
    </div>
  );
};

export default Index;
