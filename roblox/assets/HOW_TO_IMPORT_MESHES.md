# Import FBX into Roblox Studio (2025/2026 — correct steps)

Studio changed. **Do not look for “Bulk Import” only.** Use the **3D Importer**.

Your FBX files are here:

`C:\Users\btayl\vox vr alistor\roblox\assets\export`

(Fixed FBX files have real geometry — e.g. Penny is ~39 KB, not 4 KB.)

---

## Method 1 — File → Importer (most reliable)

1. Open **Roblox Studio** with your Cash Empire place (Rojo connected is fine).
2. Top menu: **File → Import 3D…**  
   (Some builds: **File → Importer…** or **Avatar** tab → **Import 3D**)
3. Browse to:  
   `C:\Users\btayl\vox vr alistor\roblox\assets\export`
4. Select **one** `.fbx` first (e.g. `Penny.fbx`) → Open.
5. Preview window appears → click **Import**.
6. A **Model** with a **MeshPart** appears in **Workspace**.
7. Click the MeshPart → **Properties** panel → find **MeshId**.
8. Copy the full value: `rbxassetid://##########`

Repeat for other FBX files (or multi-select if the importer allows a queue).

---

## Method 2 — Asset Manager Import

1. **Window** menu (or **Home**) → **Asset Manager**
2. Click **Import** (not the old “Bulk Import” if it’s missing — that routes to the new Importer now)
3. Select FBX files from the export folder
4. After import, open **Meshes** / **Inventory**
5. Insert mesh → select → copy **MeshId** from Properties

---

## Method 3 — Drag and drop

1. Open File Explorer to `roblox\assets\export`
2. Drag `Penny.fbx` into the Studio **3D viewport**
3. If the Importer opens, hit **Import**

---

## Put IDs in the game

### Easiest: paste here in chat
```
penny = rbxassetid://1234567890
dragon_egg = rbxassetid://0987654321
```
I’ll edit `MeshAssets.luau` for you.

### Or edit yourself
File: `roblox\src\shared\MeshAssets.luau`

```lua
penny = { meshId = "rbxassetid://1234567890", size = Vector3.new(2.2, 0.45, 2.2) },
```

Save → Rojo sync → Stop → Play.

---

## Studio plugin helper

After meshes are in Workspace:

1. Restart Studio once (loads plugin)
2. **Plugins** tab → **Print MeshIds**
3. Select MeshParts → click button
4. Copy Output text → send to me or paste into `MeshAssets.luau`

---

## Common problems

| Problem | Fix |
|--------|-----|
| No “Bulk Import” button | Use **File → Import 3D** instead |
| Import fails / empty | Use the **new** FBX (re-exported). Penny should be ~30–40 KB |
| MeshId blank | Select the **MeshPart** inside the Model, not the Model folder |
| Can’t find export folder | Path above, or Explorer should already open there |
| Place not published | Publish once to Roblox so uploads are allowed |

---

## Mapping

| FBX | MeshAssets key |
|-----|----------------|
| Penny.fbx | penny |
| DollarBill.fbx | dollar |
| FiveSpot.fbx | fiver |
| TwentyStack.fbx | twenty |
| CoinJar.fbx | coin_jar |
| ZombieTooth.fbx | zombie_tooth |
| ChuckEToken.fbx | chuck_e |
| MonopolyPiece.fbx | monopoly |
| PrizeTicket.fbx | ticket |
| GoldDoubloon.fbx | doubloon |
| BlackPearl.fbx | pearl |
| RomanDenarius.fbx | denarius |
| GoldenLaurel.fbx | laurel |
| PlatinumCoin.fbx | platinum_coin |
| PlatinumBar.fbx | platinum_bar |
| VaultKeycard.fbx | vault_key |
| Bitcoin.fbx | bitcoin |
| Ethereum.fbx | ethereum |
| JPEGDuck.fbx | nft_duck |
| StarFragment.fbx | star_fragment |
| NebulaShard.fbx | nebula_shard |
| DragonEgg.fbx | dragon_egg |
| InfinityCent.fbx | infinity_cent |
