import { SONGS } from "./charts.js";
import { AudioEngine } from "./audio.js";
import { RhythmGame } from "./game.js";
import { CHARACTERS, getCharacter, preloadCharacter, LANE_TO_DIR } from "./characters.js";

const screens = {
  title: document.getElementById("screen-title"),
  chars: document.getElementById("screen-chars"),
  freeplay: document.getElementById("screen-freeplay"),
  options: document.getElementById("screen-options"),
  credits: document.getElementById("screen-credits"),
  game: document.getElementById("screen-game"),
  results: document.getElementById("screen-results"),
};

const MENU_SCREENS = new Set(["title", "chars", "freeplay", "options", "credits", "results"]);

const menuVideoWrap = document.getElementById("menu-video-wrap");
const menuVideo = document.getElementById("menu-video");

const audio = new AudioEngine();
const canvas = document.getElementById("game-canvas");
const game = new RhythmGame(canvas, audio);

const state = {
  screen: "title",
  menuIndex: 0,
  freeplayIndex: 0,
  charIndex: 0,
  selectedCharId: "koal",
  charAssetsCache: {},
  currentSong: SONGS[0],
  options: {
    speed: 2.2,
    offset: 0,
    volume: 0.7,
    downscroll: false,
    botplay: false,
  },
};

/** Mute + loop menu BG; play on menu screens, pause/hide in gameplay */
function setMenuVideoActive(active) {
  document.body.classList.toggle("menu-bg-on", active);
  menuVideoWrap.classList.toggle("hidden", !active);
  if (!menuVideo) return;
  menuVideo.muted = true;
  menuVideo.defaultMuted = true;
  menuVideo.volume = 0;
  menuVideo.loop = true;
  if (active) {
    const play = () => {
      menuVideo.play().catch(() => {});
    };
    play();
  } else {
    menuVideo.pause();
  }
}

function ensureMenuVideoUnlocked() {
  if (!menuVideo) return;
  menuVideo.muted = true;
  menuVideo.volume = 0;
  if (MENU_SCREENS.has(state.screen) && menuVideo.paused) {
    menuVideo.play().catch(() => {});
  }
}

function detectMobile() {
  const mobile =
    window.matchMedia("(max-width: 900px)").matches ||
    window.matchMedia("(pointer: coarse)").matches ||
    /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent);
  document.body.classList.toggle("is-mobile", mobile);
  return mobile;
}

function show(name) {
  Object.values(screens).forEach((el) => {
    if (el) el.classList.remove("active");
  });
  screens[name].classList.add("active");
  state.screen = name;
  setMenuVideoActive(MENU_SCREENS.has(name));
  detectMobile();
}

function loadSettings() {
  try {
    const raw = localStorage.getItem("second-dibs-opts") || localStorage.getItem("stayed-gone-opts");
    if (raw) Object.assign(state.options, JSON.parse(raw));
    const charId = localStorage.getItem("second-dibs-char");
    if (charId && getCharacter(charId) && !getCharacter(charId).locked) {
      state.selectedCharId = charId;
      state.charIndex = Math.max(
        0,
        CHARACTERS.findIndex((c) => c.id === charId)
      );
    }
  } catch (_) {}
  applyOptionsToUI();
}

function saveSettings() {
  localStorage.setItem("second-dibs-opts", JSON.stringify(state.options));
  localStorage.setItem("second-dibs-char", state.selectedCharId);
}

function applyOptionsToUI() {
  const o = state.options;
  document.getElementById("opt-speed").value = o.speed;
  document.getElementById("opt-speed-val").textContent = o.speed.toFixed(1);
  document.getElementById("opt-offset").value = o.offset;
  document.getElementById("opt-offset-val").textContent = String(o.offset);
  document.getElementById("opt-volume").value = o.volume;
  document.getElementById("opt-volume-val").textContent = Math.round(o.volume * 100) + "%";
  document.getElementById("opt-downscroll").checked = o.downscroll;
  document.getElementById("opt-botplay").checked = o.botplay;
  audio.setVolume(o.volume);
}

function wireOptions() {
  const bind = (id, key, parse, labelId, fmt) => {
    const el = document.getElementById(id);
    el.addEventListener("input", () => {
      state.options[key] = parse(el.value);
      if (labelId) document.getElementById(labelId).textContent = fmt(state.options[key]);
      if (key === "volume") audio.setVolume(state.options.volume);
      saveSettings();
    });
  };
  bind("opt-speed", "speed", parseFloat, "opt-speed-val", (v) => v.toFixed(1));
  bind("opt-offset", "offset", (v) => parseInt(v, 10), "opt-offset-val", String);
  bind("opt-volume", "volume", parseFloat, "opt-volume-val", (v) => Math.round(v * 100) + "%");
  document.getElementById("opt-downscroll").addEventListener("change", (e) => {
    state.options.downscroll = e.target.checked;
    saveSettings();
  });
  document.getElementById("opt-botplay").addEventListener("change", (e) => {
    state.options.botplay = e.target.checked;
    saveSettings();
  });
}

