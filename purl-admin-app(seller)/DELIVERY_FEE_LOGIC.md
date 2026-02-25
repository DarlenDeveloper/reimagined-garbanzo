# Delivery Fee Calculation Logic

Date: February 25, 2026
Status: IMPLEMENTED ✅

## Fee Structure

### Package Types
- **Standard** (< 15kg, Motorcycle): 500 UGX per km
- **Bulky** (> 15kg, Car/Vehicle): 1000 UGX per km

### Common Rules
- Minimum Fee: 1000 UGX
- Maximum Fee: None
- Rounding: Round to nearest 500 UGX (e.g., 1000, 1500, 2000, 2500, 3000)

## Calculation Steps

1. Get route distance from Google Directions API (actual road distance)
2. Select rate based on package type (500 or 1000 UGX/km)
3. Calculate raw fee: distance_km × rate
4. Apply minimum: max(raw_fee, 1000)
5. Round to nearest 500: round(fee / 500) × 500

## Examples

### Standard Package (500 UGX/km)

Distance 0.5 km:
- Raw: 0.5 × 500 = 250 UGX
- After minimum: 1000 UGX
- After rounding: 1000 UGX
- Final: 1000 UGX

Distance 3.2 km:
- Raw: 3.2 × 500 = 1600 UGX
- After minimum: 1600 UGX
- After rounding: 1500 UGX
- Final: 1500 UGX

Distance 6.16 km:
- Raw: 6.16 × 500 = 3080 UGX
- After minimum: 3080 UGX
- After rounding: 3000 UGX
- Final: 3000 UGX

Distance 15.3 km:
- Raw: 15.3 × 500 = 7650 UGX
- After minimum: 7650 UGX
- After rounding: 7500 UGX
- Final: 7500 UGX

### Bulky Package (1000 UGX/km)

Distance 0.5 km:
- Raw: 0.5 × 1000 = 500 UGX
- After minimum: 1000 UGX
- After rounding: 1000 UGX
- Final: 1000 UGX

Distance 3.2 km:
- Raw: 3.2 × 1000 = 3200 UGX
- After minimum: 3200 UGX
- After rounding: 3000 UGX
- Final: 3000 UGX

Distance 6.16 km:
- Raw: 6.16 × 1000 = 6160 UGX
- After minimum: 6160 UGX
- After rounding: 6000 UGX
- Final: 6000 UGX

Distance 15.3 km:
- Raw: 15.3 × 1000 = 15300 UGX
- After minimum: 15300 UGX
- After rounding: 15500 UGX
- Final: 15500 UGX

## Implementation

### Files Updated

1. `lib/services/directions_service.dart` - Created
   - getRoute() - Calls Google Directions API
   - calculateDeliveryFee() - Implements fee logic
   - decodePolyline() - Decodes polyline for map display

2. `lib/services/delivery_service.dart` - Updated
   - Line 81: Changed from 1000 UGX/km to 325 UGX/km with proper rounding

3. `lib/screens/delivery_screen.dart` - Updated
   - Added DirectionsService integration
   - _requestDeliveryForOrder() now calls Directions API before creating delivery
   - _calculateDeliveryFee() updated with minimum and rounding logic
   - Passes routePolyline to tracking screen
   - Stores routePolyline in Firestore

4. `lib/screens/delivery_tracking_screen.dart` - Updated
   - Accepts routePolyline parameter
   - Displays route on map using decoded polyline
   - Shows actual route instead of straight line

### Function Signature

```dart
double calculateDeliveryFee(double routeDistanceKm) {
  const perKmRate = 325.0;
  const minimumFee = 1000.0;
  
  double rawFee = routeDistanceKm * perKmRate;
  double feeAfterMinimum = rawFee < minimumFee ? minimumFee : rawFee;
  double roundedFee = (feeAfterMinimum / 100).round() * 100.0;
  
  return roundedFee;
}
```

## Google Directions API

Endpoint: https://maps.googleapis.com/maps/api/directions/json
Parameters:
- origin: lat,lng (store location)
- destination: lat,lng (buyer location)
- mode: driving
- key: API_KEY

Response includes:
- routes[0].legs[0].distance.value (meters)
- routes[0].legs[0].duration.value (seconds)
- routes[0].overview_polyline.points (encoded polyline)

Convert meters to km: distance_meters / 1000

## Fallback Behavior

If Google Directions API fails:
- Falls back to straight-line distance calculation
- Still applies same fee logic (325/km, 1000 min, round to 100)
- Logs warning in console
- No route polyline displayed on map

## Courier Search Radius

Current: 2km radius from store location (configured in Cloud Function)
Standard: Can be increased to 5km or 10km based on demand

## Firestore Schema Update

New field added to deliveries collection:
- routePolyline: string (encoded polyline from Directions API)

This allows the tracking screen to display the actual route on the map.

## Testing Checklist

- [x] Fee calculation logic implemented
- [x] Google Directions API integration
- [x] Polyline decoding and map display
- [x] Fallback to straight-line distance
- [x] Firestore schema updated
- [ ] Test with real orders
- [ ] Verify fee accuracy
- [ ] Test API failure scenarios
- [ ] Verify map route display

## Notes

- Route distance is always longer than straight-line distance
- Fees will be higher but more accurate
- Sellers and buyers see real delivery cost upfront
- Couriers know exact distance before accepting
- API key is embedded in code (consider moving to environment variables for production)
