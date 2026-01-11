import { useQuery } from '@tanstack/react-query';
import { API_BASE_URL } from '@/lib/api';
import PropertyCard from './PropertyCard';

interface NearbyPropertiesProps {
  propertyId: string;
  limit?: number;
}

const NearbyProperties = ({ propertyId, limit = 6 }: NearbyPropertiesProps) => {
  const { data: properties = [], isLoading, isError } = useQuery({
    queryKey: ['nearby-properties', propertyId],
    queryFn: async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/properties/${propertyId}/nearby?limit=${limit}`
      );
      if (!response.ok) {
        throw new Error('Erro ao carregar imóveis próximos');
      }
      return response.json();
    },
    enabled: !!propertyId,
  });

  // Se estiver carregando
  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {[1, 2, 3, 4, 5, 6].map((i) => (
          <div
            key={i}
            className="h-96 bg-muted/30 animate-pulse rounded-xl"
          />
        ))}
      </div>
    );
  }

  // Se houver erro
  if (isError) {
    return (
      <div className="text-center py-12">
        <p className="text-muted-foreground">
          Erro ao carregar imóveis próximos
        </p>
      </div>
    );
  }

  // Se não houver imóveis próximos
  if (!properties || properties.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-muted-foreground">
          Nenhum imóvel próximo encontrado
        </p>
      </div>
    );
  }

  return (
    <div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {properties.map((property: any) => (
          <div key={property.id} className="relative">
            <PropertyCard {...property} />
            {property.distance && (
              <div className="absolute top-3 left-3 bg-primary text-primary-foreground px-3 py-1 rounded-full text-xs font-semibold z-10">
                {property.distance} km
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default NearbyProperties;
