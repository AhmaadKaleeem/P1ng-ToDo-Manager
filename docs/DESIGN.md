# Visual Language & Design System

## Core Vibe
- **Calm, focused, serious, technical, student-first.**
- Designed for studying late at night. No flashy productivity/SaaS dashboard tropes.
- **Aesthetics to avoid**: Purple/blue AI gradients, glassmorphism, neon effects, excessive shadows, rainbow colors, generic illustrations, gamification, AI buzzwords.

## Extracted Design Principles (from Video Reference)

### 1. Visual Hierarchy
- **Oversized Headings**: Prominent, bold page titles (e.g., "What's up, {Name}!") that establish clear context.
- **Section Labels**: Small, uppercase, letter-spaced, and subdued (e.g., "CATEGORIES", "TODAY'S TASKS") to separate content without overpowering it.
- **De-emphasized Metadata**: Timestamps, tags, and secondary info use lower opacity to keep the focus on the primary task text.

### 2. Spacing Rhythm
- **Generous Margins**: 24px to 32px horizontal padding for the main canvas to create breathing room.
- **Vertical Rhythm**: Large gaps (32px-40px) between distinct sections; tight grouping (8px-12px) for related elements (like title and subtitle).
- **List Spacing**: Tasks have comfortable padding inside and between each row, avoiding a cramped, dense list look.

### 3. Typography Scale
- **Display**: ~28-32px, Bold (Page titles).
- **Heading**: ~20-24px, Semi-Bold (Drawer items, major categories).
- **Body / Action**: ~15-16px, Medium/Regular (Task titles, buttons).
- **Caption / Overline**: ~12-13px, Semi-Bold, uppercase tracking (Section headers, due times).

### 4. Component Geometry
- **Cards & Surfaces**: Rounded rectangles with generous radii (16px to 24px) for cards, dialogs, and the main canvas when pushed back.
- **Controls**: Fully circular checkboxes; pill-shaped or fully rounded Floating Action Buttons (FAB).
- **Category Indicators**: Subtle thick colorful bottom borders on category cards rather than fully colored backgrounds.

### 5. Navigation Patterns
- **3D Animated Drawer**: A side drawer that scales down the main canvas to ~85% and pushes it to the right, revealing the navigation menu underneath.
- **Bottom-Right FAB**: Primary action (adding a task) is anchored at the bottom right.
- **Contextual Actions**: Swipe-to-delete, tap-to-edit.

### 6. Motion Language
- **Fluid & Spring-based**: Animations should feel physical, not linear. The drawer push should use a spring curve.
- **Morphing Transitions**: Tapping the FAB should smoothly expand into a bottom sheet or full screen for data entry.
- **Micro-interactions**: Checking a box fills smoothly, text gets a strike-through with a slight fade. Swipe-to-delete slides out gracefully.

### 7. Surface Treatment
- **Flat Depth**: In our dark theme, avoid literal drop shadows. Instead, use background (`#0B1120`) vs. surface (`#111827`) contrast to define edges.
- **Borders over Shadows**: Use a subtle 1px stroke (`AppColors.divider`) if a boundary needs to be drawn, rather than glowing or neon borders.

### 8. Interaction States
- **Completion**: Task text fades to secondary opacity + strike-through. The circle icon becomes a filled checkmark with `AppColors.action`.
- **Selection**: Active navigation items have high contrast (`textPrimary`) and an icon highlighted in `action` color.
- **Destructive**: Swipe to delete reveals the action, accompanied by an inline "UNDO" snackbar or button.

## Color Palette Constraints
| Element | Hex | Use |
| :--- | :--- | :--- |
| **Background** | `#0B1120` Midnight Navy | Main canvas, Drawer background |
| **Surface** | `#111827` Dark Slate | Cards, task rows, pushed main-canvas |
| **Text** | `#F3F4F6` Ash | Primary text/icons |
| **Action / Positive** | `#10B981` Terminal Green | Primary actions, completion, Start Focus |
| **Alert** | `#F59E0B` Warning Amber | Reminders, overdue states |

*Secondary text uses `#F3F4F6` at roughly 60–65% opacity.*

STRICT NEGATIVE DESIGN COMMANDS: Do not use harsh gradients, Lucide icons, pure white backgrounds, rainbow colors, drop shadows, three feature cards in a row, emojis, liquid glass, em dashes, Inter, Geist, Space Grotesk, colored left stripes, fake testimonials, bento grids, decorative terminal windows, the "it's not X, it's Y" copywriting formula, checkmark bullets, three pricing tiers, generic AI imagery, soft corner radii, purple-and-black palettes, radial orbs, dot grids, sparkle icons, animated arrows, hover animations, neon colors, basic pastels, excessive rounded cards, generic SaaS templates, unnecessary animations, stock imagery without purpose, fake metrics, fabricated claims, corporate filler, AI buzzwords, repetitive layouts, meaningless icons, inaccessible controls, poor contrast, dead links, nonfunctional buttons, excessive dependencies, inconsistent design tokens, and unnecessary visual clutter.

Do not omit real product demos, skeleton loaders, loading/error/empty states, responsive mobile layouts, accessibility, functional interactions, Terms of Service, or a Privacy Policy where required. Never fabricate product capabilities, testimonials, statistics, security claims, or legal documents.

Prioritize: distinctive product-specific design, clear hierarchy, restrained colors, readable typography, sharp intentional geometry, genuine product visuals, accessible interactions, responsive layouts, maintainable code, and production quality. Audit every restriction before completion. If information is missing, ask instead of inventing it.
