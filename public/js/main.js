import { SONGS } from "./charts.js";
import { AudioEngine } from "./audio.js";
import { RhythmGame } from "./game.js";

const screens = {
  title: document.getElementById("screen-title"),
  freeplay: document.getElementById("screen-freeplay"),
  options: document.getElementById("screen-options"),
  credits: document.getElementById("screen-credits"),
  game: document.getElementById("screen-game"),
  results: document.getElementById("screen-results"),
};

const MENU_SCREENS = new Set(["title", "freeplay", "options", "credits", "results"]);

const menuVideoWrap = document.getElementById("menu-video-wrap");
const menuVideo = document.getElementById("menu-video");

const audio = new AudioEngine();
const canvas = document.getElementById("game-canvas");
const game = new RhythmGame(canvas, audio);

const state = {
  screen: "title",
  menuIndex: 0,
  freeplayIndex: 0,
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
      menuVideo.play().catch(() => {
        /* autoplay blocked until gesture — retry on first click */
      });
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

function show(name) {
  Object.values(screens).forEach((el) => el.classList.remove("active"));
  screens[name].classList.add("active");
  state.screen = name;
  setMenuVideoActive(MENU_SCREENS.has(name));
}

function loadSettings() {
  try {
    const raw = localStorage.getItem("stayed-gone-opts");
    if (raw) Object.assign(state.options, JSON.parse(raw));
  } catch (_) {}
  applyOptionsToUI();
}

function saveSettings() {
  localStorage.setItem("stayed-gone-opts", JSON.stringify(state.options));
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
      startSong(SONGS[i]);
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
  show("game");
  document.getElementById("pause-overlay").classList.add("hidden");
  game.setOptions({
    speed: state.options.speed,
    offset: state.options.offset,
    downscroll: state.options.downscroll,
    botplay: state.options.botplay,
  });
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
    ? "YOU STAYED GONE"
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

// Clicks + unlock muted autoplay after first gesture if needed
document.body.addEventListener("click", (e) => {
  ensureMenuVideoUnlocked();
  const btn = e.target.closest("[data-action]");
  if (!btn) return;
  const action = btn.dataset.action;
  handleAction(action);
});

document.body.addEventListener("keydown", () => ensureMenuVideoUnlocked(), { once: false });

function handleAction(action) {
  switch (action) {
    case "play":
      startSong(SONGS[0]);
      break;
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

// Keyboard navigation
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
  } else if (state.screen === "freeplay") {
    if (e.key === "ArrowDown" || e.key === "s") {
      state.freeplayIndex = (state.freeplayIndex + 1) % SONGS.length;
      updateFreeplaySelection();
    } else if (e.key === "ArrowUp" || e.key === "w") {
      state.freeplayIndex = (state.freeplayIndex - 1 + SONGS.length) % SONGS.length;
      updateFreeplaySelection();
    } else if (e.key === "Enter") {
      startSong(SONGS[state.freeplayIndex]);
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

loadSettings();
wireOptions();
updateTitleMenu();
buildFreeplay();

// Force mute + start looping menu BG on load
if (menuVideo) {
  menuVideo.muted = true;
  menuVideo.defaultMuted = true;
  menuVideo.setAttribute("muted", "");
  menuVideo.volume = 0;
  menuVideo.loop = true;
  // Some browsers still emit audio unless we hard-mute on load/metadata
  menuVideo.addEventListener("loadeddata", () => {
    menuVideo.muted = true;
    menuVideo.volume = 0;
  });
}
setMenuVideoActive(true);
