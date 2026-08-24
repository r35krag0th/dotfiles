#!/usr/bin/env -S ${HOME}/.local/share/mise/shims/uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "flask>=3.0",
#     "pillow>=10.0",
# ]
# ///
import os
import sys
import glob
from io import BytesIO
from flask import Flask, send_file, request
from PIL import Image, ImageDraw, ImageFont

app = Flask(__name__)


# Logical font names -> ordered glob fallback chains. Resolution happens once at
# startup; a missing font degrades down its chain rather than returning a 500.
FONT_CHAINS = {
    "glyph": [
        # Narrow pattern first, on purpose: "PragmataProVF*liga*.ttf" below also
        # matches "PragmataProVF_Italic_liga_09.ttf", and sorted() puts that
        # ahead of the upright "PragmataProVF_liga_09.ttf" alphabetically
        # (uppercase 'I' < lowercase 'l'). That silently italicised every
        # glyph on the deck. This exact pattern matches only the upright face,
        # so it must stay first -- do not "simplify" it back into the loose
        # one below.
        "{home}/Library/Fonts/PragmataProVF_liga_*.ttf",
        "{home}/Library/Fonts/PragmataProVF*liga*.ttf",
        "{home}/Library/Fonts/PragmataProVF*.ttf",
        "{home}/Library/Fonts/*Nerd*Font*.ttf",
        "/Library/Fonts/*Nerd*Font*.ttf",
    ],
    "display": [
        # Aldrich is the user's choice for the date/time tiles. It is a STATIC
        # font (no variable axes), so a requested `weight` silently degrades to
        # its single weight -- load_font's try/except handles that. Orbitron
        # stays as a fallback and does honour weight, so a machine without
        # Aldrich still renders sensibly rather than dropping to PragmataPro.
        "{home}/Library/Fonts/Aldrich*.ttf",
        "/Library/Fonts/Aldrich*.ttf",
        "{home}/Library/Fonts/Orbitron*.ttf",
        "/Library/Fonts/Orbitron*.ttf",
        "{home}/Library/Fonts/PragmataProVF*.ttf",
    ],
}

RESOLVED_FONTS = {}


def resolve_fonts():
    home = os.path.expanduser("~")
    for name, patterns in FONT_CHAINS.items():
        for pattern in patterns:
            matches = sorted(glob.glob(pattern.format(home=home)))
            if matches:
                RESOLVED_FONTS[name] = matches[0]
                print(f"[icon-service] font {name!r} -> {matches[0]}")
                break
        else:
            print(f"[icon-service] WARNING: no font resolved for {name!r}", file=sys.stderr)


resolve_fonts()
if "glyph" not in RESOLVED_FONTS:
    print("ERROR: no glyph font found.", file=sys.stderr)
    sys.exit(1)


def load_font(name, size, weight=None):
    """Load a logical font by name, falling back to the glyph chain."""
    path = RESOLVED_FONTS.get(name) or RESOLVED_FONTS["glyph"]
    font = ImageFont.truetype(path, size)
    if weight:
        try:
            font.set_variation_by_name(weight)
        except Exception:
            pass  # static font, or no such named instance
    return font


@app.route("/generate", methods=["GET"])
def generate_icon():
    """Generate a Stream Deck XL icon (96x96).

    Query params:
      - glyph: Unicode codepoint (hex, e.g., f017 for nerd font icon)
      - glyph_color: Hex color (e.g., ffffff)
      - bg_color: Hex color (e.g., 141d3a)
      - glyph_size: Font size for glyph (default: 48)
      - label: Text label (optional, centered at bottom)
      - label_color: Hex color (default: ffffff)
      - label_size: Font size for label (default: 12)
      - font: logical font name for the label (default: "glyph")
      - glyph_font: logical font name for the glyph (default: "glyph")
      - weight: named variable-font instance for the label font, e.g. "Black"
    """
    try:
        glyph_hex = request.args.get("glyph") or "0000"
        glyph_color = request.args.get("glyph_color", "ffffff")
        bg_color = request.args.get("bg_color", "141d3a")
        glyph_size = int(request.args.get("glyph_size", 48))
        label = request.args.get("label", "").strip()
        label_color = request.args.get("label_color", "ffffff")
        label_size = int(request.args.get("label_size", 12))
        font_name = request.args.get("font", "glyph")
        glyph_font_name = request.args.get("glyph_font", "glyph")
        weight = request.args.get("weight")  # e.g. "Black" for variable fonts

        # Parse hex values
        glyph_unicode = int(glyph_hex, 16)
        has_glyph = glyph_unicode != 0
        glyph_char = chr(glyph_unicode)
        glyph_rgb = tuple(int(glyph_color[i: i + 2], 16) for i in (0, 2, 4))
        bg_rgb = tuple(int(bg_color[i: i + 2], 16) for i in (0, 2, 4))
        label_rgb = tuple(int(label_color[i: i + 2], 16) for i in (0, 2, 4))

        # Create image
        size = 96
        img = Image.new("RGB", (size, size), bg_rgb)
        draw = ImageDraw.Draw(img)

        # Load fonts
        try:
            glyph_font = load_font(glyph_font_name, glyph_size)
            label_font = load_font(font_name, label_size, weight)
        except Exception as e:
            print(f"Font load error: {e}", file=sys.stderr)
            raise

        # Draw glyph (centered, with space for label)
        if has_glyph:
            glyph_y_offset = 8 if label else 12
            bbox = draw.textbbox((0, 0), glyph_char, font=glyph_font)
            glyph_w = bbox[2] - bbox[0]
            glyph_h = bbox[3] - bbox[1]
            glyph_x = (size - glyph_w) / 2
            glyph_y = (size - glyph_h) / 2 - glyph_y_offset
            draw.text((glyph_x, glyph_y), glyph_char,
                      fill=glyph_rgb, font=glyph_font)

        # Draw label if provided
        if label:
            label_bbox = draw.textbbox((0, 0), label, font=label_font)
            label_w = label_bbox[2] - label_bbox[0]
            label_h = label_bbox[3] - label_bbox[1]
            label_x = (size - label_w) / 2
            if has_glyph:
                # Position so bottom of text is 5px from bottom of image --
                # correct for a caption beneath an icon.
                label_y = size - 5 - label_bbox[3]
            else:
                # No glyph: the label owns the whole tile, so centre it.
                label_y = (size - label_h) / 2 - label_bbox[1]
            draw.text((label_x, label_y), label,
                      fill=label_rgb, font=label_font)

        # Return PNG
        buf = BytesIO()
        img.save(buf, format="PNG")
        buf.seek(0)
        return send_file(buf, mimetype="image/png")

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return {"error": str(e)}, 500


@app.route("/health", methods=["GET"])
def health():
    return {"status": "ok", "fonts": RESOLVED_FONTS}


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5555, debug=False)
