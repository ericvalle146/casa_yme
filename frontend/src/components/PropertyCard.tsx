import { Card, CardContent } from "./ui/card";
import { Button } from "./ui/button";
import { Bed, Bath, Square, MapPin } from "lucide-react";
import { useNavigate } from "react-router-dom";
import type { Property } from "@/data/properties";
import { formatCurrency } from "@/data/properties";
import { resolveMediaUrl } from "@/lib/media";
import { FavoriteButton } from "./FavoriteButton";

const PropertyCard = ({
  id,
  image,
  title,
  type,
  transaction,
  price,
  bedrooms,
  bathrooms,
  area,
  city,
  state,
  neighborhood,
}: Property) => {
  const navigate = useNavigate();
  const imageSrc = resolveMediaUrl(image) || "/placeholder.svg";

  const handleClick = () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    navigate(`/propriedade/${id}`);
  };

  return (
    <Card className="group flex h-full flex-col overflow-hidden border border-border/70 bg-card/95 transition-shadow duration-300 hover:shadow-lg">
      <div className="relative overflow-hidden h-52 bg-muted/30">
        <FavoriteButton propertyId={id} />
        <img
          src={imageSrc}
          alt={title}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 ease-out"
        />
      </div>

      <CardContent className="flex flex-1 flex-col gap-4 p-5">
        <div className="space-y-2">
          <h3 className="text-lg font-semibold text-foreground leading-snug line-clamp-2">
            {title}
          </h3>
          <div className="flex items-center text-muted-foreground text-sm">
            <MapPin className="h-4 w-4 mr-2 text-accent" />
            <span className="text-sm">
              {neighborhood}, {city} - {state}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-2 text-xs text-muted-foreground">
          <div className="flex flex-col items-center gap-1 rounded-md bg-muted/40 py-2">
            <Bed className="h-4 w-4 text-primary" />
            <span className="text-[0.7rem] font-semibold text-foreground">{bedrooms} dorms</span>
          </div>
          <div className="flex flex-col items-center gap-1 rounded-md bg-muted/40 py-2">
            <Bath className="h-4 w-4 text-primary" />
            <span className="text-[0.7rem] font-semibold text-foreground">{bathrooms} banhos</span>
          </div>
          <div className="flex flex-col items-center gap-1 rounded-md bg-muted/40 py-2">
            <Square className="h-4 w-4 text-primary" />
            <span className="text-[0.7rem] font-semibold text-foreground">{area} m²</span>
          </div>
        </div>

        <div className="mt-auto flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-[0.65rem] uppercase tracking-[0.2em] text-muted-foreground">Investimento</p>
            <p className="mt-1 text-2xl font-semibold text-primary">
              {formatCurrency(price)}
              {transaction === "ALUGUEL" ? " / mês" : ""}
            </p>
          </div>
          <Button
            size="sm"
            className="bg-primary hover:bg-primary/90 text-primary-foreground font-semibold"
            onClick={handleClick}
          >
            Ver detalhes
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default PropertyCard;
