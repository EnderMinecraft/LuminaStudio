import os
import struct
import zlib
import math
import json
import zipfile

def create_png(width, height, color_func):
    """Generates an uncompressed/deflated raw PNG file without external dependencies."""
    raw_bytes = bytearray()
    for y in range(height):
        raw_bytes.append(0) # filter type 0 (None)
        for x in range(width):
            r, g, b, a = color_func(x, y, width, height)
            raw_bytes.extend([int(r), int(g), int(b), int(a)])
    
    compressed = zlib.compress(bytes(raw_bytes), level=6)
    
    # PNG signature
    png = bytearray(b'\x89PNG\r\n\x1a\n')
    
    # IHDR
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
    png.extend(struct.pack('>I', len(ihdr_data)))
    png.extend(b'IHDR')
    png.extend(ihdr_data)
    png.extend(struct.pack('>I', ihdr_crc))
    
    # IDAT
    idat_crc = zlib.crc32(b'IDAT' + compressed)
    png.extend(struct.pack('>I', len(compressed)))
    png.extend(b'IDAT')
    png.extend(compressed)
    png.extend(struct.pack('>I', idat_crc))
    
    # IEND
    iend_crc = zlib.crc32(b'IEND')
    png.extend(struct.pack('>I', 0))
    png.extend(b'IEND')
    png.extend(struct.pack('>I', iend_crc))
    
    return bytes(png)

def portrait_gradient(x, y, w, h):
    # Radial color gradient
    cx, cy = w / 2, h / 2
    dx = (x - cx) / (w / 2)
    dy = (y - cy) / (h / 2)
    dist = math.sqrt(dx*dx + dy*dy)
    r = min(255, max(0, int(180 + 70 * math.cos(dist * 3.0))))
    g = min(255, max(0, int(120 + 90 * math.sin(dist * 2.5))))
    b = min(255, max(0, int(220 - 80 * dist)))
    return r, g, b, 255

def cutout_subject(x, y, w, h):
    # Central disc subject over dark background
    cx, cy = w / 2, h / 2
    dist = math.sqrt((x - cx)**2 + (y - cy)**2)
    radius = min(w, h) * 0.35
    if dist < radius:
        # Subject: vibrant warm orange-pink
        return 245, 110, 60, 255
    else:
        # Background: deep dark teal
        return 15, 23, 42, 255

def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "SampleAssets")
    os.makedirs(out_dir, exist_ok=True)
    
    # 1. Portrait 2K test asset (1024x1024 for lightweight fast preview)
    portrait_png = create_png(512, 512, portrait_gradient)
    with open(os.path.join(out_dir, "Sample_Gradient_512.png"), "wb") as f:
        f.write(portrait_png)
    print("Created Sample_Gradient_512.png")
    
    # 2. Cutout subject test asset
    cutout_png = create_png(512, 512, cutout_subject)
    with open(os.path.join(out_dir, "Sample_Cutout_Subject_512.png"), "wb") as f:
        f.write(cutout_png)
    print("Created Sample_Cutout_Subject_512.png")
    
    # 3. Sample Vector SVG
    svg_content = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600" width="800" height="600">
  <rect width="100%" height="100%" fill="#0f172a"/>
  <circle cx="200" cy="300" r="120" fill="#3b82f6" fill-opacity="0.8"/>
  <rect x="320" y="180" width="240" height="240" rx="32" fill="#10b981" fill-opacity="0.8"/>
  <path d="M 600 200 C 650 150, 750 250, 700 350 S 600 450, 650 500" stroke="#f59e0b" stroke-width="8" fill="none"/>
</svg>"""
    with open(os.path.join(out_dir, "Sample_Vector.svg"), "w", encoding="utf-8") as f:
        f.write(svg_content)
    print("Created Sample_Vector.svg")

if __name__ == "__main__":
    main()
