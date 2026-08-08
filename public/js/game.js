import { LANE_TO_DIR } from "./characters.js";

const LANE_COLORS = ["#c44dff", "#4d9fff", "#4dff7a", "#ff4d6a"];
const LANE_KEYS = {
  // Player lanes 0-3  (left, down, up, right)
  ArrowLeft: 0,
  ArrowDown: 1,
  ArrowUp: 2,
  ArrowRight: 3,
  a: 0,
  s: 1,
  w: 2,
  d: 3,
  A: 0,
  S: 1,
  W: 2,
  D: 3,
};

const WINDOWS = {
  sick: 45,
  good: 90,
  bad: 135,
  shit: 166,
};

export class RhythmGame {
  constructor(canvas, audio, options = {}) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.audio = audio;
    this.chart = null;
    this.options = {
      speed: 1.0,
      offset: 0,
      downscroll: false,
      botplay: false,
      ...options,
    };

    this.running = false;
    this.paused = false;
    this.notes = [];
    this.held = [false, false, false, false];
    this.flash = [0, 0, 0, 0];
    this.health = 0.5;
    this.score = 0;
    this.combo = 0;
    this.maxCombo = 0;
    this.misses = 0;
    this.hits = { sick: 0, good: 0, bad: 0, shit: 0 };
    this.totalPlayerNotes = 0;
    this.judgement = "";
    this.judgementClass = "";
    this.judgementTimer = 0;
    this.songTime = 0;
    this.raf = null;
    this.onEnd = null;
    this.onHud = null;
    this.onPose = null; // (dirName: string|null) => void — for character sprite
    this.character = null;
    this.charAssets = null;
    this.poseDir = null; // "left"|"down"|"up"|"right"|null idle
    this.poseTimer = 0;
    this._charCanvas = document.getElementById("game-char-player");
    this._charCtx = this._charCanvas ? this._charCanvas.getContext("2d") : null;
    this._boundKeyDown = (e) => this._keyDown(e);
    this._boundKeyUp = (e) => this._keyUp(e);
    this._resize();
    window.addEventListener("resize", () => this._resize());
  }

  isMobileLayout() {
    return (
      window.matchMedia("(max-width: 900px)").matches ||
      window.matchMedia("(pointer: coarse)").matches ||
      document.body.classList.contains("is-mobile")
    );
  }

  setCharacter(char, assets) {
    this.character = char;
    this.charAssets = assets || null;
    this.poseDir = null;
    this._drawCharacterPose(null);
  }

  _resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const w = window.innerWidth;
    const h = window.innerHeight;
    this.canvas.width = w * dpr;
    this.canvas.height = h * dpr;
    this.canvas.style.width = w + "px";
    this.canvas.style.height = h + "px";
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    this.w = w;
    this.h = h;
  }

  load(chart) {
    this.chart = chart;
    this.notes = chart.notes.map((n) => ({
      ...n,
      hit: false,
      missed: false,
      judged: false,
    }));
    this.totalPlayerNotes = this.notes.filter((n) => n.side === "player").length;
    this.health = 0.5;
    this.score = 0;
    this.combo = 0;
    this.maxCombo = 0;
    this.misses = 0;
    this.hits = { sick: 0, good: 0, bad: 0, shit: 0 };
    this.songTime = 0;
    this.judgement = "";
  }

  setOptions(opts) {
    Object.assign(this.options, opts);
  }

  async start() {
    this.running = true;
    this.paused = false;
    window.addEventListener("keydown", this._boundKeyDown);
    window.addEventListener("keyup", this._boundKeyUp);
    this._drawCharacterPose(null);
    await this.audio.start(this.chart.bpm);
    this._loop();
  }

  /** Public: hit a lane from keyboard or touch (0–3) */
  hitLane(lane) {
    if (!this.running || this.paused || lane < 0 || lane > 3) return;
    this.held[lane] = true;
    this.flash[lane] = 1;
    this._setPose(LANE_TO_DIR[lane]);
    if (!this.options.botplay) this._tryHit(lane);
  }

  releaseLane(lane) {
    if (lane < 0 || lane > 3) return;
    this.held[lane] = false;
    if (!this.held.some(Boolean)) {
      this.poseTimer = 0.12;
    }
  }

  pause() {
    if (!this.running) return;
    this.paused = true;
    this.audio.stop();
    this._pauseAt = this.songTime;
  }

  async resume() {
    if (!this.running || !this.paused) return;
    this.paused = false;
    await this.audio.start(this.chart.bpm);
    // Re-align: audio restarts from 0; offset by previous pause point via fake start
    this._resumeOffset = this._pauseAt || 0;
    this.audio.startTime = this.audio.ctx.currentTime - this._resumeOffset / 1000;
    this._loop();
  }

  stop() {
    this.running = false;
    this.paused = false;
    this.audio.stop();
    window.removeEventListener("keydown", this._boundKeyDown);
    window.removeEventListener("keyup", this._boundKeyUp);
    if (this.raf) cancelAnimationFrame(this.raf);
  }

  _keyDown(e) {
    if (e.repeat || this.paused || !this.running) return;
    if (e.key === "Escape") return;
    const lane = LANE_KEYS[e.key];
    if (lane === undefined) return;
    e.preventDefault();
    this.hitLane(lane);
  }

  _keyUp(e) {
    const lane = LANE_KEYS[e.key];
    if (lane === undefined) return;
    this.releaseLane(lane);
  }

  _setPose(dir) {
    this.poseDir = dir;
    this.poseTimer = 0.35;
    this._drawCharacterPose(dir);
    if (this.onPose) this.onPose(dir);
  }

  _drawCharacterPose(dir) {
    // Keep offscreen canvas in sync (optional layer); main draw uses _paintCharacter
    const canvas = this._charCanvas;
    const ctx = this._charCtx;
    if (!canvas || !ctx) return;
    const w = canvas.width;
    const h = canvas.height;
    ctx.clearRect(0, 0, w, h);
    this._paintCharacter(ctx, w, h, dir, 1);
  }

  /**
   * Draw selected character (idle select art or UDLR sheet frame).
   * Used both on the overlay canvas and the main game canvas (behind notes).
   */
  _paintCharacter(ctx, boxW, boxH, dir, alpha = 1) {
    const assets = this.charAssets;
    const char = this.character;
    if (!char || !assets || !ctx) return;

    ctx.save();
    ctx.globalAlpha = alpha;

    let drew = false;
    if (dir && assets.sheetImg?.complete && char.sheet?.frames?.[dir]) {
      const fr = char.sheet.frames[dir];
      const img = assets.sheetImg;
      if (img.naturalWidth > 0) {
        const scale = Math.min(boxW / fr.sw, boxH / fr.sh) * 0.95;
        const dw = fr.sw * scale;
        const dh = fr.sh * scale;
        const dx = (boxW - dw) / 2;
        const dy = boxH - dh;
        try {
          ctx.drawImage(img, fr.sx, fr.sy, fr.sw, fr.sh, dx, dy, dw, dh);
          drew = true;
        } catch (_) {}
      }
    }

    if (!drew && assets.selectImg?.complete && assets.selectImg.naturalWidth > 0) {
      const img = assets.selectImg;
      const scale = Math.min(boxW / img.naturalWidth, boxH / img.naturalHeight) * 0.95;
      const dw = img.naturalWidth * scale;
      const dh = img.naturalHeight * scale;
      const dx = (boxW - dw) / 2;
      const dy = boxH - dh;
      ctx.drawImage(img, dx, dy, dw, dh);
      drew = true;
    }

    // Fallback if images not ready yet
    if (!drew && char.name) {
      ctx.fillStyle = char.color || "#00e5ff";
      ctx.font = `bold ${Math.min(boxW, boxH) * 0.12}px sans-serif`;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(char.name, boxW / 2, boxH * 0.55);
    }
    ctx.restore();
  }

  _tryHit(lane) {
    const t = this.songTime + this.options.offset;
    let best = null;
    let bestDist = Infinity;
    for (const n of this.notes) {
      if (n.side !== "player" || n.hit || n.missed || n.lane !== lane) continue;
      const dist = Math.abs(n.time - t);
      if (dist < bestDist && dist <= WINDOWS.shit) {
        bestDist = dist;
        best = n;
      }
    }
    if (!best) return;
    best.hit = true;
    best.judged = true;
    let j = "shit";
    if (bestDist <= WINDOWS.sick) j = "sick";
    else if (bestDist <= WINDOWS.good) j = "good";
    else if (bestDist <= WINDOWS.bad) j = "bad";
    this._registerHit(j);
  }

  _registerHit(j) {
    this.hits[j]++;
    const scores = { sick: 350, good: 200, bad: 100, shit: 50 };
    this.score += scores[j] + Math.min(this.combo, 50) * 2;
    this.combo++;
    if (this.combo > this.maxCombo) this.maxCombo = this.combo;
    const heal = { sick: 0.02, good: 0.012, bad: 0.004, shit: -0.005 };
    this.health = Math.min(1, Math.max(0, this.health + heal[j]));
    this.judgement = j.toUpperCase();
    this.judgementClass = j;
    this.judgementTimer = 0.5;
    this.audio.hit(j);
    // Keep pose on successful hits from botplay too
    this._emitHud();
  }

  _registerMiss(n) {
    if (n) {
      n.missed = true;
      n.judged = true;
    }
    this.misses++;
    this.combo = 0;
    this.health = Math.max(0, this.health - 0.045);
    this.judgement = "MISS";
    this.judgementClass = "miss";
    this.judgementTimer = 0.5;
    this.audio.hit("miss");
    this._emitHud();
    if (this.health <= 0) this._finish(false);
  }

  _emitHud() {
    if (this.onHud) {
      this.onHud({
        score: this.score,
        combo: this.combo,
        misses: this.misses,
        health: this.health,
        judgement: this.judgement,
        judgementClass: this.judgementClass,
      });
    }
  }

  _loop = () => {
    if (!this.running || this.paused) return;
    this.songTime = this.audio.now();
    this._update();
    this._draw();
    if (this.songTime >= this.chart.duration) {
      this._finish(true);
      return;
    }
    this.raf = requestAnimationFrame(this._loop);
  };

  _update() {
    const t = this.songTime + this.options.offset;
    // Pose hold timer → idle
    if (this.poseTimer > 0) {
      this.poseTimer -= 1 / 60;
      if (this.poseTimer <= 0 && !this.held.some(Boolean)) {
        this.poseDir = null;
        this._drawCharacterPose(null);
      }
    }
    const speed = this.options.speed;

    // Botplay
    if (this.options.botplay) {
      for (const n of this.notes) {
        if (n.side === "player" && !n.hit && !n.missed && t >= n.time) {
          n.hit = true;
          n.judged = true;
          this.flash[n.lane] = 1;
          this._setPose(LANE_TO_DIR[n.lane]);
          this._registerHit("sick");
        }
      }
    }

    // Miss window
    for (const n of this.notes) {
      if (n.side === "player" && !n.hit && !n.missed && t - n.time > WINDOWS.shit) {
        this._registerMiss(n);
      }
      // Opponent auto "hit" visual
      if (n.side === "opponent" && !n.hit && t >= n.time) {
        n.hit = true;
      }
    }

    for (let i = 0; i < 4; i++) {
      this.flash[i] = Math.max(0, this.flash[i] - 0.08);
    }
    if (this.judgementTimer > 0) this.judgementTimer -= 1 / 60;

    // scroll speed unused var quiet
    void speed;
  }

  _finish(won) {
    this.stop();
    const acc = this._accuracy();
    if (this.onEnd) {
      this.onEnd({
        won: won && this.health > 0,
        score: this.score,
        maxCombo: this.maxCombo,
        misses: this.misses,
        hits: { ...this.hits },
        accuracy: acc,
        grade: this._grade(acc),
        health: this.health,
      });
    }
  }

  _accuracy() {
    const total =
      this.hits.sick + this.hits.good + this.hits.bad + this.hits.shit + this.misses;
    if (!total) return 100;
    const weighted =
      this.hits.sick * 1 +
      this.hits.good * 0.75 +
      this.hits.bad * 0.4 +
      this.hits.shit * 0.2;
    return Math.round((weighted / total) * 10000) / 100;
  }

  _grade(acc) {
    if (this.misses === 0 && acc >= 100) return "P";
    if (acc >= 95) return "S";
    if (acc >= 90) return "A";
    if (acc >= 80) return "B";
    if (acc >= 70) return "C";
    if (acc >= 60) return "D";
    return "F";
  }

  _draw() {
    const { ctx, w, h } = this;
    ctx.clearRect(0, 0, w, h);
    const mobile = this.isMobileLayout();

    // Stage split glow
    if (!mobile) {
      const g1 = ctx.createLinearGradient(0, 0, w / 2, 0);
      g1.addColorStop(0, "rgba(255,26,26,0.06)");
      g1.addColorStop(1, "transparent");
      ctx.fillStyle = g1;
      ctx.fillRect(0, 0, w / 2, h);

      const g2 = ctx.createLinearGradient(w, 0, w / 2, 0);
      g2.addColorStop(0, "rgba(0,229,255,0.06)");
      g2.addColorStop(1, "transparent");
      ctx.fillStyle = g2;
      ctx.fillRect(w / 2, 0, w / 2, h);

      ctx.strokeStyle = "rgba(255,255,255,0.08)";
      ctx.beginPath();
      ctx.moveTo(w / 2, 0);
      ctx.lineTo(w / 2, h);
      ctx.stroke();
    } else {
      const g = ctx.createLinearGradient(0, 0, 0, h);
      g.addColorStop(0, "rgba(0,229,255,0.06)");
      g.addColorStop(0.5, "transparent");
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, w, h);
    }

    // Touch bar reserve (mobile)
    const touchReserve = mobile ? Math.min(h * 0.22, 130) : 0;

    // Character BEHIND notes (on main canvas so it is never covered)
    {
      const charH = mobile ? Math.min(h * 0.36, 260) : h * 0.55;
      const charW = mobile ? Math.min(w * 0.4, 200) : w * 0.32;
      const charX = mobile ? w * 0.02 : w * 0.58;
      const charY = mobile ? h - touchReserve - charH - 8 : h * 0.32;
      ctx.save();
      ctx.translate(charX, charY);
      this._paintCharacter(ctx, charW, charH, this.poseDir, mobile ? 0.92 : 0.9);
      ctx.restore();
    }

    const noteSize = mobile
      ? Math.min(78, Math.max(50, w * 0.155))
      : Math.min(64, w * 0.055);
    const gap = noteSize * (mobile ? 1.28 : 1.15);
    let receptorY;
    if (this.options.downscroll) {
      receptorY = mobile ? h * 0.12 : h * 0.18;
    } else {
      receptorY = mobile ? h - touchReserve - noteSize * 1.2 : h * 0.82;
    }
    const scrollDir = this.options.downscroll ? 1 : -1;
    const pxPerMs = ((mobile ? 0.52 : 0.45) * this.options.speed * h) / 1000;

    const drawSide = (side, centerX, sizeMul = 1) => {
      const ns = noteSize * sizeMul;
      const g = gap * sizeMul;
      const baseX = centerX - 1.5 * g;
      for (let i = 0; i < 4; i++) {
        const x = baseX + i * g;
        const flash = side === "player" ? this.flash[i] : 0;
        const held = side === "player" && this.held[i];
        ctx.save();
        ctx.translate(x, receptorY);
        ctx.strokeStyle = LANE_COLORS[i];
        ctx.fillStyle = held || flash > 0 ? LANE_COLORS[i] : "rgba(0,0,0,0.45)";
        ctx.globalAlpha = held ? 0.9 : 0.4 + flash * 0.55;
        ctx.lineWidth = mobile ? 4 : 3;
        this._roundRect(-ns / 2, -ns / 2, ns, ns, 10);
        ctx.fill();
        ctx.globalAlpha = 1;
        ctx.stroke();
        ctx.fillStyle = held || flash > 0 ? "#0a0a12" : LANE_COLORS[i];
        ctx.font = `bold ${ns * 0.45}px sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        const arrows = ["←", "↓", "↑", "→"];
        ctx.fillText(arrows[i], 0, 1);
        ctx.restore();
      }

      const t = this.songTime + this.options.offset;
      for (const n of this.notes) {
        if (n.side !== side || n.hit || n.missed) continue;
        const dy = (n.time - t) * pxPerMs * scrollDir;
        const y = receptorY + dy;
        if (y < -ns || y > h + ns) continue;
        const x = baseX + n.lane * g;
        ctx.save();
        ctx.translate(x, y);
        ctx.fillStyle = LANE_COLORS[n.lane];
        ctx.shadowColor = LANE_COLORS[n.lane];
        ctx.shadowBlur = mobile ? 18 : 12;
        this._roundRect(-ns / 2, -ns / 2, ns, ns, 10);
        ctx.fill();
        ctx.shadowBlur = 0;
        ctx.fillStyle = "#0a0a12";
        ctx.font = `bold ${ns * 0.45}px sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        const arrows = ["←", "↓", "↑", "→"];
        ctx.fillText(arrows[n.lane], 0, 1);
        ctx.restore();
      }
    };

    if (mobile) {
      // Single-player only — centered full-width highway
      drawSide("player", w * 0.5, 1);
    } else {
      drawSide("opponent", w * 0.28);
      drawSide("player", w * 0.72);
    }

    // Labels
    ctx.font = "12px 'Share Tech Mono', monospace";
    ctx.textAlign = "center";
    const pName = this.character?.name || "KOAL";
    if (mobile) {
      ctx.fillStyle = "rgba(255,255,255,0.92)";
      ctx.fillText(pName, w * 0.5, 26);
      ctx.fillStyle = "rgba(255,255,255,0.45)";
      ctx.font = "10px 'Share Tech Mono', monospace";
      ctx.fillText("tap pads below", w * 0.5, 42);
    } else {
      ctx.fillStyle = "rgba(255,80,80,0.7)";
      ctx.fillText("KROSS", w * 0.28, 48);
      ctx.fillStyle = "rgba(0,220,255,0.7)";
      ctx.fillText(`${pName}  ·  ←↓↑→ or WASD`, w * 0.72, 48);
    }
  }

  _roundRect(x, y, w, h, r) {
    const ctx = this.ctx;
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }
}
