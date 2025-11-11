import { Badge } from "./ui/badge";
import { Card, CardContent, CardFooter } from "./ui/card";
import { Button } from "./ui/button";
import { Bed, Bath, Square, MapPin } from "lucide-react";
import { useNavigate } from "react-router-dom";
import type { Property } from "@/data/properties";
import { formatCurrency } from "@/data/properties";

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

  const handleClick = () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    navigate(`/propriedade/${id}`);
  };

  return (
    <Card className="overflow-hidden group hover:-translate-y-2 transition-all duration-300 border border-border/70 bg-card/90 backdrop-blur">
      <div className="relative overflow-hidden h-64">
        <img
          src={image}
          alt={title}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 ease-out"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/45 via-black/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
        <Badge className="absolute top-4 left-4 bg-property-badge text-white uppercase tracking-[0.15em]">
          {transaction}
        </Badge>
        <Badge className="absolute top-4 right-4 bg-background/80 text-foreground uppercase tracking-[0.15em]">
          {type}
        </Badge>
      </div>

      <CardContent className="p-6 space-y-4">
        <div>
          <h3 className="text-xl font-semibold text-foreground leading-snug line-clamp-2">
            {title}
          </h3>
          <div className="flex items-center text-muted-foreground mt-2">
            <MapPin className="h-4 w-4 mr-2 text-primary" />
            <span className="text-sm">
              {neighborhood}, {city} - {state}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-3 text-xs text-muted-foreground">
          <div className="flex flex-col items-center gap-1 border border-dashed border-border/80 rounded-md py-3">
            <Bed className="h-4 w-4 text-primary" />
            <span className="text-[0.7rem] font-semibold text-foreground">{bedrooms} dorms</span>
          </div>
          <div className="flex flex-col items-center gap-1 border border-dashed border-border/80 rounded-md py-3">
            <Bath className="h-4 w-4 text-primary" />
            <span className="text-[0.7rem] font-semibold text-foreground">{bathrooms} banhos</span>
          </div>
          <div className="flex flex-col items-center gap-1 border border-dashed border-border/80 rounded-md py-3">
            <Square className="h-4 w-4 text-primary" />
            <span className="text-[0.7rem] font-semibold text-foreground">{area} m²</span>
          </div>
        </div>

        <div>
          <p className="text-xs font-medium text-muted-foreground">Investimento</p>
          <p className="mt-2 text-3xl font-semibold text-primary">
            {formatCurrency(price)}
            {transaction === "ALUGUEL" ? " / mês" : ""}
          </p>
        </div>
      </CardContent>

      <CardFooter className="p-6 pt-0">
        <Button
          className="w-full bg-primary hover:bg-primary/90 text-primary-foreground font-semibold"
          onClick={handleClick}
        >
          Ver detalhes
        </Button>
      </CardFooter>
    </Card>
  );
};

export default PropertyCard;
