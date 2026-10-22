# Shape-safe Slide Puzzle icons

Preferred icon set, prepared 2026-10-22. The platform applies its own outer shape; the square master has an opaque full-bleed cream background, without a baked outer mask.

## Files

| File | Purpose |
|---|---|
| `google-play-512.png` | Google Play listing: 512×512 RGBA PNG, fully opaque, 185,872 bytes |
| `icon-square-1024.png` | Square master / iOS source artwork, 1024×1024, fully opaque |
| `slide-puzzle.ico` | Windows icon container: 16, 32, 48, 64, 128, 256 px |
| `slide-puzzle.icns` | macOS icon container: 128, 256, 512, 1024 px |
| `web-maskable-512.png` | Web maskable icon with extra safe padding |
| `icon-*.png` | Square sizes for desktop, web and touch icon exports |
| `shape-previews.png` | Left: circle; middle: rounded square; right: squircle, simulating Android's visible 72dp viewport |
| `preview-*.png` | Individual mask simulations, for inspection only |

## App assets and configuration

`project.godot` points to `assets/branding/slide-puzzle-icon-adaptive.png`.
Android's export preset explicitly uses:

- `slide-puzzle-adaptive-foreground.png`: 432×432 transparent foreground.
- `slide-puzzle-adaptive-background.png`: 432×432 opaque cream background.
- `slide-puzzle-monochrome.png`: 432×432 white-on-transparent outline mark for themed icons. Its editable source is `slide-puzzle-monochrome.svg`.

Foreground content with alpha ≥ 0.1 was checked pixel-by-pixel against the centered 264px diameter safe circle (66dp in a 108dp / 432px canvas). Soft antialiasing may extend beyond the visible content bounds.
The original non-adaptive candidate is retained in `publishing/google-play/`.
These are source assets and simulated masks; physical-device launcher checks and platform release builds remain to be done.

References: [Android adaptive icon design](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive), [Godot Android icon export options](https://docs.godotengine.org/en/4.5/classes/class_editorexportplatformandroid.html), [Apple app icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons/).

## Image source and edit prompt

The built-in imagegen tool extracted the board from the original generated master. Source output was preserved as `../google-play/icon-foreground-master.png`. Padding, resampling, compositing and format exports were performed with Godot's Image API; ICO/ICNS containers wrap the exported PNG sizes. The monochrome SVG extends the project's existing geometric tile motif.

Exact edit prompt:

Use case: background-extraction. Edit target: the supplied wooden 1-2-3 sliding puzzle app icon. Produce the foreground layer for an adaptive app icon. Remove ONLY the entire ivory background and any external cast shadow, leaving genuine transparent alpha outside the wooden puzzle tray. Preserve the front-facing wooden square tray, rounded wooden corners, honey tiles, engraved numeral shapes 1 2 3, empty bottom-right walnut recess, internal shading and fine woodgrain. Keep all four outer board edges intact, not clipped. Center the complete board, with transparent padding on all sides. Do not add a checkerboard pattern or a white background; use actual transparency. No additional text, no badges, no new objects. The output is a single square transparent PNG cutout, not a mockup or a contact sheet.
