#!/usr/bin/env python3
"""Generate Rewind Survivor app icon - 1024x1024 clean neon style."""

from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 255))
draw = ImageDraw.Draw(img)

# ======= HELPERS =======
def blend_pixel(img, x, y, color):
    """Alpha-blend a color onto an existing pixel."""
    if 0 <= x < SIZE and 0 <= y < SIZE:
        bg = img.getpixel((x, y))
        a = color[3] / 255.0
        r = int(bg[0] * (1 - a) + color[0] * a)
        g = int(bg[1] * (1 - a) + color[1] * a)
        b = int(bg[2] * (1 - a) + color[2] * a)
        img.putpixel((x, y), (r, g, b, 255))

def draw_soft_circle(layer, cx, cy, radius, color):
    """Draw a soft glowing circle on a layer."""
    r2 = radius * radius
    for y in range(max(0, int(cy - radius)), min(SIZE, int(cy + radius) + 1)):
        for x in range(max(0, int(cx - radius)), min(SIZE, int(cx + radius) + 1)):
            dx, dy = x - cx, y - cy
            d2 = dx * dx + dy * dy
            if d2 < r2:
                t = 1.0 - math.sqrt(d2) / radius
                a = int(color[3] * t * t)
                if a > 0:
                    ex = layer.getpixel((x, y))
                    na = min(255, ex[3] + a)
                    nr = min(255, int((ex[0] * ex[3] + color[0] * a) / max(1, na)))
                    ng = min(255, int((ex[1] * ex[3] + color[1] * a) / max(1, na)))
                    nb = min(255, int((ex[2] * ex[3] + color[2] * a) / max(1, na)))
                    layer.putpixel((x, y), (nr, ng, nb, na))

# ======= BACKGROUND =======
# Rich dark gradient with subtle purple
for y in range(SIZE):
    for x in range(SIZE):
        dx, dy = x - SIZE // 2, y - SIZE // 2
        dist = math.sqrt(dx * dx + dy * dy)
        t = min(1.0, dist / (SIZE * 0.7))
        # Center: dark navy, edges: deeper dark
        r = int(12 * (1 - t * 0.5) + 4 * t)
        g = int(10 * (1 - t * 0.5) + 3 * t)
        b = int(28 * (1 - t * 0.3) + 10 * t)
        img.putpixel((x, y), (r, g, b, 255))

# ======= PIXEL GRID SCALE =======
P = 28  # pixel size - gives ~36x36 grid, character fills nicely

def px(gx, gy, color):
    """Draw a pixel-art block."""
    x1 = int(gx * P)
    y1 = int(gy * P)
    x2 = int(x1 + P - 1)
    y2 = int(y1 + P - 1)
    if x1 < SIZE and y1 < SIZE and x2 >= 0 and y2 >= 0:
        x1 = max(0, x1)
        y1 = max(0, y1)
        x2 = min(SIZE - 1, x2)
        y2 = min(SIZE - 1, y2)
        draw.rectangle([x1, y1, x2, y2], fill=color)

GRID = SIZE // P  # ~36

# ======= COLORS =======
cyan = (0, 245, 255, 255)
blue = (0, 130, 200, 255)
dark_blue = (0, 50, 100, 255)
visor = (75, 255, 215, 255)
white = (255, 255, 255, 255)
highlight = (140, 240, 255, 255)
armor = (12, 140, 218, 255)
armor_dark = (8, 95, 160, 255)
boot = (0, 65, 140, 255)
belt_col = (0, 40, 90, 255)
buckle = (220, 195, 60, 255)
outline = (0, 20, 50, 255)
ghost_col = (80, 200, 255)

# ======= CHARACTER CENTER =======
cx = GRID // 2  # ~18
cy_top = 5  # Character starts here

# ======= GHOST ECHO (behind player, offset) =======
gox, goy = -3, -1
ga = 55  # ghost alpha

# Ghost helmet
for y in range(cy_top + 1, cy_top + 9):
    hw = min(y - cy_top, 6)
    for x in range(cx + gox - hw, cx + gox + hw + 1):
        px(x, y + goy, (*ghost_col, ga))

# Ghost visor
for x in range(cx + gox - 5, cx + gox + 6):
    px(x, cy_top + 5 + goy, (*ghost_col, ga + 30))

