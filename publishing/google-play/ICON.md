# Slide Puzzle icon

Created with the built-in imagegen tool on 2026-10-22.

- `icon-512.png`: Google Play store icon, 512×512, 32-bit RGBA PNG, fully opaque, under 1 MiB. Upload this file in the store listing's app icon field.
- `icon-master.png`: original generated master, preserved without modification.
- `../../assets/branding/slide-puzzle-icon.png`: 1024×1024 PNG from the initial candidate. The preferred adaptive set is documented in `../icons/README.md`.

The ivory background fills the square canvas. No rounded app-icon mask is baked into the outer image.
The publishing folder has `.gdignore` so store artwork is not bundled into the game.

## Generation prompt

Use case: logo-brand. Asset type: final mobile game app icon for Google Play, a square PNG master, 1024 by 1024. Create one polished original icon for a cozy wooden sliding number puzzle game. Straight-on, perfectly front-facing square wooden puzzle tray centered on a full-bleed opaque warm ivory background. The tray contains a clear 2 by 2 grid: three large softly beveled honey-colored wooden square tiles engraved with dark walnut numerals 1 (top left), 2 (top right), 3 (bottom left), and an empty deep walnut recessed square at bottom right. Precise aligned geometry, generous tile size, beautifully rounded tile corners, tactile satin wood, fine restrained woodgrain, warm golden edges, subtle dimensional relief and soft lighting. The board occupies about 76 percent of the image width, with the numerals large and extremely readable even at small app-icon size. Sophisticated casual-game art, inviting and clean, harmonious amber/walnut/cream palette, matching a relaxing wooden sliding puzzle interface. The outer image itself must remain a full square with opaque ivory reaching all four edges: no pre-rounded app-icon mask, no transparent corners, no external frame or phone mockup, no drop shadow around the outer canvas. No text except the three numerals 1, 2, 3. No letters, logos, watermark, badges, stars, sparkles, arrows, extra tiles, scenery, perspective tilt, or busy decoration. Deliver a single finished icon, not a presentation sheet.

## Export

The original generated image was square, 1254×1254. Godot's Image API exported the app and store sizes using Lanczos resampling, preserving fully opaque pixels and 8-bit RGBA channels. The Play Store file is 409,948 bytes.
