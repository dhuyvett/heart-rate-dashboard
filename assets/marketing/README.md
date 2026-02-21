# Marketing Assets

This folder contains Play Store marketing graphics:

- `play_feature_graphic.svg` (source of truth)
- `play_feature_graphic.png` (rendered output for upload)

## Render SVG to PNG (Recommended)

The PNG should be rendered from the SVG with headless Chrome.  
Direct ImageMagick SVG rasterization in this environment may produce incorrect output.

Run from repo root:

```bash
cat > /tmp/render_feature_graphic_inline.html <<'EOF'
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <style>
    html, body { margin:0; padding:0; width:1024px; height:500px; overflow:hidden; background:#0E3B2D; }
    svg { display:block; width:1024px; height:500px; }
  </style>
</head>
<body>
EOF
cat assets/marketing/play_feature_graphic.svg >> /tmp/render_feature_graphic_inline.html
cat >> /tmp/render_feature_graphic_inline.html <<'EOF'
</body>
</html>
EOF
```

Capture and crop:

```bash
google-chrome \
  --headless \
  --disable-gpu \
  --force-device-scale-factor=1 \
  --virtual-time-budget=3000 \
  --screenshot=/tmp/play_feature_graphic_full.png \
  --window-size=1024,600 \
  file:///tmp/render_feature_graphic_inline.html

magick /tmp/play_feature_graphic_full.png \
  -crop 1024x500+0+0 +repage \
  assets/marketing/play_feature_graphic.png
```

## Verify Output

```bash
identify assets/marketing/play_feature_graphic.png
```

Expected dimensions:

- `1024x500`
