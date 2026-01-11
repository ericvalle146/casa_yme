import { Heart } from 'lucide-react';
import { Button } from './ui/button';
import { useFavorites } from '@/hooks/useFavorites';
import { useAuth } from '@/context/AuthContext';
import { cn } from '@/lib/utils';
import { toast } from 'sonner';

interface FavoriteButtonProps {
  propertyId: string;
  className?: string;
  variant?: 'default' | 'floating';
}

/**
 * Botão de favoritar/desfavoritar imóvel
 * - Variante 'default': botão normal
 * - Variante 'floating': botão flutuante sobre imagem (padrão)
 */
export const FavoriteButton = ({
  propertyId,
  className,
  variant = 'floating'
}: FavoriteButtonProps) => {
  const { user } = useAuth();
  const { isFavorited, toggleFavorite, isLoading } = useFavorites(propertyId);

  const handleClick = async (e: React.MouseEvent) => {
    e.stopPropagation(); // Prevenir navegação se estiver dentro de um link
    e.preventDefault();

    if (!user) {
      toast.error('Faça login para favoritar imóveis', {
        description: 'Você precisa estar logado para usar esta funcionalidade'
      });
      return;
    }

    toggleFavorite(undefined, {
      onSuccess: (data) => {
        if (data.isFavorited) {
          toast.success('Imóvel favoritado!', {
            description: 'Você pode ver seus favoritos no seu perfil'
          });
        } else {
          toast.success('Removido dos favoritos');
        }
      },
      onError: (error) => {
        toast.error('Erro ao favoritar', {
          description: error.message
        });
      }
    });
  };

  const baseClasses = 'transition-all duration-200 hover:scale-110';
  const variantClasses = variant === 'floating'
    ? 'absolute top-3 right-3 z-10 rounded-full bg-white/90 hover:bg-white shadow-md'
    : '';

  return (
    <Button
      variant="ghost"
      size="icon"
      className={cn(baseClasses, variantClasses, className)}
      onClick={handleClick}
      disabled={isLoading}
      title={isFavorited ? 'Remover dos favoritos' : 'Adicionar aos favoritos'}
    >
      <Heart
        className={cn(
          'h-5 w-5 transition-colors',
          isFavorited ? 'fill-red-500 text-red-500' : 'text-gray-600 hover:text-red-400'
        )}
      />
    </Button>
  );
};
