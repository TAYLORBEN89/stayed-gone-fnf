/**
 * Second Dibs roster — Koal, Kross, Kain all playable.
 */

/** FNF lane index → direction name */
export const LANE_TO_DIR = ["left", "down", "up", "right"];

/**
 * Koal_02.jpg (1792×1008) — diamond sheet:
 *   top = up · bottom = down · left = left · right = right
 */
const KOAL_SHEET = {
  src: "assets/characters/koal/moves.jpg",
  width: 1792,
  height: 1008,
  frames: {
    left: { sx: 20, sy: 160, sw: 520, sh: 680 },
    up: { sx: 600, sy: 10, sw: 580, sh: 500 },
    down: { sx: 600, sy: 500, sw: 580, sh: 500 },
    right: { sx: 1240, sy: 160, sw: 530, sh: 680 },
  },
};

/**
 * Kross_02.jpg (1200×1600) — 2×2 grid:
 *   TL = left · TR = right · BL = down · BR = up
 */
const KROSS_SHEET = {
  src: "assets/characters/kross/moves.jpg",
  width: 1200,
  height: 1600,
  frames: {
    left: { sx: 20, sy: 20, sw: 560, sh: 760 },
    right: { sx: 620, sy: 20, sw: 560, sh: 760 },
    down: { sx: 20, sy: 820, sw: 560, sh: 760 },
    up: { sx: 620, sy: 820, sw: 560, sh: 760 },
  },
};

/**
 * Kain_02.jpg (1328×1488) — 2×2 grid:
 *   TL = up · TR = down · BL = left · BR = right
 */
const KAIN_SHEET = {
  src: "assets/characters/kain/moves.jpg",
  width: 1328,
  height: 1488,
  frames: {
    up: { sx: 20, sy: 20, sw: 640, sh: 720 },
    down: { sx: 680, sy: 20, sw: 640, sh: 720 },
    left: { sx: 20, sy: 760, sw: 640, sh: 720 },
    right: { sx: 680, sy: 760, sw: 640, sh: 720 },
  },
};

export const CHARACTERS = [
  {
    id: "koal",
    name: "KOAL",
    role: "First dibs",
    select: "assets/characters/koal/select.jpg",
    sheet: KOAL_SHEET,
    color: "#ff6b35",
  },
  {
    id: "kross",
    name: "KROSS",
    role: "Point & laugh",
    select: "assets/characters/kross/select.jpg",
    sheet: KROSS_SHEET,
    color: "#ffcc33",
  },
  {
    id: "kain",
    name: "KAIN",
    role: "Stevie Ray vibes",
    select: "assets/characters/kain/select.jpg",
    sheet: KAIN_SHEET,
    color: "#00e5ff",
  },
];

export function getCharacter(id) {
  return CHARACTERS.find((c) => c.id === id) || CHARACTERS[0];
}

/** Preload select + sheet images for a character */
export function preloadCharacter(char) {
  return new Promise((resolve) => {
    const out = { selectImg: null, sheetImg: null };
    let pending = 0;
    const done = () => {
      pending -= 1;
      if (pending <= 0) resolve(out);
    };
    if (char.select) {
      pending += 1;
      const img = new Image();
      img.onload = () => {
        out.selectImg = img;
        done();
      };
      img.onerror = done;
      img.src = char.select;
    }
    if (char.sheet?.src) {
      pending += 1;
      const img = new Image();
      img.onload = () => {
        out.sheetImg = img;
        done();
      };
      img.onerror = done;
      img.src = char.sheet.src;
    }
    if (pending === 0) resolve(out);
  });
}
