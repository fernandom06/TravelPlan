# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

Phone-first on Android and iOS; desktop and web builds exist but are not where design effort goes. The app uses one shared Material design language across all platforms (single `core/theme/app_theme.dart`), not per-OS theming.

## Users

The developer as a personal traveler: a single user planning their own trips with it. It is a personal tool, not a published product for others. In practice it is used while preparing an upcoming trip (organizing places into geographic zones, building the day-by-day itinerary) and consulted while out in the field.

## Product Purpose

TravelPlan organizes a trip: create trips with dates and a cover image, collect places with coordinates and categories, link places to trips, group places into geographic zones, and build the day-by-day itinerary as ordered slots. Success means the plan on screen can be trusted in the field — you know where you go, in what order, on which day.

## Positioning

The structured zone/day flow: places are not loose notes — they are grouped into geographic zones and placed into day-by-day itinerary slots. Booking and notes apps keep a list; TravelPlan keeps the ordered, zone-aware sequence of a trip.

## Operating Context

- Used in two situations: trip preparation (with the backend running locally) and field use on a phone, where connectivity may be unreliable.
- A connectivity stream (`connectivity_plus`) drives an offline banner; it is informational only — there is no offline persistence.
- Backed by a local FastAPI + SQLite service (`backend/`); the frontend needs it reachable (`API_BASE_URL`, defaulting to the Android emulator host loopback).

## Capabilities and Constraints

- Trips: CRUD with date validation (start <= end), cover image upload, status tracking; many-to-many link to places.
- Places & categories: CRUD for name, description, lat/lng, category; category rename/delete-with-reassignment semantics.
- Zone map: interactive map (`flutter_map` + OpenStreetMap tiles); places are created by long-press, zones rendered as points.
- Itinerary: day-by-day slots with reorder/move operations.
- Settings screen.
- Constraints that carry forward: the API contract is hand-written (`lib/data/*_api.dart` + `lib/data/models/`); backend status codes (409 duplicate, 422 invalid reassign) map to named frontend exceptions that must stay in sync. No migrations exist — schema changes mean editing `init_db()` DDL.
- Explicitly undecided: nothing recorded; no publishing, monetization, or multi-user plans are confirmed.

## Evidence on Hand

No real content, data, demonstrations, testimonials, case studies, press, or brand assets exist in the repository. Future work must not fabricate any of these; screenshots or sample data would have to be generated honestly from the app itself.

## Product Principles

1. The plan is the artifact: every screen serves the ordered, zone-aware trip sequence, not collection for its own sake.
2. Field-truthful: the app must behave honestly about connectivity and never pretend data is safe when it is not saved.
3. Structure over freeform: places, zones, and days are first-class structure; free text is the fallback, not the mechanism.
4. Small is deliberate: a single-user tool — precision and craft outrank feature breadth.
