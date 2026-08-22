# AGENTS.md

## Project Overview

TravelPlan is a travel planning application consisting of two independent subprojects:

- **`backend/`** — Python API built with FastAPI (Python >= 3.14), managed with [uv](https://docs.astral.sh/uv/)
- **`frontend/`** — Flutter app (Dart SDK ^3.11.5) targeting Android, iOS, Linux, macOS, Windows, and web, managed with [FVM](https://fvm.app)

This is an early-stage project. There is no root-level package manager or build orchestrator; run commands inside each subproject directory.

**Important:** Flutter is managed through FVM — always prefix `flutter`/`dart` commands with `fvm` (e.g. `fvm flutter ...`). The pinned version lives in `frontend/.fvmrc`; do not use a global `flutter` install.

## Setup Commands

### Backend (`backend/`)

- Install dependencies: `uv sync`
- Add a dependency: `uv add <package>`
- Python version is enforced by `requires-python = ">=3.14"` in `pyproject.toml`

### Frontend (`frontend/`)

- Install dependencies: `fvm flutter pub get`
- Add a dependency: `fvm flutter pub add <package>`

## Development Workflow

### Backend

- Start dev server (hot reload): `uv run fastapi dev src/backend/main.py` (from `backend/`)
- Alternative entry point: `uv run python src/backend/main.py` if a `if __name__ == "__main__"` runner exists
- App instance lives in `backend/src/backend/main.py` (`app = FastAPI()`)
- Interactive API docs available at `/docs` once the server runs
- Source code goes in `backend/src/backend/` (uv build backend layout)

### Frontend

- Run on a device/emulator: `fvm flutter run` (add `-d chrome`, `-d macos`, etc. to pick a target)
- App entry point: `frontend/lib/main.dart`

## Testing Instructions

### Backend

No tests exist yet. When adding them, use `pytest`:

- Run all tests: `uv run pytest`
- Run one test file: `uv run pytest tests/test_<name>.py`
- Run a single test: `uv run pytest -k "<test name>"`
- Add `pytest` and `httpx` as dev dependencies (`uv add --dev pytest httpx`) and use FastAPI's `TestClient`

### Frontend

Tests live in `frontend/test/` using the `flutter_test` framework:

- Run all tests: `fvm flutter test`
- Run one file: `fvm flutter test test/widget_test.dart`
- Run by name pattern: `fvm flutter test --plain-name "<test name>"`

Always add or update tests for code you change.

## Code Style

### Backend

- No linter/formatter is configured yet; use `ruff` conventions when writing code:
  - Check: `uvx ruff check .` / Format: `uvx ruff format .` (from `backend/`)
- Follow PEP 8; keep line length reasonable (~88 chars)
- Prefer type hints on all function signatures

### Frontend

- Lints are enforced via `analysis_options.yaml` with `package:flutter_lints/flutter.yaml`
- Analyze: `fvm flutter analyze`
- Format: `fvm dart format .`
- All analyzer issues must be resolved before committing; do not add `// ignore:` suppressions without justification

## Build and Deployment

No CI/CD or deployment configuration exists yet.

- Frontend release builds: `fvm flutter build apk`, `fvm flutter build ios`, `fvm flutter build web`, etc.
- Production serving would typically use `fastapi run src/backend/main.py` or `uvicorn`

## Pull Request Guidelines

- Keep changes scoped to one concern per PR
- Before submitting:
  - Backend: `uv sync && uvx ruff check .` passes
  - Frontend: `fvm flutter analyze` and `fvm flutter test` pass with no issues
- Do not commit generated artifacts: `__pycache__/`, `.dart_tool/`, `build/`, `.tmp/`

## Additional Notes

- The repo layout is two separate projects sharing a git root — always check which directory you are in before running commands
- `backend/pyproject.toml` uses the `uv_build` build backend with `src/backend/` layout; place importable modules under `src/backend/`
- Secrets must never be committed; there is no `.env` handling yet, so create one locally if needed and keep it ignored
- Flutter platform folders (`android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`) are generated — avoid manual edits unless changing platform-specific configuration
