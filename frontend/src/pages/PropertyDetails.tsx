import { useParams, useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import ContactForm from "@/components/ContactForm";
import { Button } from "@/components/ui/button";
import { AspectRatio } from "@/components/ui/aspect-ratio";
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
} from "@/components/ui/carousel";
import { Bed, Bath, Square, MapPin, ArrowLeft, Phone, Mail, Car, Dumbbell, Waves, Shield } from "lucide-react";
import { Property, formatCurrency } from "@/data/properties";
import { API_BASE_URL } from "@/lib/api";
import { resolveMediaUrl } from "@/lib/media";

const PropertyDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [property, setProperty] = useState<Property | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [id]);

  useEffect(() => {
    if (!id) return;

    let active = true;

    const fetchProperty = async () => {
      setIsLoading(true);
      try {
        const response = await fetch(`${API_BASE_URL}/api/properties/${id}`);
        const data = await response.json().catch(() => null);
        if (!response.ok) {
          throw new Error("Falha ao carregar imovel.");
        }
        if (active) {
          setProperty(data);
        }
      } catch (error) {
        if (active) {
          setProperty(null);
        }
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    };

    fetchProperty();

    return () => {
      active = false;
    };
  }, [id]);

  const handleBackClick = () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    navigate("/");
  };

  const gallerySource = property?.gallery?.length
    ? property.gallery
    : property?.image
      ? [{ url: property.image, alt: property.title }]
      : [{ url: "/placeholder.svg", alt: "Imagem do imovel" }];

  const gallery = gallerySource.map((item) => ({
    ...item,
    url: resolveMediaUrl(item.url) || "/placeholder.svg",
    alt: item.alt || "Imagem do imovel",
  }));

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center text-muted-foreground">Carregando imovel...</div>
      </div>
    );
  }

  if (!property) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-foreground mb-4">Propriedade não encontrada</h1>
          <Button onClick={() => navigate("/")}>Voltar para o início</Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-foreground">
      <Header />
      <main className="pt-32 pb-24">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-10 text-sm text-muted-foreground">
            <button
              onClick={handleBackClick}
              className="inline-flex items-center gap-2 text-primary hover:text-primary/80 transition-colors"
            >
              <ArrowLeft className="h-4 w-4" />
              Voltar para o portfólio
            </button>
            <span>
              ID #{property.id.slice(0, 8)} • {property.type} • {property.area}m²
            </span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
            <div className="lg:col-span-2">
              <div className="relative rounded-3xl mb-8 shadow-2xl bg-card">
                <Carousel className="rounded-3xl">
                  <CarouselContent>
                    {gallery.map((media, index) => (
                      <CarouselItem key={media.url}>
                        <AspectRatio ratio={16 / 9} className="overflow-hidden rounded-3xl bg-muted">
                          <img
                            src={`${media.url}`}
                            alt={media.alt}
                            className="h-full w-full object-cover"
                            loading={index > 2 ? "lazy" : "eager"}
                          />
                        </AspectRatio>
                      </CarouselItem>
                    ))}
                  </CarouselContent>
                  <CarouselPrevious className="hidden md:flex border-none bg-background/80 hover:bg-background" />
                  <CarouselNext className="hidden md:flex border-none bg-background/80 hover:bg-background" />
                </Carousel>
              </div>

              <h1 className="text-4xl md:text-5xl font-semibold text-foreground leading-tight mb-4">
                {property.title}
              </h1>

              <div className="flex items-center text-muted-foreground mb-8 text-lg">
                <MapPin className="h-5 w-5 mr-2" />
                <span>
                  {property.neighborhood}, {property.city} - {property.state}
                </span>
              </div>

              <div className="flex flex-wrap items-center gap-6 mb-10 text-muted-foreground text-sm">
                <div className="flex items-center gap-3 border border-border/80 rounded-full px-5 py-3">
                  <Bed className="h-5 w-5" />
                  <span className="text-foreground font-medium">{property.bedrooms} dormitórios</span>
                </div>
                <div className="flex items-center gap-3 border border-border/80 rounded-full px-5 py-3">
                  <Bath className="h-5 w-5" />
                  <span className="text-foreground font-medium">{property.bathrooms} banhos</span>
                </div>
                <div className="flex items-center gap-3 border border-border/80 rounded-full px-5 py-3">
                  <Square className="h-5 w-5" />
                  <span className="text-foreground font-medium">{property.area} m² privativos</span>
                </div>
              </div>

              <div className="bg-card rounded-3xl p-8 mb-8 border border-border/60 shadow-lg">
                <h2 className="text-2xl font-semibold text-foreground mb-4">
                  Descrição
                </h2>
                <p className="text-muted-foreground leading-relaxed text-lg">
                  {property.description}
                </p>
              </div>

              <div className="bg-card rounded-3xl p-8 border border-border/60 shadow-lg">
                <h2 className="text-2xl font-semibold text-foreground mb-6">
                  Comodidades
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  {property.amenities.map((amenity, index) => {
                    const normalized = amenity.toLowerCase();
                    const hasPool = normalized.includes("piscina") || normalized.includes("prainha");
                    const hasGym = normalized.includes("academia") || normalized.includes("fitness");
                    const hasGarage = normalized.includes("vaga") || normalized.includes("garagem");
                    const hasSecurity = normalized.includes("seguranca") || normalized.includes("concierge");

                    return (
                      <div
                        key={index}
                        className="flex items-center gap-3 text-muted-foreground border border-dashed border-border/70 rounded-2xl px-4 py-3"
                      >
                        {hasPool && <Waves className="h-5 w-5 text-primary" />}
                        {hasGym && <Dumbbell className="h-5 w-5 text-primary" />}
                        {hasGarage && <Car className="h-5 w-5 text-primary" />}
                        {hasSecurity && <Shield className="h-5 w-5 text-primary" />}
                        {!hasPool && !hasGym && !hasGarage && !hasSecurity && (
                          <div className="h-2 w-2 rounded-full bg-primary" />
                        )}
                        <span className="text-sm font-medium text-foreground">{amenity}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

            <div className="lg:col-span-1 space-y-6">
              <div className="bg-card rounded-3xl p-8 border border-border/60 sticky top-32 shadow-xl">
                <p className="text-xs font-semibold text-muted-foreground mb-2">Investimento</p>
                <div className="text-4xl font-semibold text-primary mb-8">
                  {formatCurrency(property.price)}
                  {property.transaction === "ALUGUEL" ? " / mês" : ""}
                </div>

                <div className="space-y-4 mb-6">
                  <Button className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-semibold">
                    <Phone className="h-5 w-5 mr-2" />
                    Ligar Agora
                  </Button>
                  <Button variant="outline" className="w-full h-12 font-semibold">
                    <Mail className="h-5 w-5 mr-2" />
                    Enviar Mensagem
                  </Button>
                </div>

                <div className="pt-6 border-t border-border/60">
                  <h3 className="font-semibold text-foreground mb-4">
                    Informações do Imóvel
                  </h3>
                  <div className="space-y-3 text-sm text-muted-foreground">
                    <div className="flex justify-between">
                      <span>Tipologia</span>
                      <span className="text-foreground font-medium">{property.type}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Área Privativa</span>
                      <span className="text-foreground font-medium">{property.area} m²</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Dormitórios</span>
                      <span className="text-foreground font-medium">{property.bedrooms}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Banheiros</span>
                      <span className="text-foreground font-medium">{property.bathrooms}</span>
                    </div>
                  </div>
                </div>
              </div>

              <ContactForm defaultMessage={`Tenho interesse na propriedade "${property.title}".`} />
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default PropertyDetails;
