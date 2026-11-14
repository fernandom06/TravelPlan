# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

> ASSUMPTION: inferred from the Flutter codebase targeting Android, iOS, desktop, and web with a single Material theme; not confirmed with the user.

## Users

- ASSUMPTION (inferred from repository and code, not confirmed): An individual traveler planning their own trips — building a personal catalog of places they might visit, organized into categories, and composing day-by-day itineraries for each trip. The user runs the app themselves against their own backend instance (personal/hobby context; no accounts, no multi-tenant server evidence).
- Open decision: whether a second audience (e.g., shared/family planning) is intended — unconfirmed.

## Product Purpose

TravelPlan lets a person collect and organize places (name, description, coordinates, category), group them into trips (with dates and an optional cover image), plan the trip as an itinerary by day and time slots, and see everything on a map. Success means the user can go from "places I want to visit" to a concrete day-by-day plan without leaving the app.

## Positioning

- ASSUMPTION (not confirmed): The differentiator is map- and geography-first planning: places are created directly on the map (long-press), itineraries are planned per day/slot around those places, and the same personal catalog of places and categories is reused across multiple trips — in contrast to generic list tools (Google Maps saved lists) or document-style itinerary managers (TripIt).

## Operating Context

- ASSUMPTION (from code): Used across phone and desktop during planning sessions; runs against a local FastAPI backend (`just dev` starts API + app together). Offline state matters: the app shows a connectivity banner and must behave sensibly without the API.

## Capabilities and Constraints

- Places: CRUD with name, description, lat/lng, category; categories support rename and delete-with-reassignment (409 on conflict, 422 on invalid target — frontend exceptions must stay in sync).
- Trips: CRUD with date validation (start <= end), optional cover image upload; many-to-many link to places (`trip_places`).
- Itinerary: day/slot-based planning per trip (itinerary API + two-column layout screen); URL import of places (`import_url_dialog.dart`).
- Map: interactive `flutter_map` + OpenStreetMap tiles; places created by long-press, edited/deleted in place; zone-map screen for spatial planning.
- Connectivity: offline banner driven by `connectivity_plus`.
- Technical constraints: SQLite backend (no migrations — schema changes edit `init_db()` DDL); uploads limited to 5 MB images; hand-written frontend API contract that must mirror backend endpoint shapes.
- Open decision: primary UI language (developer docs are Spanish; app copy language unconfirmed).

## Brand Commitments

- Name: TravelPlan (as used in `MaterialApp.title`).
- An existing design system document (DESIGN.md, "Artisanal Wanderer" world) is present in the repo; init does not modify or validate it — treat it as incumbent visual context for later design work, not as a confirmed binding commitment.

## Evidence on Hand

- Complete runnable codebase: `backend/` (FastAPI + SQLite, 71 tests) and `frontend/` (Flutter, ~200 tests), with `AGENTS.md` documenting setup, testing, and conventions.
- No real user research, testimonials, usage data, press, or marketing assets — future work must not fabricate any of these.

## Product Principles

- ASSUMPTION (derived from repository evidence and code, not confirmed): 
  1. Geography first — places and plans live on the map, not just in lists.
  2. Reuse over re-entry — one catalog of places and categories serves many trips.
  3. Honest state — the app always shows what is offline/unsynced rather than pretending connectivity.
  4. Simple and personal — no accounts or cloud assumptions; the user owns their data.
