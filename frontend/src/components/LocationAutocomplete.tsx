import { useState } from 'react';
import { useDebounce } from 'use-debounce';
import { useQuery } from '@tanstack/react-query';
import { Check, ChevronsUpDown, MapPin } from 'lucide-react';
import { API_BASE_URL } from '@/lib/api';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from '@/components/ui/command';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';

interface Location {
  city: string;
  state: string;
  neighborhood: string;
}

interface LocationAutocompleteProps {
  value?: Location | null;
  onChange: (location: Location | null) => void;
  placeholder?: string;
  className?: string;
}

const LocationAutocomplete = ({
  value,
  onChange,
  placeholder = 'Buscar localização...',
  className = '',
}: LocationAutocompleteProps) => {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [debouncedSearch] = useDebounce(search, 300);

  const { data: locations = [], isLoading } = useQuery({
    queryKey: ['locations-autocomplete', debouncedSearch],
    queryFn: async () => {
      const response = await fetch(
        `${API_BASE_URL}/api/properties/autocomplete/locations?q=${encodeURIComponent(debouncedSearch)}`
      );
      if (!response.ok) {
        throw new Error('Erro ao buscar localizações');
      }
      return response.json();
    },
    enabled: debouncedSearch.length >= 2,
    staleTime: 1000 * 60 * 5, // Cache por 5 minutos
  });

  const formatLocationLabel = (loc: Location | null) => {
    if (!loc) return placeholder;
    const parts = [];
    if (loc.neighborhood) parts.push(loc.neighborhood);
    if (loc.city) parts.push(loc.city);
    if (loc.state) parts.push(loc.state);
    return parts.join(', ') || placeholder;
  };

  const formatLocationDisplay = (loc: Location) => {
    const parts = [];
    if (loc.neighborhood) parts.push(loc.neighborhood);
    if (loc.city) parts.push(loc.city);
    if (loc.state) parts.push(loc.state);
    return parts.join(', ');
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className={cn(
            'w-full justify-between',
            !value && 'text-muted-foreground',
            className
          )}
        >
          <div className="flex items-center gap-2 truncate">
            <MapPin className="h-4 w-4 flex-shrink-0" />
            <span className="truncate">{formatLocationLabel(value)}</span>
          </div>
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[--radix-popover-trigger-width] p-0" align="start">
        <Command shouldFilter={false}>
          <CommandInput
            placeholder="Digite cidade, bairro ou estado..."
            value={search}
            onValueChange={setSearch}
          />
          <CommandList>
            {isLoading && (
              <div className="py-6 text-center text-sm">
                Buscando localizações...
              </div>
            )}
            {!isLoading && debouncedSearch.length >= 2 && locations.length === 0 && (
              <CommandEmpty>Nenhuma localização encontrada.</CommandEmpty>
            )}
            {!isLoading && debouncedSearch.length < 2 && (
              <div className="py-6 text-center text-sm text-muted-foreground">
                Digite pelo menos 2 caracteres para buscar
              </div>
            )}
            {!isLoading && locations.length > 0 && (
              <CommandGroup>
                {locations.map((location: Location, index: number) => {
                  const key = `${location.city}-${location.neighborhood}-${index}`;
                  const isSelected =
                    value?.city === location.city &&
                    value?.state === location.state &&
                    value?.neighborhood === location.neighborhood;

                  return (
                    <CommandItem
                      key={key}
                      value={key}
                      onSelect={() => {
                        onChange(isSelected ? null : location);
                        setOpen(false);
                        setSearch('');
                      }}
                    >
                      <Check
                        className={cn(
                          'mr-2 h-4 w-4',
                          isSelected ? 'opacity-100' : 'opacity-0'
                        )}
                      />
                      <div className="flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-muted-foreground" />
                        <span>{formatLocationDisplay(location)}</span>
                      </div>
                    </CommandItem>
                  );
                })}
              </CommandGroup>
            )}
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
};

export default LocationAutocomplete;
