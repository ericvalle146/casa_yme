export type TransactionType = "VENDA" | "ALUGUEL";

export interface Property {
  id: string;
  image: string | null;
  title: string;
  type: string;
  transaction: TransactionType;
  price: number;
  bedrooms: number;
  bathrooms: number;
  area: number;
  neighborhood: string;
  city: string;
  state: string;
  description: string;
  amenities: string[];
  gallery?: { id?: string; url: string; alt: string; position?: number; isCover?: boolean }[];
}

export const formatCurrency = (value: number) =>
  new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
    minimumFractionDigits: 0,
  }).format(value);
