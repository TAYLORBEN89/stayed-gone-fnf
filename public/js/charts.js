/** Song charts for Second Dibs — Kain vs Kross vs Koal */

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

/** Generate a full dual-side chart for Second Dibs demo */
export function generateStayedGoneChart() {
  const bpm = 148;
  const beat = 60000 / bpm;
  const notes = [];

  // Intro — Kross (opponent, lanes 0-3) then Kain answers (player 4-7)
  // We use 8 lanes: 0-3 opponent, 4-7 player
  const intro = [
    { beat: 0, lane: 0, side: "opponent" },
    { beat: 1, lane: 2, side: "opponent" },
    { beat: 2, lane: 1, side: "opponent" },
    { beat: 3, lane: 3, side: "opponent" },
  ];
  const answer = [
    { beat: 0, lane: 0, side: "player" },
    { beat: 1, lane: 1, side: "player" },
    { beat: 2, lane: 2, side: "player" },
    { beat: 3, lane: 3, side: "player" },
  ];
  const trade = [
    { beat: 0, lane: 1, side: "opponent" },
    { beat: 0.5, lane: 3, side: "opponent" },
    { beat: 1, lane: 0, side: "player" },
    { beat: 1.5, lane: 2, side: "player" },
    { beat: 2, lane: 2, side: "opponent" },
    { beat: 2.5, lane: 1, side: "opponent" },
    { beat: 3, lane: 3, side: "player" },
    { beat: 3.5, lane: 0, side: "player" },
  ];
  const dense = [
    { beat: 0, lane: 0, side: "player" },
    { beat: 0.25, lane: 1, side: "player" },
    { beat: 0.5, lane: 2, side: "player" },
    { beat: 0.75, lane: 3, side: "player" },
    { beat: 1, lane: 2, side: "player" },
    { beat: 1.5, lane: 0, side: "player" },
    { beat: 2, lane: 1, side: "opponent" },
    { beat: 2.25, lane: 3, side: "opponent" },
    { beat: 2.5, lane: 0, side: "opponent" },
    { beat: 3, lane: 3, side: "player" },
    { beat: 3.5, lane: 1, side: "player" },
  ];
  const climax = [
    { beat: 0, lane: 0, side: "opponent" },
    { beat: 0, lane: 2, side: "player" },
    { beat: 0.5, lane: 1, side: "opponent" },
    { beat: 0.5, lane: 3, side: "player" },
    { beat: 1, lane: 3, side: "opponent" },
    { beat: 1, lane: 0, side: "player" },
    { beat: 1.5, lane: 2, side: "opponent" },
    { beat: 1.5, lane: 1, side: "player" },
    { beat: 2, lane: 0, side: "opponent" },
    { beat: 2.25, lane: 1, side: "player" },
    { beat: 2.5, lane: 2, side: "opponent" },
    { beat: 2.75, lane: 3, side: "player" },
    { beat: 3, lane: 1, side: "opponent" },
    { beat: 3, lane: 2, side: "player" },
    { beat: 3.5, lane: 0, side: "player" },
    { beat: 3.5, lane: 3, side: "opponent" },
  ];

  let t = 0;
  const push = (pattern, bars) => {
    notes.push(...makePattern(t, bpm, bars, pattern));
    t += bars * 4 * beat;
  };

  push(intro, 2);
  push(answer, 2);
  push(trade, 4);
  push(dense, 4);
  push(climax, 6);
  push(trade, 2);
  push(dense, 2);
  push(climax, 4);
  // Outro
  push(
    [
      { beat: 0, lane: 0, side: "opponent" },
      { beat: 2, lane: 2, side: "player" },
      { beat: 0, lane: 0, side: "player" },
      { beat: 2, lane: 3, side: "opponent" },
    ],
    2
  );

  notes.sort((a, b) => a.time - b.time || a.lane - b.lane);

  return {
    id: "second-dibs",
    name: "Second Dibs",
    artist: "Demo Chart · Kain vs Kross vs Koal",
    bpm,
    speed: 1.0,
    duration: Math.ceil(t + 2000),
    notes,
  };
}

export function generateTutorialChart() {
  const bpm = 120;
  const beat = 60000 / bpm;
  const notes = [];
  let t = beat * 2;
  const lanes = [0, 1, 2, 3, 0, 2, 1, 3];
  for (let i = 0; i < 32; i++) {
    notes.push({
      time: Math.round(t + i * beat),
      lane: lanes[i % lanes.length],
      side: "player",
      sustain: 0,
    });
    if (i % 4 === 0) {
      notes.push({
        time: Math.round(t + i * beat),
        lane: (lanes[i % lanes.length] + 1) % 4,
        side: "opponent",
        sustain: 0,
      });
    }
  }
  return {
    id: "tutorial",
    name: "Static Signal (Tutorial)",
    artist: "Practice",
    bpm,
    speed: 0.9,
    duration: Math.ceil(t + 32 * beat + 2000),
    notes,
  };
}

export const SONGS = [generateStayedGoneChart(), generateTutorialChart()];
