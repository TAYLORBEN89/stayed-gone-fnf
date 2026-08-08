/**
 * Audio engine: real song playback + hit SFX.
 * Falls back to a procedural beat bed if no track is set.
 */

export class AudioEngine {
  constructor() {
    this.ctx = null;
    this.master = null;
    this.volume = 0.7;
    this.playing = false;
    this.startTime = 0;
    this.bpm = 128;
    this._timer = null;
    this._beat = 0;

    /** @type {HTMLAudioElement|null} */
    this.track = null;
    this.trackUrl = null;
    this.useTrack = false;
    this._pauseMs = 0;
  }

  async ensure() {
    if (!this.ctx) {
      this.ctx = new (window.AudioContext || window.webkitAudioContext)();
      this.master = this.ctx.createGain();
      this.master.gain.value = this.volume;
      this.master.connect(this.ctx.destination);
    }
    if (this.ctx.state === "suspended") {
      await this.ctx.resume();
    }
  }

  setVolume(v) {
    this.volume = Math.max(0, Math.min(1, v));
    if (this.master) this.master.gain.value = this.volume;
    if (this.track) this.track.volume = this.volume;
  }

  /** Load (or reuse) an audio track URL */
  async loadTrack(url) {
    if (this.trackUrl === url && this.track) return this.track;
    if (this.track) {
      this.track.pause();
      this.track.src = "";
      this.track = null;
    }
    const el = new Audio();
    el.preload = "auto";
    el.crossOrigin = "anonymous";
    el.src = url;
    el.volume = this.volume;
    await new Promise((resolve, reject) => {
      const ok = () => {
        cleanup();
        resolve();
      };
      const err = () => {
        cleanup();
        reject(new Error("Failed to load audio: " + url));
      };
      const cleanup = () => {
        el.removeEventListener("canplaythrough", ok);
        el.removeEventListener("error", err);
      };
      el.addEventListener("canplaythrough", ok, { once: true });
      el.addEventListener("error", err, { once: true });
      el.load();
      // Safari sometimes never fires canplaythrough — timeout fallback
      setTimeout(() => {
        if (el.readyState >= 2) ok();
      }, 2500);
    });
    this.track = el;
    this.trackUrl = url;
    return el;
  }

  /** Current song time in ms */
  now() {
    if (!this.playing) return this._pauseMs || 0;
    if (this.useTrack && this.track) {
      return this.track.currentTime * 1000;
    }
    if (!this.ctx) return 0;
    return (this.ctx.currentTime - this.startTime) * 1000;
  }

  /**
   * @param {number|object} bpmOrOpts - bpm number, or { bpm, audioUrl }
   */
  async start(bpmOrOpts = 128) {
    await this.ensure();
    const opts = typeof bpmOrOpts === "object" && bpmOrOpts !== null ? bpmOrOpts : { bpm: bpmOrOpts };
    this.bpm = opts.bpm || 128;
    this._pauseMs = 0;

    // Stop previous track
    if (this.track) {
      this.track.pause();
      this.track.currentTime = 0;
    }
    this.stopProcedural();

    if (opts.audioUrl) {
      try {
        await this.loadTrack(opts.audioUrl);
        this.useTrack = true;
        this.playing = true;
        this.track.currentTime = 0;
        this.track.volume = this.volume;
        await this.track.play();
        return;
      } catch (e) {
        console.warn("[Audio] track play failed, falling back to procedural", e);
        this.useTrack = false;
      }
    }

    this.useTrack = false;
    this.playing = true;
    this.startTime = this.ctx.currentTime;
    this._beat = 0;
    this._scheduleLoop();
  }

  pause() {
    if (!this.playing) return;
    this._pauseMs = this.now();
    this.playing = false;
    if (this.useTrack && this.track) {
      this.track.pause();
    }
    this.stopProcedural();
  }

  async resume() {
    await this.ensure();
    if (this.useTrack && this.track) {
      this.playing = true;
      try {
        this.track.currentTime = (this._pauseMs || 0) / 1000;
        await this.track.play();
      } catch (e) {
        console.warn("[Audio] resume failed", e);
      }
      return;
    }
    // Procedural resume from pause point
    this.playing = true;
    this.startTime = this.ctx.currentTime - (this._pauseMs || 0) / 1000;
    this._beat = Math.floor(((this._pauseMs || 0) / 1000) * (this.bpm / 60));
    this._scheduleLoop();
  }

  stop() {
    this.playing = false;
    this._pauseMs = 0;
    if (this.track) {
      this.track.pause();
      try {
        this.track.currentTime = 0;
      } catch (_) {}
    }
    this.stopProcedural();
  }

  stopProcedural() {
    if (this._timer) {
      clearTimeout(this._timer);
      this._timer = null;
    }
  }

  _scheduleLoop() {
    if (!this.playing || this.useTrack) return;
    const beatSec = 60 / this.bpm;
    const next = this.startTime + this._beat * beatSec;
    const delay = Math.max(0, (next - this.ctx.currentTime) * 1000 - 5);
    this._timer = setTimeout(() => {
      if (!this.playing || this.useTrack) return;
      this._hitBeat(this._beat);
      this._beat++;
      this._scheduleLoop();
    }, delay);
  }

  _hitBeat(n) {
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const isDown = n % 4 === 0;
    const isHalf = n % 2 === 0;

    if (isHalf) {
      const o = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      o.type = "sine";
      o.frequency.setValueAtTime(isDown ? 110 : 85, t);
      o.frequency.exponentialRampToValueAtTime(40, t + 0.12);
      g.gain.setValueAtTime(0.45 * this.volume, t);
      g.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
      o.connect(g);
      g.connect(this.master);
      o.start(t);
      o.stop(t + 0.2);
    }

    const noise = this.ctx.createBufferSource();
    const buf = this.ctx.createBuffer(1, this.ctx.sampleRate * 0.05, this.ctx.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
    noise.buffer = buf;
    const ng = this.ctx.createGain();
    ng.gain.setValueAtTime((isDown ? 0.08 : 0.04) * this.volume, t);
    ng.gain.exponentialRampToValueAtTime(0.001, t + 0.04);
    const filt = this.ctx.createBiquadFilter();
    filt.type = "highpass";
    filt.frequency.value = 6000;
    noise.connect(filt);
    filt.connect(ng);
    ng.connect(this.master);
    noise.start(t);

    if (isDown) {
      const o = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      o.type = "sawtooth";
      o.frequency.value = n % 8 === 0 ? 55 : 73.4;
      g.gain.setValueAtTime(0.12 * this.volume, t);
      g.gain.exponentialRampToValueAtTime(0.001, t + 0.35);
      const f = this.ctx.createBiquadFilter();
      f.type = "lowpass";
      f.frequency.value = 400;
      o.connect(f);
      f.connect(g);
      g.connect(this.master);
      o.start(t);
      o.stop(t + 0.4);
    }
  }

  /** Short hit SFX (layered under music, quieter when track plays) */
  hit(judgement = "sick") {
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    const freqs = { sick: 880, good: 660, bad: 440, shit: 330, miss: 120 };
    o.type = judgement === "miss" ? "sawtooth" : "square";
    o.frequency.setValueAtTime(freqs[judgement] || 660, t);
    const vol = this.useTrack ? 0.045 : 0.08;
    g.gain.setValueAtTime(judgement === "miss" ? 0.1 : vol, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.08);
    o.connect(g);
    g.connect(this.master);
    o.start(t);
    o.stop(t + 0.1);
  }
}