# Ghost torso
for y in range(cy_top + 9, cy_top + 18):
    hw = max(2, 6 - (y - cy_top - 9) // 2)
    fade = max(10, ga - (y - cy_top - 9) * 5)
    for x in range(cx + gox - hw, cx + gox + hw + 1):
        px(x, y + goy, (*ghost_col, fade))

# Ghost wispy trails
for y in range(cy_top + 18, cy_top + 25):
    fade = max(5, 40 - (y - cy_top - 18) * 5)
    w = 1 if (y % 3) == 0 else 0
    px(cx + gox - 2 - w, y + goy, (*ghost_col, fade))
    px(cx + gox, y + goy, (*ghost_col, fade))
    px(cx + gox + 2 + w, y + goy, (*ghost_col, fade))

# ======= MAIN CHARACTER =======

# -- Helmet crest (antenna) --
px(cx, cy_top - 1, cyan)
px(cx - 1, cy_top, cyan)
px(cx, cy_top, highlight)
px(cx + 1, cy_top, cyan)

# -- Helmet shell --
for y in range(cy_top + 1, cy_top + 9):
    hw = min(y - cy_top, 6)
    for x in range(cx - hw, cx + hw + 1):
        # Shading: left highlight, right shadow
        if x < cx - hw + 2:
            px(x, y, highlight)
        elif x > cx + hw - 2:
            px(x, y, dark_blue)
        else:
            px(x, y, blue)
    # Outline
    px(cx - hw - 1, y, outline)
    px(cx + hw + 1, y, outline)

# Top outline
for x in range(cx - 1, cx + 2):
    px(x, cy_top, cyan)
px(cx - 2, cy_top + 1, outline)
px(cx + 2, cy_top + 1, outline)

# Bottom helmet outline
for x in range(cx - 7, cx + 8):
    px(x, cy_top + 8, outline)

# -- Visor (the iconic element) --
visor_y = cy_top + 5
# Dark visor band
for x in range(cx - 5, cx + 6):
    px(x, visor_y, outline)
    px(x, visor_y + 1, (0, 30, 60, 255))

# Glowing visor eyes
for x in [cx - 4, cx - 3, cx - 2]:
    px(x, visor_y, visor)
    px(x, visor_y + 1, (40, 200, 170, 255))
for x in [cx + 2, cx + 3, cx + 4]:
    px(x, visor_y, visor)
    px(x, visor_y + 1, (40, 200, 170, 255))

# -- Torso / Armor --
torso_top = cy_top + 9
for y in range(torso_top, torso_top + 10):
    dy = y - torso_top
    if dy < 3:
        hw = 7
    elif dy < 6:
        hw = 6
    elif dy < 8:
        hw = 5
    else:
        hw = 5
    for x in range(cx - hw, cx + hw + 1):
        if x < cx - hw + 2:
            px(x, y, armor)
        elif x > cx + hw - 2:
            px(x, y, armor_dark)
        else:
            px(x, y, armor)
    # Outline
    px(cx - hw - 1, y, outline)
    px(cx + hw + 1, y, outline)

# Chest plate (center bright area)
for y in range(torso_top, torso_top + 5):
    for x in range(cx - 3, cx + 4):
        px(x, y, cyan)

# Chest emblem - diamond/gem
px(cx, torso_top + 1, white)
px(cx - 1, torso_top + 2, visor)
px(cx, torso_top + 2, white)
px(cx + 1, torso_top + 2, visor)
px(cx - 2, torso_top + 3, (0, 180, 170, 255))
px(cx - 1, torso_top + 3, visor)
px(cx, torso_top + 3, visor)
px(cx + 1, torso_top + 3, visor)
px(cx + 2, torso_top + 3, (0, 180, 170, 255))
px(cx - 1, torso_top + 4, visor)
px(cx, torso_top + 4, white)
px(cx + 1, torso_top + 4, visor)

# Belt
belt_y = torso_top + 8
for x in range(cx - 5, cx + 6):
    px(x, belt_y, belt_col)
px(cx - 1, belt_y, buckle)
px(cx, belt_y, buckle)
px(cx + 1, belt_y, buckle)

# -- Shoulder pads --
for y in range(torso_top, torso_top + 4):
    px(cx - 9, y, blue)
    px(cx - 8, y, blue)
    px(cx + 8, y, blue)
    px(cx + 9, y, blue)
px(cx - 9, torso_top, highlight)
px(cx + 9, torso_top, highlight)
px(cx - 10, torso_top + 2, outline)
px(cx + 10, torso_top + 2, outline)

# -- Arms --
for y in range(torso_top + 4, torso_top + 9):
    px(cx - 8, y, armor)
    px(cx - 9, y, armor_dark)
    px(cx + 8, y, armor)
    px(cx + 9, y, armor_dark)
# Hands
px(cx - 8, torso_top + 9, cyan)
px(cx - 9, torso_top + 9, cyan)
px(cx + 8, torso_top + 9, cyan)
px(cx + 9, torso_top + 9, cyan)

# -- Legs --
legs_top = torso_top + 10
for y in range(legs_top, legs_top + 8):
    # Left leg
    px(cx - 3, y, blue)
    px(cx - 2, y, armor)
    px(cx - 1, y, armor_dark)
    # Right leg
    px(cx + 1, y, armor_dark)
    px(cx + 2, y, armor)
    px(cx + 3, y, blue)
    # Gap between legs
    # Outer outlines
    px(cx - 4, y, outline)
    px(cx + 4, y, outline)

# Boots
boot_y = legs_top + 8
for x in range(cx - 4, cx):
    px(x, boot_y, boot)
    px(x, boot_y + 1, boot)
for x in range(cx + 1, cx + 5):
    px(x, boot_y, boot)
    px(x, boot_y + 1, boot)
# Boot highlight
px(cx - 4, boot_y, armor)
px(cx + 1, boot_y, armor)

# ======= REWIND ARROWS (left side, subtle) =======
arrow_y = cy_top + 12
arrow_col = (255, 0, 255, 130)
for a in range(2):
    ax = 3 + a * 5
    for i in range(4):
        px(ax + i, arrow_y - i, arrow_col)
        px(ax + i, arrow_y + i, arrow_col)

# ======= BULLET TRAILS (right side) =======
bullet_bright = (0, 255, 136, 230)
bullet_dim = (0, 255, 136, 100)
# Trail going upper-right
for i in range(6):
    bx = cx + 10 + i * 2
    by = torso_top + 2 - i
    if bx < GRID and by >= 0:
        px(bx, by, bullet_bright)
        px(bx + 1, by, bullet_dim)

# Trail going lower-right
for i in range(5):
    bx = cx + 10 + i * 2
    by = torso_top + 4 + i
    if bx < GRID:
        px(bx, by, bullet_bright)
        px(bx + 1, by, bullet_dim)

# ======= SCATTERED ENEMY EYES (background) =======
enemy_positions = [
    (4, 6), (GRID - 5, 7),
    (3, GRID - 8), (GRID - 4, GRID - 7),
    (5, cy_top + 20), (GRID - 6, cy_top + 18),
    (GRID - 5, cy_top + 2), (6, cy_top + 3),
]
for ex, ey in enemy_positions:
    dist = math.sqrt((ex - cx) ** 2 + (ey - (cy_top + 12)) ** 2)
    if dist > 12:
        alpha = max(50, int(150 - dist * 3))
        # Two red eyes
        px(ex, ey, (255, 60, 60, alpha))
        px(ex + 1, ey, (255, 60, 60, alpha))

# ======= POST-PROCESSING: GLOW EFFECTS =======
img_flat = img.copy().convert("RGBA")

glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

# Visor glow (most prominent)
draw_soft_circle(glow_layer, cx * P + P // 2, (visor_y) * P + P // 2, 140, (75, 255, 215, 60))

# Ghost glow
draw_soft_circle(glow_layer, (cx + gox) * P, (cy_top + 5 + goy) * P, 180, (80, 200, 255, 35))

# Chest emblem glow
draw_soft_circle(glow_layer, cx * P + P // 2, (torso_top + 3) * P + P // 2, 100, (0, 245, 255, 45))

# Bullet trail glow
draw_soft_circle(glow_layer, (cx + 14) * P, (torso_top + 2) * P, 80, (0, 255, 136, 30))
draw_soft_circle(glow_layer, (cx + 14) * P, (torso_top + 6) * P, 80, (0, 255, 136, 25))

# Rewind arrows glow
draw_soft_circle(glow_layer, 5 * P, arrow_y * P, 100, (255, 0, 255, 25))

# Blur the glow
glow_blurred = glow_layer.filter(ImageFilter.GaussianBlur(radius=30))

# Composite
result = Image.alpha_composite(img_flat, glow_blurred)

# ======= SUBTLE SCANLINES (very faint, every 4 real pixels) =======
scanline_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
sl_draw = ImageDraw.Draw(scanline_layer)
for y in range(0, SIZE, 4):
    sl_draw.line([(0, y), (SIZE - 1, y)], fill=(0, 0, 0, 15))

result = Image.alpha_composite(result, scanline_layer)

# ======= SAVE =======
output_path = "/Users/cdalen/Repos/Rewind Survivor/Rewind Survivor Shared/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
result.save(output_path, "PNG")
print(f"Icon saved to {output_path}")
print(f"Size: {result.size}")
