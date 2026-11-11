# PRD — Pulido visual de la pantalla de itinerario (desktop)

## Contexto

La pantalla de itinerario (`ItineraryScreen`) en desktop ancho presenta problemas
visuales detectados en una auditoría de UI/UX sobre captura real (1875px) y el
código de los widgets implicados. El objetivo es **mejorar visualmente la
implementación existente**, no rediseñarla.

Widgets implicados (todos en `frontend/lib/presentation/`):

- `screens/itinerary_screen.dart`
- `widgets/itinerary_two_column_layout.dart`
- `widgets/general_items_section.dart`
- `widgets/itinerary_slot_section.dart`
- `widgets/itinerary_place_card.dart`
- `widgets/dashed_action_card.dart` (también usado en trips screen)
- `widgets/day_pill_strip.dart` (solo lectura, sin cambios)
- `core/theme/app_theme.dart` (tokens)

## Problemas detectados (resumen por categoría)

1. **Jerarquía visual** — la cabecera de columna ("LUGARES POR ASIGNAR", Lora
   12px caps navy/70) pesa menos que las subsecciones ("Mañana/Tarde/Noche",
   Fraunces 700). El `+` de 40px de `DashedActionCard` compite con el contenido.
2. **Espaciado y alineación** — zona muerta de ~300px entre columnas en desktop
   (columna izquierda centrada con maxWidth 480 dentro de un `Expanded`); las
   tarjetas del timeline se estiran hasta ~900px sin max-width.
3. **Tipografía** — tamaños bajo mínimo legible (categoría 10px, nombre 12px);
   `fontFamily: 'Lora'` hardcodeado en vez de salir del `textTheme`.