function buildFreeplay() {
  const list = document.getElementById("song-list");
  list.innerHTML = "";
  SONGS.forEach((song, i) => {
    const li = document.createElement("li");
    li.innerHTML = `<span>${song.name}</span><span class="diff">${song.bpm} BPM</span>`;
    if (i === state.freeplayIndex) li.classList.add("selected");
    li.addEventListener("click", () => {
      state.freeplayIndex = i;
      updateFreeplaySelection();
      openCharSelectThenPlay(SONGS[i]);
    });
    list.appendChild(li);
  });
}

function updateFreeplaySelection() {
  document.querySelectorAll("#song-list li").forEach((li, i) => {
    li.classList.toggle("selected", i === state.freeplayIndex);
  });
}

function updateTitleMenu() {
  const btns = [...document.querySelectorAll("#screen-title .menu-btn")];
  btns.forEach((b, i) => b.classList.toggle("selected", i === state.menuIndex));
}

function buildCharSelect() {
  const row = document.getElementById("char-row");
  row.innerHTML = "";
  CHARACTERS.forEach((char, i) => {
    const card = document.createElement("div");
    card.className = "char-card" + (char.locked ? " locked" : "");
    card.dataset.index = String(i);
    card.setAttribute("role", "option");
    if (char.select) {
      card.innerHTML = `
        <img src="${char.select}" alt="${char.name}" />
        <div class="char-name" style="color:${char.color}">${char.name}</div>
        <div class="char-role">${char.role}</div>
      `;
    } else {
      card.innerHTML = `
        <div class="char-placeholder">SOON</div>
        <div class="char-name" style="color:${char.color}">${char.name}</div>
        <div class="char-role">${char.role}</div>
      `;
    }
    if (!char.locked) {
      card.addEventListener("click", () => {
        state.charIndex = i;
        state.selectedCharId = char.id;
        updateCharSelect();
        saveSettings();
      });
    }
    row.appendChild(card);
  });
  updateCharSelect();
}

function updateCharSelect() {
  const char = CHARACTERS[state.charIndex] || CHARACTERS[0];
  if (!char.locked) state.selectedCharId = char.id;
  document.querySelectorAll(".char-card").forEach((c, i) => {
    c.classList.toggle("selected", i === state.charIndex);
  });
  const preview = document.getElementById("char-preview");
  const hint = document.getElementById("char-preview-hint");
  if (char.select) {
    preview.src = char.select;
    preview.style.display = "";
  } else {
    preview.removeAttribute("src");
    preview.style.display = "none";
  }
  hint.textContent = char.locked
    ? `${char.name} · locked (art coming)`
    : `${char.name} · press ← ↓ ↑ → to preview moves · Enter to play`;
  previewCharPose(null);
}

/** Preview UDLR pose on character select using sheet crops */
async function previewCharPose(dir) {
  const char = getCharacter(state.selectedCharId);
  const preview = document.getElementById("char-preview");
  if (!char || char.locked) return;

  if (!dir || !char.sheet) {
    if (char.select) preview.src = char.select;
    return;
  }

  let assets = state.charAssetsCache[char.id];
  if (!assets) {
    assets = await preloadCharacter(char);
    state.charAssetsCache[char.id] = assets;
  }
  if (!assets.sheetImg || !char.sheet.frames[dir]) {
    if (char.select) preview.src = char.select;
    return;
  }
  const fr = char.sheet.frames[dir];
  const c = document.createElement("canvas");
  c.width = fr.sw;
  c.height = fr.sh;
  const ctx = c.getContext("2d");
  ctx.drawImage(assets.sheetImg, fr.sx, fr.sy, fr.sw, fr.sh, 0, 0, fr.sw, fr.sh);
  preview.src = c.toDataURL("image/png");
}

function openCharSelectThenPlay(song) {
  state.pendingSong = song || SONGS[0];
  buildCharSelect();
  show("chars");
}

