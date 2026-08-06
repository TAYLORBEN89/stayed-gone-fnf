# STAYED GONE — Vox vs Alastor

Browser **Friday Night Funkin'–style** rhythm game themed around the *Stayed Gone* duel (Vox vs Alastor). Static HTML5 — deploys cleanly on **Vercel**.

> Fan project. Hazbin Hotel characters/song and Friday Night Funkin' are owned by their respective creators. No official affiliation. Demo uses a **procedural beat bed** (no copyrighted audio).

## Play

- **Controls:** `← ↓ ↑ →` or `W A S D` (player / Vox side)
- **Menu:** arrows + Enter · **Esc** pause / back
- **Story** starts *Stayed Gone* · **Freeplay** picks songs · **Botplay** in Options

## Local dev

```bash
npm start
# → http://localhost:3000
```

Or open `public/index.html` via any static server (ES modules need HTTP).

## Deploy (Vercel + GitHub)

```bash
# push repo
gh repo create stayed-gone-fnf --public --source=. --remote=origin --push

# link & deploy
npx vercel login
npx vercel --prod
```

`vercel.json` serves the `public/` folder as a static site.

## Project layout

```
public/
  index.html
  css/style.css
  js/
    main.js      # screens / menus
    game.js      # rhythm engine + canvas
    audio.js     # Web Audio procedural track
    charts.js    # note charts
vercel.json
package.json
```

## Custom charts

Edit `public/js/charts.js`. Notes:

```js
{ time: 1000, lane: 0, side: "player" } // lane 0-3, side player|opponent
```

Optional: drop an `.mp3`/`.ogg` in `public/assets/` and wire it in `audio.js` (respect copyright).

## License

Fan project code: MIT. Characters/music not included under that license.
