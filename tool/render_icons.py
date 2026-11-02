"""Renders Ka7's app icons from ../ka7-brand/ka7-icon.svg into app/assets/icon/.

uv run --with cairosvg python -I tool/render_icons.py

- ka7-square.png: full bleed, no corners, no transparency (iOS and old
  Android masks round it themselves).
- ka7-rounded.png: the brand icon as drawn (desktop).
- ka7-foreground.png / ka7-background.png: Android adaptive icon layers; the
  cassette sits inside the 66% safe zone so no mask crops it.
- ka7-monochrome.png: Android 13+ themed icon, the ka7-icon-mono.svg shape.
"""

import re
import sys
from pathlib import Path

import cairosvg

root = Path(__file__).resolve().parent.parent
svg = (root.parent / "ka7-brand" / "ka7-icon.svg").read_text()
out = root / "app" / "assets" / "icon"
out.mkdir(parents=True, exist_ok=True)

defs = re.search(r"<defs>.*?</defs>", svg, re.S).group(0)
cassette = re.search(r"<g transform=.*?</g>", svg, re.S).group(0)
head = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'


def render(name: str, body: str) -> None:
    cairosvg.svg2png(
        bytestring=f"{head}{defs}{body}</svg>".encode(),
        write_to=str(out / name),
        output_width=1024,
        output_height=1024,
    )


background = '<rect width="1024" height="1024" fill="url(#bg)"/>'
render("ka7-rounded.png", svg[svg.index(">", svg.index("<svg")) + 1 : svg.rindex("</svg>")])
render("ka7-square.png", background + cassette)
render("ka7-background.png", background)
# Largest cassette whose diagonal (1.25 x width) fits the 676 px safe circle.
scale = 676 / 1.25 / 160
width, height = 160 * scale, 120 * scale
small = re.sub(
    r'translate\([^)]*\) scale\([^)]*\)',
    f"translate({(1024 - width) / 2:.1f} {(1024 - height) / 2:.1f}) scale({scale:.3f})",
    cassette,
)
render("ka7-foreground.png", small)

# Themed icon (Android 13+): one-color silhouette, cut with even-odd paths
# (cairosvg ignores the SVG mask of ka7-icon-mono.svg), same safe-zone size.
def rrect(x, y, w, h, r):
    return (
        f"M{x + r},{y} H{x + w - r} A{r},{r} 0 0 1 {x + w},{y + r} V{y + h - r} "
        f"A{r},{r} 0 0 1 {x + w - r},{y + h} H{x + r} A{r},{r} 0 0 1 {x},{y + h - r} "
        f"V{y + r} A{r},{r} 0 0 1 {x + r},{y} Z"
    )


def circle(cx, cy, r):
    return f"M{cx - r},{cy} A{r},{r} 0 1 0 {cx + r},{cy} A{r},{r} 0 1 0 {cx - r},{cy} Z"


body = " ".join(
    [rrect(4, 4, 152, 112, 16), rrect(18, 18, 124, 56, 10), "M38,116 L47,90 H113 L122,116 Z"]
)
reels = " ".join(
    [circle(52, 44, 17), circle(52, 44, 6), circle(108, 44, 17), circle(108, 44, 6)]
)
side = 1024 / scale
cairosvg.svg2png(
    bytestring=(
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'viewBox="{-(side - 160) / 2:.2f} {-(side - 120) / 2:.2f} {side:.2f} {side:.2f}">'
        f'<path fill="#000" fill-rule="evenodd" d="{body}"/>'
        f'<path fill="#000" fill-rule="evenodd" d="{reels}"/></svg>'
    ).encode(),
    write_to=str(out / "ka7-monochrome.png"),
    output_width=1024,
    output_height=1024,
)
print("\n".join(sorted(p.name for p in out.iterdir())), file=sys.stderr)