4. **Color y contraste** — `AppColors.muted` (#D6CEB6, arena) usado como color
   de texto/icono (categorías, hints, drag handles, delete): contraste muy por
   debajo de WCAG AA. La pill de día inactiva parece deshabilitada.
5. **Componentes** — doble contenedor: cards blancas dentro de una caja
   discontinua siempre visible (el dashed solo debería significar "zona de drop
   vacía"); el panel izquierdo vertical es una caja enmarcada gigante casi
   vacía; icono delete de 16px casi invisible.
6. **Densidad** — filas de ~64px × ~900px para un nombre y una categoría.
7. **Responsive** — el breakpoint 900px y el modo apilado están bien; el
   problema es solo desktop ancho (sin max-width global, empeora cuanto más
   grande la ventana).
8. **Consistencia** — dos lenguajes de contenedor distintos para el mismo tipo
   de contenido; escala de iconos sin sistema (40/18/16/14).

## Alcance — los 5 cambios aprobados

### C1. Acotar el layout de escritorio

- `ItineraryTwoColumnLayout`: columna izquierda de **ancho fijo 340** (estirada
  a toda la altura, como hoy), gutter de **24**, conjunto centrado con
  **max-width global 1100** (`Center` + `ConstrainedBox`). Columna derecha:
  `Expanded` dentro de ese límite.
- `_daySections` (variante `centered`) en `itinerary_screen.dart`: limitar la
  columna de cards con `ConstrainedBox(maxWidth: 680)` centrada, en vez de
  estirar a `constraints.maxWidth`.
- El breakpoint de 900px (`_twoColumnBreakpoint`) y el modo apilado móvil
  **no cambian**.

### C2. Borde discontinuo solo en vacío o drag-over

- `ItinerarySlotSection`: cuando `items.isNotEmpty && !highlighted`, las cards
  se renderizan directas sobre el fondo (sin `DashedBorderContainer`); el rail
  + header actúan de agrupador.
- Cuando la sección está vacía o en drag-over (`highlighted`), se mantiene el
  `DashedBorderContainer` actual (hint "Arrastra lugares aquí" / highlight).
- **Semántica de drag & drop intacta**: `DragTarget` exterior (append) e
  interiores (insert-before) sin cambios.

### C3. Token de texto secundario y legibilidad

- Nuevo token en `app_theme.dart`: `AppColors.textSecondary = Color(0x993D405B)`
  (navy al 60%).
- Sustituir `AppColors.muted` **solo donde se usa como color de texto o icono**:
  - `itinerary_place_card.dart`: texto de categoría, drag handle, icono delete.
  - `general_items_section.dart`: texto del empty state.
  - `itinerary_slot_section.dart`: texto e icono del hint vacío (no
    highlighted).
- `AppColors.muted` sigue siendo válido para bordes, dashes y fondos.
- Escala mínima: nombre de lugar 12 → **13**, categoría 10 → **11** (ambas
  variantes horizontal y vertical de `ItineraryPlaceCard`).

### C4. Unificar contenedores y compactar la acción de añadir

- `GeneralItemsSection` (layout **vertical** solamente): el panel deja de ser
  una caja enmarcada (sin fondo blanco/50 ni borde en reposo); fondo
  transparente. En drag-over (`highlighted`) sí se muestra un relleno sutil de
  `AppColors.surface`. El layout **carousel** (móvil) no cambia.
- `DashedActionCard`: añadir modo compacto **opcional** (p. ej. parámetro
  `compact` o `iconSize`, por defecto el aspecto actual para no romper la trips
  screen): icono `+` de 20px y padding reducido. En la columna vertical del
  itinerario se usa el modo compacto y la altura del trailing pasa de 120 a
  ~72 (altura comparable a una card).
- El uso de `DashedActionCard` en trips screen queda visualmente igual.

### C5. Jerarquía de encabezados y escala base

- Cabecera de columna: "Lugares por asignar" en `textTheme.titleLarge`
  (Fraunces w700, `AppColors.text`), sentence case — jerárquicamente por encima
  de los headers de slot (`titleMedium` Fraunces w700, sin cambios).
- Eliminar `fontFamily: 'Lora'` hardcodeado en los estilos tocados (el tema ya
  aplica Lora globalmente) y consumir estilos del `textTheme` cuando sea
  posible sin cambiar el aspecto.

## Restricciones

- No inventar funcionalidades, datos, imágenes, métricas ni textos nuevos.
- No cambiar la arquitectura (controllers, modelos, API) — solo presentación.
- Reutilizar componentes y tokens existentes; los cambios de `DashedActionCard`
  y tokens deben ser retrocompatibles con el resto de pantallas.
- Mantener el comportamiento responsive actual fuera de desktop ancho.
- TDD según AGENTS.md: actualizar/añadir tests en `frontend/test/` reflejando
  la estructura de `lib/` antes o junto a cada cambio.

## Tests existentes afectados (actualizar, no borrar cobertura)

- `test/presentation/widgets/itinerary_two_column_layout_test.dart` — aserciones
  geométricas (ancho 480, centro de la mitad izquierda) dejan de valer.
- `test/presentation/widgets/itinerary_slot_section_test.dart` — presencia de
  `DashedBorderContainer` con items.
- `test/presentation/widgets/general_items_section_test.dart` — finder del
  título ('LUGARES POR ASIGNAR'), alturas del trailing (120), panel vertical.
- `test/presentation/widgets/dashed_action_card_test.dart` — modo compacto.
- `test/presentation/widgets/itinerary_place_card_test.dart` — tamaños/color.
- `test/core/theme/app_theme_test.dart` — nuevo token.
- `test/presentation/screens/itinerary_screen_test.dart` — regresión general.

## Criterios de aceptación

1. A 1875px de ancho no hay zona muerta entre columnas; el conjunto está
   centrado con max-width 1100; las cards del timeline no superan ~680-736px.
2. Con items y sin drag, las secciones del timeline no muestran caja
   discontinua; el dashed aparece solo en vacío o drag-over.
3. Ningún texto o icono usa `AppColors.muted`; `textSecondary` cubre ese rol.
4. La columna izquierda y el timeline comparten lenguaje visual (sin caja
   enmarcada en reposo); el `+` de añadir está a escala del sistema (20px) en
   el itinerario, y la trips screen no cambia.
5. Jerarquía clara: título de viaje > cabecera de columna > headers de slot;
   nombre de lugar ≥13px y categoría ≥11px.
6. `fvm dart format .`, `fvm flutter analyze` (0 issues) y `fvm flutter test`
   (todo verde) al finalizar.
7. Verificación visual manual a 1875px, ~900px (breakpoint) y móvil.

## Fuera de alcance

- Pill de día inactiva (color de fondo) y alineación óptica del rail: anotado
  como deuda, no se toca en este PR.
- Backend: sin cambios.
- Cualquier cambio de comportamiento de drag & drop, navegación o datos.
