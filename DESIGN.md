# Artisanal Wanderer - Design System

## Color Palette
Tokens for a warm, tactile, and organic travel experience.

- **Primary:** `#E07A5F` (Terracotta) - Primary actions, active states, key accents.
- **Primary Deep:** `#B9563D` (Deep Terracotta) - Fill under small white text (day pills, badges, FABs). Plain primary with white only reaches ~2.9:1; this darker shade clears AA (4.5:1).
- **Background:** `#F4F1DE` (Paper) - Main page background, sun-faded paper tone.
- **Surface:** `#FFFFFF` (White) - Cards, sheets, and pure containers.
- **Text (Primary):** `#3D405B` (Navy) - Headings and main body text for soft contrast.
- **Text (Secondary):** `#5F6378` (Navy lightened) - Secondary text and icons; solid color chosen so small text clears AA on both surface and background.
- **Muted:** `#D6CEB6` (Sand) - Borders, dividers, and disabled states.
- **Accent:** `#81B29A` (Mint) - Success states, nature categories, and fresh highlights.
- **Accent Deep:** `#4F7A62` (Deep Mint) - Fill under small white text in the mint family (EN CURSO badges). Plain accent with white only reaches ~2.4:1; this darker shade clears AA.

Field-truthful contrast rule: any white text smaller than 18px sitting on a brand color uses the Deep variant of that color, so labels stay readable in direct sunlight.

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
  --color-primary-deep: #B9563D;
  --color-background: #F4F1DE;
  --color-surface: #FFFFFF;
  --color-text: #3D405B;
  --color-text-secondary: #5F6378;
  --color-muted: #D6CEB6;
  --color-accent: #81B29A;
  --color-accent-deep: #4F7A62;
  
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
