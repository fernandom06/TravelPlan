# TravelPlan — atajos de desarrollo.
# Ejecuta `just --list` para ver todas las recetas.

set shell := ["zsh", "-c"]

backend := "backend"
frontend := "frontend"
session := "travelplan"

# Lista las recetas disponibles
default:
    @just --list

# Instala dependencias de ambos subproyectos
setup:
    cd {{backend}} && uv sync
    cd {{frontend}} && fvm flutter pub get

# API en http://localhost:8000 con recarga automática
api:
    cd {{backend}} && uv run fastapi dev src/backend/main.py

# App Flutter: just app [linux|chrome|<device>] [--dart-define=...]
app dev="linux" *args:
    cd {{frontend}} && fvm flutter run -d {{dev}} {{args}}

# API + app en una sesión tmux: just dev [linux|chrome|<device>]
dev dev="linux":
    @./scripts/dev.sh {{dev}}

# Detiene la sesión de `just dev` (API + app)
stop:
    @tmux kill-session -t {{session}} 2>/dev/null && echo "Sesión '{{session}}' detenida." || echo "No hay ninguna sesión '{{session}}' en marcha."

# Indica si la sesión de `just dev` está en marcha
status:
    @tmux has-session -t {{session}} 2>/dev/null && echo "Sesión '{{session}}' en marcha (tmux a -t {{session}})." || echo "Sesión '{{session}}' parada."

# Tests del backend: just test-backend [-k patrón]
test-backend *args:
    cd {{backend}} && uv run pytest {{args}}

# Tests del frontend: just test-frontend [ruta/al/test.dart]
test-frontend *args:
    cd {{frontend}} && fvm flutter test {{args}}

# Ejecuta ambas suites (obligatorio antes de commitear)
test: test-backend test-frontend

# ruff check + flutter analyze
lint:
    cd {{backend}} && uvx ruff check .
    cd {{frontend}} && fvm flutter analyze

# Formatea el código de ambos subproyectos
fmt:
    cd {{backend}} && uvx ruff format .
    cd {{frontend}} && fvm dart format .

# Dispositivos Flutter disponibles
devices:
    cd {{frontend}} && fvm flutter devices
