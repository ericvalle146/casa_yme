import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { API_BASE_URL } from '@/lib/api';
import { useAuth } from '@/context/AuthContext';

/**
 * Faz toggle de um favorito (adiciona ou remove)
 */
const toggleFavoriteApi = async (propertyId: string, token: string) => {
  const response = await fetch(`${API_BASE_URL}/api/favorites/toggle`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ propertyId }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Erro ao favoritar');
  }

  return response.json();
};

/**
 * Verifica se um imóvel está favoritado
 */
const checkFavoriteApi = async (propertyId: string, token: string) => {
  const response = await fetch(`${API_BASE_URL}/api/favorites/check/${propertyId}`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    return { isFavorited: false };
  }

  return response.json();
};

/**
 * Hook para gerenciar favoritos de um imóvel
 * @param propertyId - ID do imóvel
 */
export const useFavorites = (propertyId: string) => {
  const { accessToken, user } = useAuth();
  const queryClient = useQueryClient();

  // Verifica se o imóvel está favoritado
  const { data, isLoading: isChecking } = useQuery({
    queryKey: ['favorite', propertyId],
    queryFn: () => checkFavoriteApi(propertyId, accessToken!),
    enabled: !!user && !!accessToken,
    staleTime: 1000 * 60 * 5, // 5 minutos
  });

  // Mutation para fazer toggle do favorito
  const mutation = useMutation({
    mutationFn: () => toggleFavoriteApi(propertyId, accessToken!),
    onSuccess: () => {
      // Invalida queries relacionadas
      queryClient.invalidateQueries({ queryKey: ['favorite', propertyId] });
      queryClient.invalidateQueries({ queryKey: ['favorites'] });
    },
  });

  return {
    isFavorited: data?.isFavorited ?? false,
    toggleFavorite: mutation.mutate,
    isLoading: mutation.isPending || isChecking,
    isError: mutation.isError,
    error: mutation.error,
  };
};

/**
 * Hook para listar todos os favoritos do usuário
 */
export const useFavoritesList = () => {
  const { accessToken, user } = useAuth();

  return useQuery({
    queryKey: ['favorites'],
    queryFn: async () => {
      const response = await fetch(`${API_BASE_URL}/api/favorites`, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      if (!response.ok) {
        throw new Error('Erro ao carregar favoritos');
      }

      return response.json();
    },
    enabled: !!user && !!accessToken,
  });
};
