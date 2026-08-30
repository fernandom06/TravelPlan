# Artisanal Wanderer - Design System

## Color Palette
Tokens for a warm, tactile, and organic travel experience.

- **Primary:** `#E07A5F` (Terracotta) - Primary actions, active states, key accents.
- **Background:** `#F4F1DE` (Paper) - Main page background, sun-faded paper tone.
- **Surface:** `#FFFFFF` (White) - Cards, sheets, and pure containers.
- **Text (Primary):** `#3D405B` (Navy) - Headings and main body text for soft contrast.
- **Muted:** `#D6CEB6` (Sand) - Borders, dividers, and disabled states.
- **Accent:** `#81B29A` (Mint) - Success states, nature categories, and fresh highlights.

## Typography
A blend of sophisticated serifs and readable body text.

- **Headings:** `Fraunces`, 700 (Bold)
- **Body:** `Lora`, 400 (Regular)
- **Small Text:** `Lora`, 400 (Regular)
- **Buttons:** `Fraunces`, 600 (Semi-bold)

## Design Tokens

```css
:root {
  --color-primary: #E07A5F;
  --color-background: #F4F1DE;
  --color-surface: #FFFFFF;
  --color-text: #3D405B;
  --color-muted: #D6CEB6;
  --color-accent: #81B29A;
  
  --font-heading: 'Fraunces', serif;
  --font-body: 'Lora', serif;
  
  /* Organic hand-cut radii */
  --radius-organic: 16px 14px 18px 12px;
  
  --shadow-soft: 0 8px 24px rgba(61, 64, 91, 0.08);
  
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
}
```

## Shared Components

### TopAppBar
- **Style:** Small center-aligned with backdrop-blur.
- **Typography:** `Fraunces` for headlines.
- **Colors:** `bg-surface/80` with `text-primary` accents.

### BottomNavBar
- **Shape:** Docked full-width, 16px top corner radius.
- **Colors:** `bg-surface` with terracotta active indicator.
- **Labels:** `Lora` 12px, capitalized.

### Trip Cards (Polaroid Style)
- **Shape:** `var(--radius-organic)`.
- **Shadow:** `var(--shadow-soft)`.
- **Content:** Full-bleed image top, title and dates bottom.

### Map Pins
- **Shape:** Teardrop with inner white circle.
- **Icons:** Hand-drawn SVG style.