async function countdown() {
  const el = document.getElementById("countdown");
  const steps = ["3", "2", "1", "GO!"];
  for (const s of steps) {
    el.textContent = s;
    el.classList.remove("show");
    void el.offsetWidth;
    el.classList.add("show");
    await new Promise((r) => setTimeout(r, 600));
  }
  el.classList.remove("show");
  el.textContent = "";
}

async function startSong(song) {
  state.currentSong = song;
  const char = getCharacter(state.selectedCharId);
  // Always (re)preload so sheet/select images are complete before play
  const assets = await preloadCharacter(char);
  state.charAssetsCache[char.id] = assets;

  document.getElementById("hud-player-name").textContent = char.name;
  document.getElementById("hud-player-role").textContent = char.role || "You";

  show("game");
  detectMobile();
  document.getElementById("pause-overlay").classList.add("hidden");
  game.setOptions({
    speed: state.options.speed,
    offset: state.options.offset,
    downscroll: state.options.downscroll,
    botplay: state.options.botplay,
  });
  game.setCharacter(char, assets);
  game.load(song);
  game.onHud = (h) => {
    document.getElementById("score-line").textContent =
      `Score: ${h.score} · Combo: ${h.combo} · Misses: ${h.misses}`;
    document.getElementById("health-fill").style.width = h.health * 100 + "%";
    const j = document.getElementById("judgement");
    if (h.judgement) {
      j.textContent = h.judgement;
      j.className = h.judgementClass;
    }
  };
  game.onEnd = (result) => showResults(result);
  await audio.ensure();
  await countdown();
  await game.start();
}

function showResults(result) {
  show("results");
  document.getElementById("results-title").textContent = result.won
    ? "SECOND DIBS — YOU WIN"
    : "SIGNAL LOST";
  document.getElementById("results-body").innerHTML = `
    <div class="grade">${result.grade}</div>
    <div>Score: <strong>${result.score}</strong></div>
    <div>Accuracy: <strong>${result.accuracy}%</strong></div>
    <div>Max Combo: <strong>${result.maxCombo}</strong></div>
    <div>Misses: <strong>${result.misses}</strong></div>
    <div>SICK ${result.hits.sick} · GOOD ${result.hits.good} · BAD ${result.hits.bad}</div>
  `;
}

function pauseGame() {
  if (state.screen !== "game" || !game.running) return;
  game.pause();
  document.getElementById("pause-overlay").classList.remove("hidden");
}

async function resumeGame() {
  document.getElementById("pause-overlay").classList.add("hidden");
  await game.resume();
}

document.body.addEventListener("click", (e) => {
  ensureMenuVideoUnlocked();
  const btn = e.target.closest("[data-action]");
  if (!btn) return;
  handleAction(btn.dataset.action);
});

document.body.addEventListener("keydown", () => ensureMenuVideoUnlocked(), { once: false });

function wireMobileControls() {
  const root = document.getElementById("mobile-controls");
  if (!root) return;

  const bindPad = (btn) => {
    const lane = parseInt(btn.dataset.lane, 10);
    if (Number.isNaN(lane)) return;

    const down = (e) => {
      e.preventDefault();
      e.stopPropagation();
      btn.classList.add("active");
      ensureMenuVideoUnlocked();
      audio.ensure().catch(() => {});
      game.hitLane(lane);
    };
    const up = (e) => {
      e.preventDefault();
      e.stopPropagation();
      btn.classList.remove("active");
      game.releaseLane(lane);
    };

    // Pointer events cover finger + mouse
    btn.addEventListener("pointerdown", down);
    btn.addEventListener("pointerup", up);
    btn.addEventListener("pointerleave", up);
    btn.addEventListener("pointercancel", up);
    // Prevent context menu / scroll on long-press
    btn.addEventListener("contextmenu", (e) => e.preventDefault());
  };

  root.querySelectorAll(".touch-pad").forEach(bindPad);

  // Block multi-touch scrolling on the control bar
  root.addEventListener(
    "touchmove",
    (e) => {
      e.preventDefault();
    },
    { passive: false }
  );
}

function handleAction(action) {
  switch (action) {
    case "pause":
      pauseGame();
      break;
    case "play":
      openCharSelectThenPlay(SONGS[0]);
      break;
    case "chars":
      state.pendingSong = null;
      buildCharSelect();
      show("chars");
      break;
    case "confirm-char": {
      const char = CHARACTERS[state.charIndex];
      if (char?.locked) return;
      state.selectedCharId = char.id;
      saveSettings();
      startSong(state.pendingSong || SONGS[0]);
      break;
    }
    case "freeplay":
      buildFreeplay();
      show("freeplay");
      break;
    case "options":
      show("options");
      break;
    case "credits":
      show("credits");
      break;
    case "back":
    case "menu":
      game.stop();
      show("title");
      break;
    case "resume":
      resumeGame();
      break;
    case "retry":
      game.stop();
      startSong(state.currentSong);
      break;
    case "quit":
      game.stop();
      document.getElementById("pause-overlay").classList.add("hidden");
      show("title");
      break;
  }
}

