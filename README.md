# Lumina Studio (iOS & iPadOS)

Lumina Studio is a professional-grade, multi-workspace image editing suite for iPhone and iPad, written entirely in Swift. It features a layer-based raster editor with non-destructive adjustments, a dedicated background removal and cutout refine editor, a resolution-independent vector workspace, and a fast collage mini mode.

---

## Workspaces
1. **Photo Workspace (Raster Editor):**
   - High-performance Metal tile compositor supporting canvases up to 8192×8192 px.
   - Smooth pinch-to-zoom (up to 3200%), two-finger pan, canvas rotation, and double-tap to fit.
   - Non-destructive layer stack: Raster, Adjustment, Text, Shape, Vector, and Group layers.
   - Full blend mode suite (16 modes) with exact mathematical blending.
   - **Core Editing Tools:**
     - **Move & Transform:** Translate, scale, rotate, flip (H/V), free transform with 8 interactive handles, and snapping guides (center X/Y, canvas edges, 0/90/180/270° rotation lock).
     - **Crop:** Aspect presets (Free, 1:1, 4:5, 3:4, 16:9, 9:16, 2:3), straighten angle slider (-45° to +45°), and rule-of-thirds grid overlay.
     - **Brushes, Eraser & Smudge:** Stamp-based compute engine with Catmull-Rom smoothing, hardness falloff, flow accumulation, Apple Pencil pressure curves, and presets (Round Soft, Round Hard, Pencil, Ink Pen, Marker, Airbrush, Eraser, Smudge).
     - **Color Tools:** Eyedropper with 1x1, 3x3, and 5x5 aperture sampling, contiguous/non-contiguous flood fill with tolerance, linear and radial gradient engines.
     - **Selection Engine:** Mask-based selections with Rectangle, Ellipse, Lasso, Polygonal Lasso, Magic Wand, and Vision subject selection (`VNGenerateForegroundInstanceMaskRequest`).
     - **Selection Operations:** Invert, feather, expand, contract, select all, deselect, and animated marching ants boundary overlay.
     - **Layer Masks:** Paint directly on masks, invert mask, apply mask (alpha bake), and enable/disable mask toggle.
   - **Adjustments & Filters (Phase 3):**
     - **Non-Destructive Adjustments:** Brightness/Contrast, Exposure, Levels, Tone Curves (interactive Fritsch-Carlson monotone cubic spline editor), Hue/Saturation, Vibrance, Color Balance, Temperature/Tint, Black & White, Vignette.
     - **Filters:** Gaussian Blur, Motion Blur, Radial Blur, Pixelate, Add Noise, Unsharp Mask, Chromatic Aberration / Glitch, Liquify (Push Warp).
     - **Clone Stamp & Spot Healing:** Offset sampling and seamless texture transfer.
     - **Live Histogram:** Real-time 256-bin multi-channel distribution (Red, Green, Blue, Luminance).
     - **Before / After Comparison:** Instant press-and-hold bypass of all adjustments.
     - **On-Device Auto-Enhance:** Automatic histogram dynamic range leveling and color cast correction.
   - Unified command system with unlimited undo/redo, two-finger tap (Undo), three-finger tap (Redo), and a visual History Panel.
   - Document persistence via `.lumina` zipped file packages.
   - Export to PNG, JPEG (quality slider), and HEIC.

2. **Vector Workspace:**
   - Artboard scene graph (`VectorDocument`, `ArtboardNode`, `VectorNode`).
   - Cubic Bezier curve math, de Casteljau splitting, and bounding box evaluations.
   - Hybrid Tile-Cached Core Graphics + Metal Canvas Compositor architecture.
   - Native `.luminavec` persistence and lossless SVG/PDF export.

3. **Collage Mini Mode:**
   - Binary Space Partitioning (BSP) layout tree engine.
   - Over 40 responsive built-in templates (grids, strips, hero, mosaics, L-shapes).
   - Live divider dragging with magnetic ratio snapping.
   - Native `.luminacollage` persistence and direct handoff to Photo editor as layered documents.

---

## Architecture & Project Structure
- `LuminaStudio.xcodeproj`: Main iOS/iPadOS application target with SwiftUI chrome, adaptive navigation, and MetalKit views.
- `Packages/EditorCore`: UI-agnostic raster graphics engine, tiled compositor, layer models, brush/selection systems, adjustment pipelines, and document packaging.
- `Packages/VectorCore`: Vector scene graph, Bezier calculus, boolean operation protocols, and tracing engines.
- `Packages/CollageCore`: BSP tree layout solver, ratio calculations, and 40+ template definitions.
- `SampleAssets/`: Programmatically generated test assets (gradients, cutout masks, vector SVGs).

---

## Setup & Running
1. Open `LuminaStudio.xcodeproj` in Xcode 15+ (macOS 14+).
2. Select target `LuminaStudio` and an iOS 17+ Simulator (e.g., iPad Pro 13-inch or iPhone 15 Pro).
3. Build and Run (`Cmd+R`).
4. To run package tests:
   ```bash
   swift test --package-path Packages/EditorCore
   swift test --package-path Packages/VectorCore
   swift test --package-path Packages/CollageCore
   ```

---

## Feature Roadmap & Status
- [x] **Phase 1: Foundation** (Metal canvas, viewport navigation, layer panel, undo/redo, .lumina I/O, workspace switcher)
- [x] **Phase 2: Core Tools** (Move/Transform, Crop, Brushes, Eyedropper, Flood Fill, Selections, Marching Ants, Layer Masks)
- [x] **Phase 3: Adjustments & Filters** (Curves spline editor, Metal filters, live histogram, auto-enhance, clone stamp)
- [x] **Phase 4: Cutout & Refine Studio** (Vision segmentation, 6 overlay modes, smart edge guided filter, hair matting, loupe, specks cleanup)
- [ ] **Phase 5: Text, Shapes & Polish** (Typography, parametric shapes, Pencil hover/pressure, localization)
- [ ] **Phase 6: Vector Workspace** (Artboards, Pen/Node tool, Boolean ops, SVG/PDF, image tracing)
- [ ] **Phase 7: Collage Mini Mode** (4-tap flow, 40+ templates, divider dragging, Photo handoff)
