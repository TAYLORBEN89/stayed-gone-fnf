/**
 * Second Dibs roster.
 * Koal is the first playable character.
 * moves sheet: diamond layout — left / up / right / down poses.
 */

/** FNF lane index → direction name */
export const LANE_TO_DIR = ["left", "down", "up", "right"];

/**
 * Crop rects for Koal_02.jpg (1792×1008), diamond sheet:
 *   top = up · bottom = down · left = left · right = right
 */
const KOAL_SHEET = {
  src: "assets/characters/koal/moves.jpg",
  width: 1792,
  height: 1008,
  frames: {
    // tuned for the diamond layout on black bg
    left: { sx: 20, sy: 160, sw: 520, sh: 680 },
    up: { sx: 600, sy: 10, sw: 580, sh: 500 },
    down: { sx: 600, sy: 500, sw: 580, sh: 500 },
    right: { sx: 1240, sy: 160, sw: 530, sh: 680 },
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
  // Placeholders until art is provided
  {
    id: "kain",
    name: "KAIN",
    role: "Coming soon",
    select: null,
    sheet: null,
    color: "#00e5ff",
    locked: true,
  },
  {
    id: "kross",
    name: "KROSS",
    role: "Coming soon",
    select: null,
    sheet: null,
    color: "#ff1a1a",
    locked: true,
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
