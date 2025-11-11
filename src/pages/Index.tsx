import Header from "@/components/Header";
import Hero from "@/components/Hero";
import FeaturedProperties from "@/components/FeaturedProperties";
import Footer from "@/components/Footer";
import ContactCTA from "@/components/ContactCTA";
import SearchForm from "@/components/SearchForm";
import { useMemo, useState } from "react";
import { properties as allProperties, Property, TransactionType } from "@/data/properties";
import { useToast } from "@/hooks/use-toast";

const Index = () => {
  const [filteredProperties, setFilteredProperties] = useState<Property[]>(allProperties);
  const { toast } = useToast();

  const cities = useMemo(() => {
    const cityEntries = Array.from(
      new Set(allProperties.map((property) => `${property.city}__${property.state}`)),
    );

    return cityEntries.map((entry) => {
      const [city, state] = entry.split("__");
      return { label: `${city} - ${state}`, city, state };
    });
  }, []);

  const neighborhoodsByCity = useMemo(() => {
    const map = new Map<string, string[]>();
    allProperties.forEach((property) => {
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
    () => Array.from(new Set(allProperties.map((property) => property.type))),
    [],
  );

  const bedroomOptions = useMemo(
    () =>
      Array.from(new Set(allProperties.map((property) => property.bedrooms)))
        .sort((a, b) => a - b)
        .map((value) => value.toString()),
    [],
  );

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
    const results = allProperties.filter((property) => {
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
        <ContactCTA />
      </main>
      <Footer />
    </div>
  );
};

export default Index;
