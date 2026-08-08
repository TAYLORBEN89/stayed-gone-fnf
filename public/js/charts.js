/**
 * Second Dibs charts — main track uses real audio + beat-matched notes.
 * Song length ≈ 1:18. Chart BPM tuned for a pop/rock groove (~128).
 * Offset adjustable in Options if hits feel early/late.
 */

function makePattern(startMs, bpm, bars, pattern) {
  const beat = 60000 / bpm;
  const notes = [];
  for (let bar = 0; bar < bars; bar++) {
    for (const step of pattern) {
      const t = startMs + (bar * 4 + step.beat) * beat;
      notes.push({
        time: Math.round(t),
        lane: step.lane,
        side: step.side || "player",
        sustain: step.sustain || 0,
      });
    }
  }
  return notes;
}

function pushPattern(notes, t, bpm, pattern, bars) {
  notes.push(...makePattern(t, bpm, bars, pattern));
  return t + bars * 4 * (60000 / bpm);
}

/**
 * Main song chart synced to assets/audio/second-dibs.m4a (~78s).
 * Structure:
 *  - 4 bar intro (sparse)
 *  - verse / build / chorus sections on beat grid
 *  - player-heavy for mobile 1P; light opponent garnish on desktop
 */
export function generateSecondDibsChart() {
  // 128 BPM ≈ 468.75ms/beat — good default for energetic track; tweak offset in Options
  const bpm = 128;
  const beat = 60000 / bpm;
  const notes = [];
  // Small lead-in so first notes aren't on frame 0
  let t = beat * 4; // 1 bar count-in feel after audio starts

  // Sparse intro — learn the beat
  const intro = [
    { beat: 0, lane: 1, side: "player" },
    { beat: 2, lane: 2, side: "player" },
  ];
  // Steady quarter-note verse
  const verse = [
    { beat: 0, lane: 0, side: "player" },
    { beat: 1, lane: 1, side: "player" },
    { beat: 2, lane: 2, side: "player" },
    { beat: 3, lane: 3, side: "player" },
  ];
  // Groove with off-beats
  const groove = [
    { beat: 0, lane: 0, side: "player" },
    { beat: 0.5, lane: 2, side: "player" },
    { beat: 1, lane: 1, side: "player" },
    { beat: 2, lane: 3, side: "player" },
    { beat: 2.5, lane: 1, side: "player" },
    { beat: 3, lane: 0, side: "player" },
  ];
  // Call-response (opp then player) — still readable on mobile (player only shown)
  const trade = [
    { beat: 0, lane: 1, side: "opponent" },
    { beat: 0.5, lane: 3, side: "opponent" },
    { beat: 1, lane: 0, side: "player" },
    { beat: 1.5, lane: 2, side: "player" },
    { beat: 2, lane: 2, side: "opponent" },
    { beat: 2.5, lane: 0, side: "opponent" },
    { beat: 3, lane: 3, side: "player" },
    { beat: 3.5, lane: 1, side: "player" },
  ];
  // Pre-chorus build
  const build = [
    { beat: 0, lane: 0, side: "player" },
    { beat: 0.5, lane: 1, side: "player" },
    { beat: 1, lane: 2, side: "player" },
    { beat: 1.5, lane: 3, side: "player" },
    { beat: 2, lane: 2, side: "player" },
    { beat: 2.5, lane: 1, side: "player" },
    { beat: 3, lane: 0, side: "player" },
    { beat: 3.5, lane: 3, side: "player" },
  ];
  // Chorus — denser but still on grid
  const chorus = [
    { beat: 0, lane: 0, side: "player" },
    { beat: 0, lane: 2, side: "opponent" },
    { beat: 0.5, lane: 1, side: "player" },
    { beat: 1, lane: 3, side: "player" },
    { beat: 1, lane: 1, side: "opponent" },
    { beat: 1.5, lane: 2, side: "player" },
    { beat: 2, lane: 0, side: "player" },
    { beat: 2.25, lane: 1, side: "player" },
    { beat: 2.5, lane: 2, side: "player" },
    { beat: 2.75, lane: 3, side: "player" },
    { beat: 3, lane: 1, side: "player" },
    { beat: 3.5, lane: 0, side: "player" },
  ];
  // Bridge — alternate lanes
  const bridge = [
    { beat: 0, lane: 2, side: "player" },
    { beat: 1, lane: 0, side: "player" },
    { beat: 2, lane: 3, side: "player" },
    { beat: 3, lane: 1, side: "player" },
  ];
  // Outro — sparse
  const outro = [
    { beat: 0, lane: 1, side: "player" },
    { beat: 2, lane: 2, side: "player" },
    { beat: 0, lane: 0, side: "opponent" },
  ];

  // ~78s song at 128 BPM ≈ 41.6 bars of 4 after count-in
  // Section plan (bars):
  t = pushPattern(notes, t, bpm, intro, 4); // intro
  t = pushPattern(notes, t, bpm, verse, 4);
  t = pushPattern(notes, t, bpm, groove, 4);
  t = pushPattern(notes, t, bpm, trade, 4);
  t = pushPattern(notes, t, bpm, build, 2);
  t = pushPattern(notes, t, bpm, chorus, 6);
  t = pushPattern(notes, t, bpm, verse, 2);
  t = pushPattern(notes, t, bpm, groove, 4);
  t = pushPattern(notes, t, bpm, bridge, 4);
  t = pushPattern(notes, t, bpm, build, 2);
  t = pushPattern(notes, t, bpm, chorus, 6);
  t = pushPattern(notes, t, bpm, trade, 2);
  t = pushPattern(notes, t, bpm, outro, 4);

  notes.sort((a, b) => a.time - b.time || a.lane - b.lane);

  // Audio length ~78s — end chart slightly after last note / song end
  const duration = Math.max(Math.ceil(t + beat * 2), 78000 + 500);

  return {
    id: "second-dibs",
    name: "Second Dibs",
    artist: "My Song 3 · Kain vs Kross vs Koal",
    bpm,
    speed: 1.0,
    duration,
    audioUrl: "assets/audio/second-dibs.m4a",
    // If hits feel early, raise offset in Options (positive = later)
    offsetHint: 0,
    notes,
  };
}

export function generateTutorialChart() {
  const bpm = 100;
  const beat = 60000 / bpm;
  const notes = [];
  let t = beat * 4;
  const lanes = [0, 1, 2, 3, 0, 2, 1, 3, 1, 0, 3, 2];
  for (let i = 0; i < 24; i++) {
    notes.push({
      time: Math.round(t + i * beat),
      lane: lanes[i % lanes.length],
      side: "player",
      sustain: 0,
    });
  }
  return {
    id: "tutorial",
    name: "Static Signal (Tutorial)",
    artist: "Practice · no song",
    bpm,
    speed: 0.85,
    duration: Math.ceil(t + 24 * beat + 2000),
    audioUrl: null,
    notes,
  };
}

export const SONGS = [generateSecondDibsChart(), generateTutorialChart()];
