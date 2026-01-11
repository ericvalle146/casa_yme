import NodeGeocoder from 'node-geocoder';
import { logger } from './logger.js';

/**
 * Configuração do geocoder usando OpenStreetMap Nominatim
 * Gratuito e sem necessidade de API key
 *
 * Rate limit recomendado: 1 request por segundo
 * Documentação: https://nominatim.org/release-docs/latest/api/Search/
 */
const geocoder = NodeGeocoder({
  provider: 'openstreetmap',
  httpAdapter: 'https',
  formatter: null,
  // User-Agent é requerido pelo Nominatim
  extra: {
    headers: {
      'User-Agent': 'CasaYME/1.0 (contato@casayme.com.br)'
    }
  }
});

logger.info('Geocoder configurado com OpenStreetMap Nominatim (gratuito)');

export { geocoder };
