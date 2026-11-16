# Lumina Studio — System Architecture

## Overview
Lumina Studio is architected around strict separation of concerns, dividing domain logic into three independent, platform-agnostic Swift packages (`EditorCore`, `VectorCore`, `CollageCore`) and keeping the application target (`LuminaStudio`) lightweight, reactive, and thin.

---

## Workspace State Management & Zero State Loss
The `RootCoordinator` lives at the application root:
- Holds references to `photoDocument`, `vectorDocument`, and `collageDocument`.
- Each workspace maintains its own `CommandManager` history stack.
- Switching tabs switches the active presentation layer while preserving memory and execution state across all three workspaces.

---

## EditorCore: Tiled Compositor & Memory Management
- **Tile Grid:** The canvas is mapped onto a sparse grid of 256×256 tiles.
- **Sparse Allocations:** Memory is only allocated for non-empty tiles, allowing canvases up to 8192×8192 px to run within mobile memory limits.
- **Tile Cache:** Thread-safe LRU `TileCache` evicts off-screen tiles under system memory pressure.
- **Shaders:** Metal compute & fragment shaders (`CompositorShaders.metal`) perform blending, opacity scaling, and high-zoom pixel-grid rendering.

---

## EditorCore: Core Tools Subsystem (Phase 2)
1. **Transform Subsystem (`TransformEngine`):**
   - 8 interactive handles and rotation stalk.
   - Magnetic snapping to canvas center axes ($X, Y$), canvas edges, and 0/90/180/270° angle targets.
   - Decomposition of affine transform into translation, scale, rotation, and flips.

2. **Crop Subsystem (`CropEngine`):**
   - Aspect ratio constraints (Free, 1:1, 4:5, 3:4, 16:9, 9:16, 2:3).
   - Dynamic rule-of-thirds grid computation.
   - Real-time layer clipping and pixel alignment adjustment via `CropDocumentCommand`.

3. **Brush & Smudge Engine (`BrushEngine`):**
   - Catmull-Rom cubic spline interpolation for high-frequency touch sampling.
   - Stamp spacing calculation ($d \le \text{spacing} \times \text{size}$).
   - Radial hardness falloff with cosine profile for soft airbrushes through hard inks.
   - Direct targeting of layer RGBA buffers or single-channel 8-bit layer masks.

4. **Selection Subsystem (`SelectionEngine` & `MarchingAntsGenerator`):**
   - 8-bit mask rasterization for Rect, Ellipse, Lasso, Polygonal Lasso, and Magic Wand.
   - Vision subject isolation via `VNGenerateForegroundInstanceMaskRequest`.
   - Boolean combining: Replace, Add, Subtract, Intersect.
   - Morphological operations: Separation box-blur feathering, dilation (expand), erosion (contract).
   - Animated marching ants border extraction using sub-pixel phase dashes.

---

## VectorCore: Hybrid Scene Graph & Calculus
- **Scene Graph:** Tree of `ArtboardNode` containing `VectorNode` instances (`PathNode`, `ParametricShapeNode`, `VectorTextNode`, `VectorGroupNode`).
- **Bezier Calculus:** `BezierCurveSegment` evaluates cubic Bezier splines using Bernstein polynomials and de Casteljau subdivision.
- **Rendering Choice:** Option C (Hybrid Tile-Cached Core Graphics + Metal Compositor) guarantees 60 fps with 5,000+ nodes while ensuring 100% native typography, stroke mitering, and lossless PDF/SVG export.

---

## CollageCore: Binary Space Partitioning (BSP) Engine
- **Tree Structure:** `CollageLayoutNode` recursively splits layout rectangles horizontally or vertically with normalized ratios.
- **Responsive Normalization:** Any template reflows automatically to any aspect ratio (1:1, 4:5, 9:16, 16:9, A4) without losing cell alignments.
- **Template Registry:** 40+ built-in templates parameterized for 2 to 12 photos.

---

## Document Persistence
- **Package Container:** Packaged via `FileWrapper` as `.lumina`, `.luminavec`, and `.luminacollage`.
- **Layout:**
  - `manifest.json`: Metadata, app version, dimensions, timestamps.
  - `document.json`: Serialized JSON scene graph.
  - `assets/`: Raw RGBA tile bytes and binary mask streams.
