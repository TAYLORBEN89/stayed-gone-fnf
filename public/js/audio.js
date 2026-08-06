/** Procedural beat bed so the game plays without copyrighted audio */

export class AudioEngine {
  constructor() {
    this.ctx = null;
    this.master = null;
    this.volume = 0.7;
    this.playing = false;
    this.startTime = 0;
    this.bpm = 148;
    this._timer = null;
    this._beat = 0;
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
  }

  /** Current song time in ms */
  now() {
    if (!this.playing || !this.ctx) return 0;
    return (this.ctx.currentTime - this.startTime) * 1000;
  }

  async start(bpm = 148) {
    await this.ensure();
    this.bpm = bpm;
    this.playing = true;
    this.startTime = this.ctx.currentTime;
    this._beat = 0;
    this._scheduleLoop();
  }

  stop() {
    this.playing = false;
    if (this._timer) {
      clearTimeout(this._timer);
      this._timer = null;
    }
  }

  _scheduleLoop() {
    if (!this.playing) return;
    const beatSec = 60 / this.bpm;
    const next = this.startTime + this._beat * beatSec;
    const delay = Math.max(0, (next - this.ctx.currentTime) * 1000 - 5);
    this._timer = setTimeout(() => {
      if (!this.playing) return;
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

    // Kick
    if (isHalf) {
      const o = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      o.type = "sine";
      o.frequency.setValueAtTime(isDown ? 110 : 85, t);
      o.frequency.exponentialRampToValueAtTime(40, t + 0.12);
      g.gain.setValueAtTime(0.45, t);
      g.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
      o.connect(g);
      g.connect(this.master);
      o.start(t);
      o.stop(t + 0.2);
    }

    // Hi-hat
    const noise = this.ctx.createBufferSource();
    const buf = this.ctx.createBuffer(1, this.ctx.sampleRate * 0.05, this.ctx.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
    noise.buffer = buf;
    const ng = this.ctx.createGain();
    ng.gain.setValueAtTime(isDown ? 0.08 : 0.04, t);
    ng.gain.exponentialRampToValueAtTime(0.001, t + 0.04);
    const filt = this.ctx.createBiquadFilter();
    filt.type = "highpass";
    filt.frequency.value = 6000;
    noise.connect(filt);
    filt.connect(ng);
    ng.connect(this.master);
    noise.start(t);

    // Bass stab every bar
    if (isDown) {
      const o = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      o.type = "sawtooth";
      o.frequency.value = n % 8 === 0 ? 55 : 73.4;
      g.gain.setValueAtTime(0.12, t);
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

  /** Short hit SFX */
  hit(judgement = "sick") {
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    const freqs = { sick: 880, good: 660, bad: 440, shit: 330, miss: 120 };
    o.type = judgement === "miss" ? "sawtooth" : "square";
    o.frequency.setValueAtTime(freqs[judgement] || 660, t);
    g.gain.setValueAtTime(judgement === "miss" ? 0.15 : 0.08, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.08);
    o.connect(g);
    g.connect(this.master);
    o.start(t);
    o.stop(t + 0.1);
  }
}
