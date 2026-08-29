export interface RouteWaypoint {
  lat: number;
  lon: number;
  speedKmh: number;
}

/**
 * Coimbatore corridors + city loop. Waypoints were hand-placed on OSM along
 * Avinashi Rd, Trichy Rd, Sathy Rd, Race Course and the airport stretch so the
 * demo map traces plausible local routes.
 */
export const COIMBATORE_ROUTES: RouteWaypoint[][] = [
  // A: Gandhipuram → Sanganur → Peelamedu → Airport (Avinashi Rd corridor)
  [
    { lat: 11.0186, lon: 76.9733, speedKmh: 30 },
    { lat: 11.0135, lon: 76.9795, speedKmh: 45 },
    { lat: 11.0112, lon: 76.9871, speedKmh: 50 },
    { lat: 11.0127, lon: 76.9914, speedKmh: 48 },
    { lat: 11.0170, lon: 76.9962, speedKmh: 52 },
    { lat: 11.0215, lon: 77.0011, speedKmh: 55 },
    { lat: 11.0255, lon: 77.0081, speedKmh: 56 },
    { lat: 11.0268, lon: 77.0170, speedKmh: 55 },
    { lat: 11.0292, lon: 77.0431, speedKmh: 58 },
  ],
  // B: Race Course / Brookefields loop
  [
    { lat: 11.0067, lon: 76.9669, speedKmh: 32 },
    { lat: 11.0060, lon: 76.9720, speedKmh: 42 },
    { lat: 11.0025, lon: 76.9761, speedKmh: 44 },
    { lat: 11.0004, lon: 76.9676, speedKmh: 40 },
    { lat: 11.0014, lon: 76.9591, speedKmh: 38 },
    { lat: 11.0067, lon: 76.9669, speedKmh: 34 },
  ],
  // C: Ukkadam → Trichy Rd stretch
  [
    { lat: 10.9989, lon: 76.9563, speedKmh: 28 },
    { lat: 11.0011, lon: 76.9463, speedKmh: 44 },
    { lat: 11.0039, lon: 76.9336, speedKmh: 50 },
    { lat: 11.0053, lon: 76.9180, speedKmh: 54 },
    { lat: 11.0102, lon: 76.9064, speedKmh: 48 },
  ],
  // D: Sathy Rd flyover → Peelamedu
  [
    { lat: 11.0018, lon: 76.9636, speedKmh: 34 },
    { lat: 11.0094, lon: 76.9533, speedKmh: 46 },
    { lat: 11.0195, lon: 76.9622, speedKmh: 52 },
    { lat: 11.0281, lon: 76.9764, speedKmh: 55 },
    { lat: 11.0255, lon: 77.0081, speedKmh: 56 },
  ],
  // E: City centre loop (Gandhipuram → Town Hall → Ukkadam)
  [
    { lat: 11.0186, lon: 76.9733, speedKmh: 30 },
    { lat: 11.0214, lon: 76.9661, speedKmh: 34 },
    { lat: 11.0154, lon: 76.9580, speedKmh: 36 },
    { lat: 11.0068, lon: 76.9530, speedKmh: 32 },
    { lat: 10.9989, lon: 76.9563, speedKmh: 30 },
    { lat: 11.0067, lon: 76.9669, speedKmh: 34 },
  ],
  // F: Kovaipudur → Sundarapuram feeder
  [
    { lat: 10.9957, lon: 76.9231, speedKmh: 38 },
    { lat: 11.0004, lon: 76.9336, speedKmh: 44 },
    { lat: 11.0039, lon: 76.9336, speedKmh: 46 },
    { lat: 11.0053, lon: 76.9180, speedKmh: 50 },
  ],
];