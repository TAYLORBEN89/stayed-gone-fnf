# Blender ↔ Roblox pipeline (Cash Empire)

Two ways to get custom items into the game:

| Path | Best for |
|------|----------|
| **A. Official Roblox Blender plugin** | Upload meshes from Blender → your Roblox inventory as packages |
| **B. FBX export → Studio 3D Importer** | Full control, textures, bulk import into the published place |

---

## Folders in this repo

```
roblox/assets/
  blender/     ← save .blend project files here
  export/      ← FBX / OBJ exports go here
  plugins/     ← Roblox Blender plugin .zip
```

---

## One-time setup

### 1. Blender
Install from winget / blender.org (3.2+ required for the Roblox plugin).

### 2. Install “Upload to Roblox” addon
1. Open Blender  
2. **Edit → Preferences → Add-ons**  
3. **⌄ → Install from Disk…**  
4. Pick the zip in `assets/plugins/` (do **not** unzip)  
5. Search **Roblox** → enable **Upload to Roblox**  
6. Press **N** in 3D view → **Roblox** tab → **Install Dependencies**  
7. **Restart Blender**  
8. **Roblox tab → Log in** (browser OAuth) → pick your account/group  

### 3. Roblox Studio
- Open **Cash Empire** (published place or Rojo)  
- **View → Asset Manager** for bulk FBX import  
- Or **Toolbox → Inventory → My Packages** for plugin uploads  

---

## Path A — Upload from Blender (fast)

1. Model in Blender (keep under Roblox mesh limits; prefer low-poly for props)  
2. Select mesh(es) or a **Collection** (collection = one package)  
3. **N → Roblox → Upload**  
4. In Studio: **Toolbox → Inventory → My Packages** → insert  
5. Place in workspace / turn into Tool / MeshPart  
6. **Publish** the place so live players see it  

Package IDs stick on the object as a custom property so re-upload **updates** the package.

---

## Path B — FBX export (Studio import)

### Export settings (Blender → File → Export → FBX)

| Setting | Value |
|---------|--------|
| Selected Objects | ✅ |
| Path Mode | **Copy** + embed textures if needed |
| Apply Scalings | **FBX Unit Scale** |
| Forward | **-Z Forward** |
| Up | **Y Up** |
| Apply Transform | ✅ (or Ctrl+A Apply All Transforms first) |
| Mesh → Smoothing | Face / Normals |
| Bake Animation | Off for static props |

Save to: `roblox/assets/export/YourItem.fbx`

### Import in Studio
1. **View → Asset Manager → Bulk Import** (or 3D Importer)  
2. Select the FBX from `assets/export/`  
3. Fix scale if needed (Roblox: 1 stud ≈ 0.28m; often scale mesh ×0.01 or use unit scale)  
4. Insert MeshPart into the place  
5. **Publish**  

### Quick prep checklist in Blender
- [ ] Origin at bottom center (`Object → Set Origin → Origin to Geometry` then move)  
- [ ] **Ctrl+A → All Transforms**  
- [ ] Recalculate normals (**Shift+N**)  
- [ ] UV unwrap if textured  
- [ ] Join objects if you want one mesh (`Ctrl+J`)  
- [ ] Target under **10k triangles** for simple props (lower = better)  

---

## Cash Empire item ideas to model

| Item | Use in game |
|------|-------------|
| Coin / bar / egg meshes | Replace neon ball collectibles |
| Zombie body | Replace block zombie |
| Pet models | Piggy, Doge, Dragon |
| Shop / vault building kits | Replace placeholder bricks |
| Stack of cash prop | Carry visual |

After MeshPart IDs exist, we can plug `MeshId` / `TextureID` into Luau spawners.

---

## Scripts

- `export_roblox_fbx.py` — Blender text/script to batch-export selected to `assets/export/`  
- `install_roblox_addon.ps1` — opens Blender prefs path + plugin folder  

---

## Limits & notes

- Free accounts have upload quotas; publish under your group for team assets  
- Live game only updates after **Publish to Roblox**  
- Rojo does **not** sync binary mesh assets well — keep FBX in `assets/export/` and reference MeshIds in code  