const KEY_TO_DIR = {
  ArrowLeft: "left",
  ArrowDown: "down",
  ArrowUp: "up",
  ArrowRight: "right",
  a: "left",
  s: "down",
  w: "up",
  d: "right",
  A: "left",
  S: "down",
  W: "up",
  D: "right",
};

window.addEventListener("keydown", (e) => {
  if (state.screen === "title") {
    const btns = [...document.querySelectorAll("#screen-title .menu-btn")];
    if (e.key === "ArrowDown" || e.key === "s") {
      state.menuIndex = (state.menuIndex + 1) % btns.length;
      updateTitleMenu();
    } else if (e.key === "ArrowUp" || e.key === "w") {
      state.menuIndex = (state.menuIndex - 1 + btns.length) % btns.length;
      updateTitleMenu();
    } else if (e.key === "Enter") {
      handleAction(btns[state.menuIndex].dataset.action);
    }
  } else if (state.screen === "chars") {
    // Arrow / WASD → swap preview pose (UDLR from moves sheet)
    const dir = KEY_TO_DIR[e.key];
    if (dir) {
      previewCharPose(dir);
      e.preventDefault();
    } else if (e.key === "Enter") {
      handleAction("confirm-char");
    } else if (e.key === "Escape") {
      show("title");
    } else if (e.key === "Tab") {
      // Cycle unlocked characters
      e.preventDefault();
      const unlocked = CHARACTERS.map((c, i) => ({ c, i })).filter((x) => !x.c.locked);
      const idx = unlocked.findIndex((x) => x.i === state.charIndex);
      const next = unlocked[(idx + 1) % unlocked.length];
      if (next) {
        state.charIndex = next.i;
        updateCharSelect();
        saveSettings();
      }
    }
  } else if (state.screen === "freeplay") {
    if (e.key === "ArrowDown" || e.key === "s") {
      state.freeplayIndex = (state.freeplayIndex + 1) % SONGS.length;
      updateFreeplaySelection();
    } else if (e.key === "ArrowUp" || e.key === "w") {
      state.freeplayIndex = (state.freeplayIndex - 1 + SONGS.length) % SONGS.length;
      updateFreeplaySelection();
    } else if (e.key === "Enter") {
      openCharSelectThenPlay(SONGS[state.freeplayIndex]);
    } else if (e.key === "Escape") {
      show("title");
    }
  } else if (state.screen === "options" || state.screen === "credits") {
    if (e.key === "Escape") show("title");
  } else if (state.screen === "game") {
    if (e.key === "Escape") {
      if (document.getElementById("pause-overlay").classList.contains("hidden")) {
        pauseGame();
      } else {
        resumeGame();
      }
    }
  } else if (state.screen === "results") {
    if (e.key === "Enter") handleAction("retry");
    if (e.key === "Escape") handleAction("menu");
  }
});

// Quiet unused
void LANE_TO_DIR;
void KEY_TO_DIR;

loadSettings();
wireOptions();
wireMobileControls();
updateTitleMenu();
buildFreeplay();
buildCharSelect();
detectMobile();
window.addEventListener("resize", detectMobile);
window.addEventListener("orientationchange", () => {
  setTimeout(detectMobile, 150);
});

// Preload full roster
["koal", "kross", "kain"].forEach((id) => {
  preloadCharacter(getCharacter(id)).then((a) => {
    state.charAssetsCache[id] = a;
  });
});

if (menuVideo) {
  menuVideo.muted = true;
  menuVideo.defaultMuted = true;
  menuVideo.setAttribute("muted", "");
  menuVideo.playsInline = true;
  menuVideo.setAttribute("playsinline", "");
  menuVideo.setAttribute("webkit-playsinline", "");
  menuVideo.volume = 0;
  menuVideo.loop = true;
  menuVideo.addEventListener("loadeddata", () => {
    menuVideo.muted = true;
    menuVideo.volume = 0;
  });
}
setMenuVideoActive(true);

// First tap unlocks audio (iOS) + menu video
document.body.addEventListener(
  "touchstart",
  () => {
    ensureMenuVideoUnlocked();
    audio.ensure().catch(() => {});
  },
  { once: true, passive: true }
);
