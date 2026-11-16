# Lumina Studio (iOS & iPadOS)

Lumina Studio is a professional-grade, multi-workspace image editing suite for iPhone and iPad, written entirely in Swift. It features a layer-based raster editor with non-destructive adjustments, a dedicated background removal and cutout refine editor, a resolution-independent vector workspace, and a fast collage mini mode.

---

## Workspaces
1. **Photo Workspace (Raster Editor):**
   - High-performance Metal tile compositor supporting canvases up to 8192×8192 px.
   - Smooth pinch-to-zoom (up to 3200%), two-finger pan, canvas rotation, and double-tap to fit.
   - Non-destructive layer stack: Raster, Adjustment, Text, Shape, Vector, and Group layers.
   - Full blend mode suite (16 modes) with exact mathematical blending.
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
- `Packages/EditorCore`: UI-agnostic raster graphics engine, tiled compositor, layer models, brush/selection systems, and document packaging.
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
- [ ] **Phase 2: Core Tools** (Move/Transform, Crop, Brushes, Eyedropper, Flood Fill, Selections, Marching Ants)
- [ ] **Phase 3: Adjustments & Filters** (Curves spline editor, Metal filters, live histogram, auto-enhance)
- [ ] **Phase 4: Cutout & Refine Studio** (Vision segmentation, 6 overlay modes, smart edge guided filter, loupe)
- [ ] **Phase 5: Text, Shapes & Polish** (Typography, parametric shapes, Pencil hover/pressure, localization)
- [ ] **Phase 6: Vector Workspace** (Artboards, Pen/Node tool, Boolean ops, SVG/PDF, image tracing)
- [ ] **Phase 7: Collage Mini Mode** (4-tap flow, 40+ templates, divider dragging, Photo handoff)
