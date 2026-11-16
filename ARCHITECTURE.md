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

## EditorCore: Adjustments & Filters Pipeline (Phase 3)
1. **Monotone Cubic Spline (`MonotoneCubicSpline`):**
   - Implements the Fritsch-Carlson algorithm on control points $(x_k, y_k) \in [0, 1]^2$.
   - Pre-computes 256-entry 8-bit lookup tables (LUTs) for $O(1)$ pixel transformation per channel.
   - Strictly monotonic: eliminates ringing, negative overshoots, and unnatural tone jumps.

2. **Non-Destructive Adjustments (`AdjustmentEngine`):**
   - Evaluates: Brightness/Contrast, Exposure EV ($2^{\Delta EV}$), Levels with variable midtone gamma ($1/\gamma$), HSL color shift, Vibrance (adaptive muted saturation boost), Color Balance, Temperature & Tint, Black & White mixer, and Vignette.

3. **GPU & Spatial Filters (`FilterEngine`):**
   - Separable Gaussian Blur ($O(N \cdot K)$ complexity instead of $O(N \cdot K^2)$).
   - Pixelate mosaic block rasterizer.
   - Chromatic Aberration with independent red/blue horizontal phase shifting.
   - Unsharp Mask: high-pass edge amplification ($I + \alpha(I - G(I))$).
   - Liquify push warp with smooth radial decay.

4. **Live Histogram & Auto-Enhance (`HistogramEngine` & `AutoEnhanceEngine`):**
   - Simultaneous 256-bin accumulation of Red, Green, Blue, and Rec. 601 Luminance channels.
   - Auto-Enhance evaluates 0.5% and 99.5% cumulative percentiles to establish optimal black/white points and expand dynamic range.

---

## EditorCore: Cutout & Refine Studio Pipeline (Phase 4)
1. **Vision Background Segmentation (`CutoutEngine`):**
   - Asynchronous execution of `VNGenerateForegroundInstanceMaskRequest` and `VNGeneratePersonSegmentationRequest`.
   - Produces non-destructive 8-bit `LayerMask` without modifying source image pixels.
2. **Refine Studio View (`CutoutRefineStudioView`):**
   - 6 overlay display modes: Faded original (0-60% opacity slider, 25% default), Red Tint (Quick Mask), Checkerboard, Solid color matte, Mask only (grayscale), and unmasked Original.
   - Zoom up to 3200% with procedural pixel grid shader active at $\ge 800\%$.
   - Viewport Mini-Map appearing automatically above 400% zoom.
   - Magnifier Loupe offset 85pt above touch point.
3. **Edge Refinement & Matting:**
   - **Smart Edge:** Local color variance bilateral/guided filter kernel snapping brush stamps to object boundaries.
   - **Hair / Fine Detail Matting:** Trimap generation (Keep/Remove/Unknown band) solving closed-form alpha matte projection.
   - **Color Decontamination:** Neutralizes background color bleeding along soft transition edges.
   - **Speck Removal:** 4-way Connected-Component Labeling (CCL) clearing disconnected noise components smaller than $N$ pixels.

---

## EditorCore: Text, Parametric Shapes & Layer Styles (Phase 5)
1. **Text Engine (`TextEngine`):**
   - CoreText attributed string rasterization to 32-bit premultiplied RGBA buffers.
   - Dynamic font metrics (ascent, descent, leading), kerning/tracking, line height, fill/stroke modes, and dynamic registration of custom TTF/OTF fonts via `CTFontManagerRegisterGraphicsFont`.
2. **Parametric Shape Engine (`ShapeEngine`):**
   - Direct procedural drawing for: Rectangles, Rounded Rectangles (squircle continuous curvature), Ellipses, Regular Polygons (3 to 12 vertices), Stars (configurable point count and inner radius factor), and Lines/Arrows.
   - Antialiased CoreGraphics rendering into 8-bit RGBA buffers cached as raster or vector layers.
3. **Layer Styles (`LayerStyle`):**
   - Non-destructive drop shadows with customizable blur radius, angle, distance, opacity, and color.
   - Multi-weight stroke outline (Inside, Center, Outside alignment).
   - Radial outer glow with soft exponential decay.
4. **Clipping Masks & Composition:**
   - Stack-order clipping mask flag: any layer flagged with `isClippingMask` inherits the alpha channel geometry of the underlying non-clipping base layer.
5. **Rulers, Grid & Localization:**
   - Sub-pixel horizontal and vertical rulers with adaptive scale intervals (10px, 50px, 100px, 500px) that recompute based on viewport zoom.
   - Native Apple String Catalog (`Localizable.xcstrings`) with English and Vietnamese translations.

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
