# Stayed Gone — Roblox (Rojo)

Sync Luau source from this folder into **Roblox Studio** with [Rojo](https://rojo.space/).

## One-time setup

1. **Rojo CLI** — already installed (`rojo --version` → 7.6.1)
2. **Rojo plugin** — `Rojo.rbxm` was placed in  
   `%LOCALAPPDATA%\Roblox\Plugins\`  
   Restart Studio if it was already open.
3. In Studio: open the **Plugins** tab → **Rojo** → **Connect** (default `localhost:34872`)

## Daily workflow

```powershell
cd roblox
rojo serve
```

Then in Studio: **Plugins → Rojo → Connect**.

| Edit on disk | Appears in Studio |
|--------------|-------------------|
| `src/shared/` | `ReplicatedStorage.Shared` |
| `src/server/` | `ServerScriptService.Server` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |

## Build a place file (optional)

```powershell
rojo build -o StayedGone.rbxlx
```

Open the `.rbxlx` in Studio, then Connect for live sync.

## Notes

- Keep Studio open while `rojo serve` is running.
- If Connect fails: confirm serve is running, port `34872`, and the plugin is enabled.
- This Roblox tree is separate from the web FNF game in `/public`.
