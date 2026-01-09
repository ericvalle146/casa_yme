import PropertyCard from "./PropertyCard";
import type { Property } from "@/data/properties";

interface FeaturedPropertiesProps {
  properties: Property[];
}

const FeaturedProperties = ({ properties }: FeaturedPropertiesProps) => {
  return (
    <section id="destaques" className="py-24 bg-gradient-to-b from-background via-muted/40 to-background relative overflow-hidden">
      <div className="absolute inset-x-0 top-0 h-24 bg-gradient-to-b from-background/60 to-transparent pointer-events-none" />
      <div className="container mx-auto px-4 relative">
        <div className="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-6 mb-14">
          <div className="max-w-xl space-y-4">
            <p className="text-xs font-semibold text-primary uppercase tracking-[0.15em]">
              Casas e coberturas em destaque
            </p>
            <h2 className="text-4xl md:text-5xl font-semibold text-foreground leading-tight">
              Seleção curada de residências exclusivas à venda.
            </h2>
            <p className="text-lg text-muted-foreground">
              Explore projetos residenciais de alto padrão, com localização privilegiada, ambientes generosos e
              acabamento impecável.
            </p>
          </div>
          <p className="text-sm text-muted-foreground">
            Disponibilidade sujeita a alteração sem aviso prévio. Consulte nosso time para portfólio completo.
          </p>
        </div>
        
        {properties.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4 gap-5">
            {properties.map((property) => (
              <PropertyCard key={property.id} {...property} />
            ))}
          </div>
        ) : (
          <div className="rounded-2xl border border-dashed border-border/70 bg-card/80 p-12 text-center text-muted-foreground">
            No momento não há imóveis que atendam a esses filtros. Ajuste a pesquisa ou solicite nosso portfólio
            reservado.
          </div>
        )}
      </div>
    </section>
  );
};

export default FeaturedProperties;
