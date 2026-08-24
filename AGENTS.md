# AGENTS.md

## Project Overview

TravelPlan is a travel planning application consisting of two independent subprojects:

- **`backend/`** — REST API built with FastAPI (Python >= 3.14), managed with [uv](https://docs.astral.sh/uv/), backed by SQLite (`places.db`)
- **`frontend/`** — Flutter app (Dart SDK ^3.11.5) targeting Android, iOS, Linux, macOS, Windows, and web, managed with [FVM](https://fvm.app)

Current features:

- **Places & categories**: CRUD for places (name, description, lat/lng, category) and categories, with rename/delete-with-reassignment semantics on the API
- **Trips**: CRUD with date validation (start <= end), optional cover image upload, and a many-to-many link to places via `trip_places`
- **Map**: interactive map (`flutter_map` + OpenStreetMap tiles) where places are created by long-pressing and can be edited/deleted
- **Connectivity**: offline banner driven by `connectivity_plus`

### Architecture

Backend modules live in `backend/src/backend/`:

- `main.py` — app factory point: lifespan (DB init + uploads dir creation), open CORS middleware, router registration
- `config.py` — env-based settings: `UPLOADS_DIR`, `MAX_IMAGE_SIZE_MB`; allowed image content types
- `database.py` — SQLite connection helpers, `get_db()` dependency, schema DDL (`categories`, `places`, `trips`, `trip_places`)
- `schemas.py` — Pydantic request/response models
- Routers (one file each): `categories.py`, `places.py`, `trips.py`, `uploads.py`

Frontend follows a layered structure under `frontend/lib/`:

- `data/` — typed models (`models/`) and HTTP clients (`place_api.dart`, `trip_api.dart`) that translate status codes into domain exceptions (e.g. `DuplicateCategoryException`)
- `presentation/controllers/` — `ChangeNotifier`-style controllers holding state per screen
- `presentation/screens/`, `presentation/widgets/` — UI; screens compose widgets and wire controllers
- `core/connectivity/` — connectivity stream wrapper

**Important:** Flutter is managed through FVM — always prefix `flutter`/`dart` commands with `fvm` (e.g. `fvm flutter ...`). The pinned version lives in `frontend/.fvmrc`; do not use a global `flutter` install.

## Setup Commands

### Backend (`backend/`)

- Install dependencies: `uv sync`
- Add a dependency: `uv add <package>` (dev deps: `uv add --dev <package>`)
- Python version is enforced by `requires-python = ">=3.14"` in `pyproject.toml`

Optional environment variables (see `src/backend/config.py`):

- `UPLOADS_DIR` — directory for trip images (default `uploads/`, relative to CWD)
- `MAX_IMAGE_SIZE_MB` — max upload size in MB (default 5)

### Frontend (`frontend/`)

- Install dependencies: `fvm flutter pub get`
- Add a dependency: `fvm flutter pub add <package>`

## Development Workflow

Run commands inside the corresponding subproject directory — there is no root-level build orchestrator.

### Backend

- Start dev server (hot reload): `uv run fastapi dev src/backend/main.py`
- App instance lives in `backend/src/backend/main.py` (`app = FastAPI(...)`)
- Interactive API docs available at `/docs` once the server runs
- Default port is 8000; SQLite file (`places.db`) and `uploads/` are created at startup relative to CWD — both are gitignored runtime artifacts
- CORS is currently wide open (`allow_origins=["*"]`) — tighten before any real deployment

API surface (all JSON):

- `/categories` — GET list, POST create, PATCH rename, DELETE (`?reassign_to=<id>` moves its places; conflicts return 409, invalid target 422)
- `/places` — GET list/detail, POST create (201), PATCH partial update, DELETE (204)
- `/trips` — same shape plus `POST /trips/{trip_id}/image` for cover image upload; images served from `/uploads/{filename}`
- `/` — health/root message

### Frontend

- Run on a device/emulator: `fvm flutter run` (add `-d chrome`, `-d macos`, etc. to pick a target)
- App entry point: `frontend/lib/main.dart`
- API base URL resolution (in `lib/main.dart`):
  - Override with `fvm flutter run --dart-define=API_BASE_URL=http://<host>:8000`
  - Defaults to `http://10.0.2.2:8000` on Android (emulator → host loopback) and `http://localhost:8000` elsewhere
- Keep controllers framework-free where possible: state lives in controllers, not in widget tree callbacks

## Testing Instructions

Both suites must pass before committing.

### Backend

Tests live in `backend/tests/` using `pytest` + FastAPI's `TestClient` (71 tests currently):

- Run all tests: `uv run pytest`
- Run one test file: `uv run pytest tests/test_<name>.py`
- Run a single test: `uv run pytest -k "<test name>"`

Conventions:

- Use the shared `test_client` fixture from `tests/conftest.py`: it swaps in an in-memory SQLite connection via `app.dependency_overrides[get_db]` so tests never touch `places.db`
- Uploads tests use `tmp_path` + monkeypatched config; follow the same isolation pattern for new filesystem-touching code
- Name files `tests/test_<module>.py`, mirroring the module under test

### Frontend

Tests live in `frontend/test/` using `flutter_test` (~200 tests), mirroring `lib/` structure:

- Run all tests: `fvm flutter test`
- Run one file: `fvm flutter test test/presentation/widgets/trip_form_test.dart`
- Run by name pattern: `fvm flutter test --plain-name "<test name>"`

Conventions:

- Mirror the source path: `lib/presentation/widgets/foo.dart` → `test/presentation/widgets/foo_test.dart`
- API clients are tested against mocked `http.Client`s; inject the client through the constructor rather than creating it inline
- A known benign `flutter_map` warning about `userAgentPackageName` appears in test output — ignore it unless you are touching the map

Always add or update tests for code you change, even if nobody asked.

## Code Style

### Backend

- No linter/formatter is pinned yet; follow `ruff` conventions:
  - Check: `uvx ruff check .` / Format: `uvx ruff format .` (from `backend/`)
- Follow PEP 8; keep line length reasonable (~88 chars)
- Type hints on all function signatures; routers stay thin and delegate to schemas/helpers
- Domain errors map to explicit status codes (409 duplicate, 422 invalid reassign target) — keep frontend exceptions in sync with these

### Frontend

- Lints are enforced via `analysis_options.yaml` with `package:flutter_lints/flutter.yaml`
- Analyze: `fvm flutter analyze` — zero issues required before committing
- Format: `fvm dart format .`
- Do not add `// ignore:` suppressions without justification
- Naming: models are plain immutable classes with `fromJson`/`toJson`; drafts for create payloads, `*Update` classes for PATCH payloads
- Promote a module into `core/` only once it has a second real consumer

## Build and Deployment

No CI/CD or deployment configuration exists yet.

- Frontend release builds: `fvm flutter build apk`, `fvm flutter build ios`, `fvm flutter build web`, etc.
- Backend production serving: `fastapi run src/backend/main.py` or `uvicorn backend.main:app`
- Before deploying anywhere: restrict CORS origins in `main.py` and set `UPLOADS_DIR` to a persistent path

## Pull Request Guidelines

- Commit style follows Conventional Commits with scope: `feat(backend): ...`, `fix(frontend): ...`, `test(controller): ...`
- Keep changes scoped to one concern per PR
- Required checks before submitting:
  - Backend: `uv sync && uv run pytest && uvx ruff check .`
  - Frontend: `fvm flutter analyze` and `fvm flutter test` pass with no issues
- Do not commit generated artifacts: `__pycache__/`, `.venv/`, `build/`, `dist/`, `*.db`, `uploads/`, `.tmp/`

## Additional Notes

- Two separate projects sharing a git root — always check which directory you are in before running commands
- `backend/pyproject.toml` uses the `uv_build` build backend with `src/backend/` layout; place importable modules under `src/backend/`
- Secrets must never be committed; there is no `.env` handling yet — create one locally if needed and keep it ignored
- SQLite is a stopgap: no migrations exist, schema changes mean editing `init_db()` DDL in `backend/src/backend/database.py` (and updating `tests/test_trips_db.py`-style coverage); keep this in mind when changing models on both sides
- The frontend API contract is hand-written (`data/*_api.dart` + `models/`); when changing a backend endpoint's shape or status codes, update the matching client, model, controller, and tests together
- Flutter platform folders (`android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`) are generated — avoid manual edits unless changing platform-specific configuration
- Known debt: review `userAgentPackageName` and OSM tile usage policy before the map grows; CORS lockdown before deployment
