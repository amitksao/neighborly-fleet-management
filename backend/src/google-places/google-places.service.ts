import { Injectable } from '@nestjs/common';
import {
  Client,
  DirectionsResponse,
  PlaceAutocompleteResponse,
  PlaceDetailsResponse,
  TravelMode,
} from '@googlemaps/google-maps-services-js';
import { env } from '../config/env';

@Injectable()
export class GooglePlacesService {
  async searchPlaces(search: string) {
    try {
      const client = new Client({});
      const params: any = {
        radius: 1000000,
        input: search,
        language: 'en',
        types: 'geocode',
        key: env.GOOGLE_MAPS_API_KEY,
      };
      const response: PlaceAutocompleteResponse = await client.placeAutocomplete({ params });
      return response.data.predictions.map((prediction) => ({
        description: prediction.description,
        place_id: prediction.place_id,
      }));
    } catch (error) {
      console.error(error);
      throw error;
    }
  }

  async getRouteDetails(routeDetailsRequestDto: {
    origin: { lat: number; lng: number };
    destination: { lat: number; lng: number };
  }) {
    try {
      const client = new Client({});
      const response: DirectionsResponse = await client.directions({
        params: {
          origin: `${routeDetailsRequestDto.origin.lat},${routeDetailsRequestDto.origin.lng}`,
          destination: `${routeDetailsRequestDto.destination.lat},${routeDetailsRequestDto.destination.lng}`,
          mode: TravelMode.driving,
          key: env.GOOGLE_MAPS_API_KEY,
        },
      });

      const apiStatus = response?.data?.status;
      if (apiStatus && apiStatus !== 'OK') {
        const errorMessage = (response.data as any).error_message ?? 'No details';
        throw new Error(`Directions API returned ${apiStatus}. Details: ${errorMessage}`);
      }

      const routes = response?.data?.routes;
      if (!routes?.length) throw new Error('No route found between origin and destination.');

      const route = routes[0];
      const leg = route?.legs?.[0];
      if (!leg) throw new Error('Route has no legs.');

      return {
        distance: leg.distance.text,
        duration: leg.duration.text,
        polyline: route.overview_polyline.points,
        start_location: {
          lat: leg.start_location.lat,
          lng: leg.start_location.lng,
          place_name: leg.start_address,
        },
        end_location: {
          lat: leg.end_location.lat,
          lng: leg.end_location.lng,
          place_name: leg.end_address,
        },
      };
    } catch (error) {
      console.error('Google Directions API error:', error);
      throw error;
    }
  }

  async getPlaceDetails(place_id: string) {
    try {
      const client = new Client({});
      const response: PlaceDetailsResponse = await client.placeDetails({
        params: {
          place_id,
          key: env.GOOGLE_MAPS_API_KEY,
          fields: ['geometry', 'formatted_address', 'name'],
        },
      });
      const result = response.data.result;
      return {
        name: result.name,
        address: result.formatted_address,
        lat: result.geometry.location.lat,
        lng: result.geometry.location.lng,
      };
    } catch (error) {
      console.error(error);
      throw error;
    }
  }
}
