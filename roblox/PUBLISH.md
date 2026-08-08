# Go Live — Cash Empire (multiplayer + Robux)

Other players **cannot** join a Rojo Studio playtest. You must **publish** the place as a Roblox experience.

---

## Part A — Publish so others can play

### 1. Open the place in Studio
- Rojo **Connect**, or open `CashEmpire.rbxlx`
- Press **Play** once to confirm it works

### 2. Publish
1. **File → Publish to Roblox** (or **Save to Roblox** first)
2. Create a new experience: name it **Cash Empire**
3. Set **Genre** (e.g. Simulation / Adventure)
4. Click **Create** / **Publish**

### 3. Make it public
1. [Creator Dashboard](https://create.roblox.com/dashboard/creations) → your experience  
2. **Audience** / **Access** → **Public** (not Private)  
3. Enable:
   - **Allow copying** = Off (recommended)
   - **Friends only** = Off for public play

### 4. Recommended settings
**Game Settings** (Home tab in Studio) or Dashboard:

| Setting | Value |
|--------|--------|
| Max players | 20–40 |
| Studio Access to API Services | **On** (DataStores) |
| Allow HTTP requests | On if you need external APIs later |
| Paid access | Off (free to play + Robux shop) |

### 5. Share the link
After publish, open the game page → copy URL:

`https://www.roblox.com/games/YOUR_PLACE_ID/...`

Friends open that link → **Play**.

### 6. Keep updating after Rojo changes
1. Edit code via Rojo  
2. **File → Publish to Roblox** again (overwrite)  
3. Live servers pick up new versions as they restart  

---

## Part B — Robux shop (game passes + products)

### 1. Create Game Passes
Dashboard → your experience → **Monetization → Passes** → **Create a Pass**

Create these (names can match):

| Pass | Suggested price |
|------|-----------------|
| VIP | 199 R$ |
| 2x Cash | 399 R$ |
| Auto Collector | 149 R$ |
| Tycoon Starter | 99 R$ |

Copy each **Pass ID** (number).

### 2. Create Developer Products
Dashboard → **Monetization → Developer Products** → Create:

| Product | Suggested price |
|---------|-----------------|
| Cash Pack S (+2500) | 49 R$ |
| Cash Pack M (+15000) | 149 R$ |
| Cash Pack L (+75000) | 399 R$ |
| Instant Rebirth Token | 99 R$ |

Copy each **Product ID**.

### 3. Paste IDs into the game
Edit `src/shared/Config.luau` → `Config.Monetization`:

```lua
id = 123456789,  -- your real ID, not 0
```

For every game pass and product.

### 4. Publish again
Rojo sync → **Publish to Roblox**.

### 5. Test purchases
- Studio: **Game Settings → Security → Enable Studio Access to API Services**
- Use **Test → Play** or a private server
- Roblox also has a **test purchase** mode in Studio for products

---

## Part C — What players see in-game

- **💎 ROBUX** button (top HUD) opens the paid shop  
- Game passes = permanent  
- Cash packs = spend Robux anytime  
- **You** earn Robux via Roblox DevEx after meeting their thresholds  

---

## Checklist

- [ ] Place published & **Public**
- [ ] API Services enabled (saves)
- [ ] Game passes created
- [ ] Developer products created
- [ ] IDs pasted into `Config.Monetization`
- [ ] Re-published
- [ ] Friend can join from game link
- [ ] Purchase prompt appears when clicking VIP

---

## Notes

- **Rojo Connect is only for development.** Live players use the published place.
- Never put real Robux IDs in a public GitHub repo if you care about scrapers (optional private repo).
- Comply with Roblox ToS: no pay-to-win abuse that breaks rules; label purchases clearly.
