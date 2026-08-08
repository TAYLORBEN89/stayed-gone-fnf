# SECOND DIBS — Kain vs Kross vs Koal

Browser **Friday Night Funkin'–style** rhythm game. Static HTML5 — deploys cleanly on **Vercel**.

Menu background: `public/assets/kano_cat_menu_video.mp4` (looping, muted).

## Play

- **Controls:** `← ↓ ↑ →` or `W A S D` (player / Kain side)
- **Menu:** arrows + Enter · **Esc** pause / back
- **Story** starts the main chart · **Freeplay** picks songs · **Botplay** in Options

## Local dev

```bash
npm start
# → http://localhost:3000
```

Or open `public/index.html` via any static server (ES modules need HTTP).

## Deploy (Vercel + GitHub)

```bash
npx vercel --prod
```

`vercel.json` serves the `public/` folder as a static site.

## Project layout

```
public/
  index.html
  css/style.css
  js/main.js, game.js, charts.js, audio.js
  assets/kano_cat_menu_video.mp4
```

## Next (planned)

- Character select (Kain / Kross / Koal)
- Per-arrow key images (up/down/left/right) behind the note highway
