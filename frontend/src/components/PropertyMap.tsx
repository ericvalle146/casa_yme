import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix para o ícone padrão do Leaflet não aparecer corretamente
// https://github.com/Leaflet/Leaflet/issues/4968
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

interface PropertyMapProps {
  latitude: number | null;
  longitude: number | null;
  title: string;
  address?: string;
  className?: string;
}

const PropertyMap = ({
  latitude,
  longitude,
  title,
  address,
  className = '',
}: PropertyMapProps) => {
  // Se não tiver coordenadas, mostrar placeholder
  if (!latitude || !longitude) {
    return (
      <div
        className={`flex items-center justify-center bg-muted/30 rounded-xl ${className || 'h-[400px]'}`}
      >
        <div className="text-center">
          <div className="text-muted-foreground mb-2">
            <svg
              className="mx-auto h-12 w-12"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
              />
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
              />
            </svg>
          </div>
          <p className="text-sm text-muted-foreground">
            Localização não disponível
          </p>
        </div>
      </div>
    );
  }

  return (
    <MapContainer
      center={[latitude, longitude]}
      zoom={15}
      scrollWheelZoom={false}
      className={`rounded-xl z-0 ${className || 'h-[400px]'}`}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <Marker position={[latitude, longitude]}>
        <Popup>
          <div className="p-1">
            <strong className="text-sm font-semibold">{title}</strong>
            {address && (
              <p className="text-xs text-muted-foreground mt-1">{address}</p>
            )}
          </div>
        </Popup>
      </Marker>
    </MapContainer>
  );
};

export default PropertyMap;
