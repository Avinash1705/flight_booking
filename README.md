# SkyBook – Flutter Flight Booking App

A complete, production-style flight booking front-end with a mock backend.

## Features
- **Splash → Login / Sign-up / Guest**, session persisted across launches
- **Search**: one-way & round-trip, searchable airport picker, swap, date pickers,
  adults/children, cabin class, recent searches, popular destinations
- **Results**: skeleton loading, ±3-day price strip, sort (cheapest/fastest/earliest),
  filters (stops, departure time, airlines, price), flight details sheet
- **Round-trip flow**: pick outbound, then return
- **Checkout (3 steps)**: traveller forms with validation → interactive seat map per
  passenger & flight → payment (UPI / card / net banking / wallet, promo codes)
- **Boarding-pass tickets** with barcode, gate, terminal, seats
- **My Trips**: Upcoming / Completed / Cancelled, trip details, cancellation with refund
- **Profile**: light / dark / system theme, notification toggle, help, about, logout
- Persistent storage (shared_preferences), Provider state management, unit tests

## Promo codes
`SKY10` (10%), `FLY15` (15%), `WELCOME20` (20%)

## Run
```bash
cd flight_booking
flutter create --project-name flight_booking .   # generates android/ ios/ web/ ...
rm -f test/widget_test.dart                      # generated sample test, not needed
flutter pub get
flutter run
flutter test
```

## Project structure
```
lib/
  main.dart                 app entry, providers, theme
  core/                     theme, constants, utils (formatters)
  models/                   Flight, Booking, Passenger, PriceBreakdown, ...
  services/                 AuthService, BookingService, SettingsService, FlightService
  widgets/                  reusable UI (cards, boarding pass, pickers, ...)
  screens/                  splash, login, search, results, passenger, seat,
                            payment, confirmation, trips, trip detail, profile
test/app_test.dart          formatter, schedule & pricing tests
```

## Going to production
| Area | Where to plug in |
|------|------------------|
| Real flights | `FlightService.search()` → Amadeus / Duffel / your API |
| Auth | `AuthService.login()/register()` → Firebase Auth / REST |
| Payments | `PaymentScreen._pay()` → Razorpay / Stripe SDK |
| Bookings storage | `BookingService` → API-backed repository |
| Push notifications | `SettingsService.notifications` + FCM |
| Localisation | add `flutter_localizations` + ARB files |
