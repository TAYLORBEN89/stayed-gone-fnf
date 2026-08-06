const LANE_COLORS = ["#c44dff", "#4d9fff", "#4dff7a", "#ff4d6a"];
const LANE_KEYS = {
  // Player lanes 0-3
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
      speed: 2.2,
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
    this._boundKeyDown = (e) => this._keyDown(e);
    this._boundKeyUp = (e) => this._keyUp(e);
    this._resize();
    window.addEventListener("resize", () => this._resize());
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
    await this.audio.start(this.chart.bpm);
    this._loop();
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
    this.held[lane] = true;
    this.flash[lane] = 1;
    if (!this.options.botplay) this._tryHit(lane);
  }

  _keyUp(e) {
    const lane = LANE_KEYS[e.key];
    if (lane === undefined) return;
    this.held[lane] = false;
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
    const speed = this.options.speed;

    // Botplay
    if (this.options.botplay) {
      for (const n of this.notes) {
        if (n.side === "player" && !n.hit && !n.missed && t >= n.time) {
          n.hit = true;
          n.judged = true;
          this.flash[n.lane] = 1;
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

    // Stage split glow
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

    // Center divider
    ctx.strokeStyle = "rgba(255,255,255,0.08)";
    ctx.beginPath();
    ctx.moveTo(w / 2, 0);
    ctx.lineTo(w / 2, h);
    ctx.stroke();

    const noteSize = Math.min(64, w * 0.055);
    const gap = noteSize * 1.15;
    const receptorY = this.options.downscroll ? h * 0.18 : h * 0.82;
    const scrollDir = this.options.downscroll ? 1 : -1;
    const pxPerMs = (0.45 * this.options.speed * h) / 1000;

    const drawSide = (side, centerX) => {
      const baseX = centerX - (1.5 * gap);
      // receptors
      for (let i = 0; i < 4; i++) {
        const x = baseX + i * gap;
        const flash = side === "player" ? this.flash[i] : 0;
        const held = side === "player" && this.held[i];
        ctx.save();
        ctx.translate(x, receptorY);
        ctx.strokeStyle = LANE_COLORS[i];
        ctx.fillStyle = held || flash > 0
          ? LANE_COLORS[i]
          : "rgba(0,0,0,0.35)";
        ctx.globalAlpha = held ? 0.85 : 0.35 + flash * 0.55;
        ctx.lineWidth = 3;
        this._roundRect(-noteSize / 2, -noteSize / 2, noteSize, noteSize, 10);
        ctx.fill();
        ctx.globalAlpha = 1;
        ctx.stroke();
        // arrow glyph
        ctx.fillStyle = held || flash > 0 ? "#0a0a12" : LANE_COLORS[i];
        ctx.font = `bold ${noteSize * 0.45}px sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        const arrows = ["←", "↓", "↑", "→"];
        ctx.fillText(arrows[i], 0, 1);
        ctx.restore();
      }

      // notes
      const t = this.songTime + this.options.offset;
      for (const n of this.notes) {
        if (n.side !== side || n.hit || n.missed) continue;
        const dy = (n.time - t) * pxPerMs * scrollDir;
        const y = receptorY + dy;
        if (y < -noteSize || y > h + noteSize) continue;
        const x = baseX + n.lane * gap;
        ctx.save();
        ctx.translate(x, y);
        ctx.fillStyle = LANE_COLORS[n.lane];
        ctx.shadowColor = LANE_COLORS[n.lane];
        ctx.shadowBlur = 12;
        this._roundRect(-noteSize / 2, -noteSize / 2, noteSize, noteSize, 10);
        ctx.fill();
        ctx.shadowBlur = 0;
        ctx.fillStyle = "#0a0a12";
        ctx.font = `bold ${noteSize * 0.45}px sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        const arrows = ["←", "↓", "↑", "→"];
        ctx.fillText(arrows[n.lane], 0, 1);
        ctx.restore();
      }
    };

    // Opponent left, player right
    drawSide("opponent", w * 0.28);
    drawSide("player", w * 0.72);

    // Labels
    ctx.font = "12px 'Share Tech Mono', monospace";
    ctx.fillStyle = "rgba(255,80,80,0.7)";
    ctx.textAlign = "center";
    ctx.fillText("ALASTOR", w * 0.28, 48);
    ctx.fillStyle = "rgba(0,220,255,0.7)";
    ctx.fillText("VOX  ·  ←↓↑→ or WASD", w * 0.72, 48);
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
