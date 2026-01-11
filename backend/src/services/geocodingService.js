import { geocoder } from '../config/geocoding.js';
import { logger } from '../config/logger.js';

/**
 * Serviço de geocodificação - converte endereços em coordenadas GPS
 */
export const geocodingService = {
  /**
   * Converte um endereço completo em coordenadas geográficas
   * @param {string} address - Endereço completo
   * @returns {Promise<{latitude: number|null, longitude: number|null, formattedAddress: string|null}>}
   */
  geocodeAddress: async (address) => {
    try {
      if (!address || address.trim().length < 10) {
        logger.warn({ address }, 'Endereço muito curto para geocoding');
        return { latitude: null, longitude: null, formattedAddress: null };
      }

      logger.info({ address }, 'Iniciando geocoding do endereço');

      const results = await geocoder.geocode(address);

      if (!results || results.length === 0) {
        logger.warn({ address }, 'Nenhum resultado encontrado no geocoding');
        return { latitude: null, longitude: null, formattedAddress: null };
      }

      const result = results[0];

      logger.info(
        {
          address,
          latitude: result.latitude,
          longitude: result.longitude,
          formatted: result.formattedAddress
        },
        'Geocoding realizado com sucesso'
      );

      return {
        latitude: result.latitude,
        longitude: result.longitude,
        formattedAddress: result.formattedAddress || null
      };
    } catch (error) {
      logger.error({ error, address }, 'Erro ao realizar geocoding');
      // Não bloqueia a criação do imóvel, apenas retorna null
      return { latitude: null, longitude: null, formattedAddress: null };
    }
  },

  /**
   * Constrói um endereço completo a partir de componentes individuais
   * @param {Object} components - Componentes do endereço
   * @param {string} components.street - Rua/Avenida
   * @param {string} components.number - Número
   * @param {string} components.neighborhood - Bairro
   * @param {string} components.city - Cidade
   * @param {string} components.state - Estado
   * @param {string} components.zipCode - CEP
   * @returns {string} Endereço formatado
   */
  buildFullAddress: ({ street, number, neighborhood, city, state, zipCode }) => {
    const parts = [
      street,
      number,
      neighborhood,
      city,
      state,
      zipCode
    ].filter(Boolean); // Remove valores vazios ou undefined

    return parts.join(', ');
  },

  /**
   * Calcula a distância entre duas coordenadas usando a fórmula de Haversine
   * @param {number} lat1 - Latitude do ponto 1
   * @param {number} lon1 - Longitude do ponto 1
   * @param {number} lat2 - Latitude do ponto 2
   * @param {number} lon2 - Longitude do ponto 2
   * @returns {number} Distância em quilômetros
   */
  calculateDistance: (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Raio da Terra em km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) *
      Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;

    return distance;
  }
};
