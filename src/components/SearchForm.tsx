import { useMemo, useState } from "react";
import { Button } from "./ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import { Input } from "./ui/input";
import { cn } from "@/lib/utils";
import type { TransactionType } from "@/data/properties";

interface SearchFormProps {
  cities: { label: string; city: string; state: string }[];
  neighborhoodsByCity: Map<string, string[]>;
  propertyTypes: string[];
  bedroomOptions: string[];
  onSearch: (filters: {
    transaction?: TransactionType | "INVESTIMENTO" | "";
    city?: string;
    state?: string;
    neighborhood?: string;
    type?: string;
    bedrooms?: number;
    minValue?: number;
    maxValue?: number;
  }) => void;
}

const objectiveToTransaction: Record<string, TransactionType | "INVESTIMENTO"> = {
  comprar: "VENDA",
  alugar: "ALUGUEL",
  investir: "INVESTIMENTO",
};

const sanitizeCurrencyInput = (value: string) => value.replace(/\D/g, "");

const parseCurrency = (value: string) => {
  const sanitized = sanitizeCurrencyInput(value);
  if (!sanitized) {
    return undefined;
  }
  const parsed = Number.parseInt(sanitized, 10);
  return Number.isNaN(parsed) ? undefined : parsed;
};

const formatInputCurrency = (value: string) => {
  const sanitized = sanitizeCurrencyInput(value);
  if (!sanitized) {
    return "";
  }
  const parsed = Number.parseInt(sanitized, 10);
  if (Number.isNaN(parsed)) {
    return value;
  }
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
    minimumFractionDigits: 0,
  })
    .format(parsed)
    .replace("R$", "")
    .trim();
};

const SearchForm = ({
  cities,
  neighborhoodsByCity,
  propertyTypes,
  bedroomOptions,
  onSearch,
}: SearchFormProps) => {
  const [objective, setObjective] = useState<string>("");
  const [cityKey, setCityKey] = useState<string>("");
  const [neighborhood, setNeighborhood] = useState<string>("");
  const [propertyType, setPropertyType] = useState<string>("");
  const [bedrooms, setBedrooms] = useState<string>("");
  const [minInvestment, setMinInvestment] = useState<string>("");
  const [maxInvestment, setMaxInvestment] = useState<string>("");

  const neighborhoodsOptions = useMemo(() => {
    if (!cityKey) {
      return [];
    }
    return neighborhoodsByCity.get(cityKey) ?? [];
  }, [cityKey, neighborhoodsByCity]);

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    const filters: {
      transaction?: TransactionType | "INVESTIMENTO" | "";
      city?: string;
      state?: string;
      neighborhood?: string;
      type?: string;
      bedrooms?: number;
      minValue?: number;
      maxValue?: number;
    } = {};

    if (objective) {
      filters.transaction = objectiveToTransaction[objective];
    }

    if (cityKey) {
      const [city, state] = cityKey.split("__");
      filters.city = city;
      filters.state = state;
    }

    if (neighborhood) {
      filters.neighborhood = neighborhood;
    }

    if (propertyType) {
      filters.type = propertyType;
    }

    if (bedrooms) {
      const parsedBedrooms = Number.parseInt(bedrooms, 10);
      if (!Number.isNaN(parsedBedrooms)) {
        filters.bedrooms = parsedBedrooms;
      }
    }

    const minValue = parseCurrency(minInvestment);
    if (typeof minValue === "number") {
      filters.minValue = minValue;
    }

    const maxValue = parseCurrency(maxInvestment);
    if (typeof maxValue === "number") {
      filters.maxValue = maxValue;
    }

    onSearch(filters);
  };

  const handleCityChange = (value: string) => {
    setCityKey(value);
    setNeighborhood("");
  };

  const handleMinChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { value } = event.target;
    setMinInvestment(formatInputCurrency(value));
  };

  const handleMaxChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { value } = event.target;
    setMaxInvestment(formatInputCurrency(value));
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="w-full max-w-5xl ml-auto bg-card/95 backdrop-blur-sm rounded-2xl shadow-2xl border border-white/40 p-6 md:p-8"
    >
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
        <div>
          <h2 className="text-lg font-semibold text-foreground text-left">Selecione seu perfil</h2>
          <p className="mt-2 text-sm text-muted-foreground text-left max-w-md">
            Personalize sua busca e receba imóveis que correspondem ao seu estilo de vida e objetivos.
          </p>
        </div>
        <div className="text-xs uppercase tracking-[0.15em] text-muted-foreground">
          Filtros combináveis
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        <Select value={objective} onValueChange={setObjective}>
          <SelectTrigger className="w-full bg-background h-12">
            <SelectValue placeholder="Objetivo" />
          </SelectTrigger>
          <SelectContent className="bg-popover">
            <SelectItem value="comprar">Aquisição</SelectItem>
            <SelectItem value="alugar">Locação</SelectItem>
            <SelectItem value="investir">Investimento</SelectItem>
          </SelectContent>
        </Select>

        <Select value={cityKey} onValueChange={handleCityChange}>
          <SelectTrigger className="w-full bg-background h-12">
            <SelectValue placeholder="Cidade" />
          </SelectTrigger>
          <SelectContent className="bg-popover">
            {cities.map(({ label, city, state }) => (
              <SelectItem key={`${city}__${state}`} value={`${city}__${state}`}>
                {label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select
          value={neighborhood}
          onValueChange={setNeighborhood}
          disabled={!neighborhoodsOptions.length}
        >
          <SelectTrigger className={cn("w-full bg-background h-12", { "text-muted-foreground": !cityKey })}>
            <SelectValue placeholder="Bairro" />
          </SelectTrigger>
          <SelectContent className="bg-popover">
            {neighborhoodsOptions.map((item) => (
              <SelectItem key={item} value={item}>
                {item}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={propertyType} onValueChange={setPropertyType}>
          <SelectTrigger className="w-full bg-background h-12">
            <SelectValue placeholder="Tipologia" />
          </SelectTrigger>
          <SelectContent className="bg-popover">
            {propertyTypes.map((type) => (
              <SelectItem key={type} value={type}>
                {type}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={bedrooms} onValueChange={setBedrooms}>
          <SelectTrigger className="w-full bg-background h-12">
            <SelectValue placeholder="Dormitórios (mínimo)" />
          </SelectTrigger>
          <SelectContent className="bg-popover">
            {bedroomOptions.map((option) => (
              <SelectItem key={option} value={option}>
                {option} {Number(option) === 1 ? "dormitório" : "dormitórios"}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <div className="grid grid-cols-2 gap-3">
          <Input
            className="h-12 bg-background"
            placeholder="Investimento mínimo (R$)"
            value={minInvestment}
            onChange={handleMinChange}
            inputMode="numeric"
          />
          <Input
            className="h-12 bg-background"
            placeholder="Investimento máximo (R$)"
            value={maxInvestment}
            onChange={handleMaxChange}
            inputMode="numeric"
          />
        </div>

        <Button
          type="submit"
          className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-semibold"
        >
          Pesquisar agora
        </Button>
      </div>

      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 text-sm text-muted-foreground">
        <p>
          Preferência por imóveis confidenciais?{" "}
          <span className="text-primary font-medium">Solicite portfólio reservado.</span>
        </p>
        <Button type="button" variant="outline" className="border-primary text-primary hover:bg-primary/10">
          Pesquisa por código
        </Button>
      </div>
    </form>
  );
};

export default SearchForm;
