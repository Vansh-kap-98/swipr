'use client';

import { useCallback, useEffect, useRef, useState } from 'react';

type Decision = 'keep' | 'delete';

type Photo = { scene: string; caption: string; date: string; mb: number; verdict: Decision };

const PHOTOS: Photo[] = [
  { scene: 'scene-sunset', caption: 'Sunset at the pier', date: 'Aug 12', mb: 3.8, verdict: 'keep' },
  { scene: 'scene-blur', caption: 'Pocket shot', date: 'Aug 12', mb: 2.9, verdict: 'delete' },
  { scene: 'scene-ocean', caption: 'Beach day', date: 'Aug 10', mb: 4.2, verdict: 'keep' },
  { scene: 'scene-screens', caption: 'Screenshot', date: 'Aug 9', mb: 1.1, verdict: 'delete' },
  { scene: 'scene-forest', caption: 'Trail hike', date: 'Aug 3', mb: 3.5, verdict: 'keep' },
  { scene: 'scene-city', caption: 'Blurry city lights', date: 'Jul 29', mb: 2.6, verdict: 'delete' },
];

const TOTAL = 240; // for the progress bar; the photos themselves loop
const photoAt = (i: number) => PHOTOS[((i % PHOTOS.length) + PHOTOS.length) % PHOTOS.length]!;

const linear = (t: number) => t;
const easeIn = (t: number) => t * t * t;
const easeOut = (t: number) => 1 - (1 - t) ** 3;

/**
 * The swipeable phone in the hero. React renders the three visible cards;
 * dragging and the animations write transforms straight to the DOM, so no
 * state updates happen per frame.
 */
export function PhoneDemo() {
  const stackRef = useRef<HTMLDivElement>(null);
  const cardRefs = useRef(new Map<number, HTMLDivElement>());
  const offset = useRef({ x: 0, y: 0 });
  const index = useRef(0);
  const busy = useRef(false);
  const cancelled = useRef({ cancelled: false });
  const lastInteraction = useRef(-Infinity);
  const history = useRef<{ index: number; decision: Decision }[]>([]);
  const drag = useRef<{ id: number; startX: number; startY: number; samples: { t: number; x: number; y: number }[] } | null>(null);

  // Rendered state: which photos are on the stack, and the trash counter.
  const [top, setTop] = useState(0);
  const [trash, setTrash] = useState({ count: 0, mb: 0 });
  const visible = [top, top + 1, top + 2];

  const reduced = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const stackWidth = () => stackRef.current?.clientWidth || 300;

  const paint = useCallback(() => {
    const { x, y } = offset.current;
    const width = stackWidth();
    const progress = Math.min(Math.abs(x) / (width * 0.35), 1);

    visible.forEach((cardIndex, depthIndex) => {
      const el = cardRefs.current.get(cardIndex);
      if (!el) return;
      if (depthIndex === 0) {
        el.style.transform = `translate3d(${x}px, ${y}px, 0) rotate(${(x / width) * 15}deg)`;
        const keep = x > 0;
        const tint = el.querySelector<HTMLElement>('.demo-card__tint');
        if (tint) {
          tint.style.opacity = String(progress);
          tint.style.borderColor = keep ? 'var(--keep)' : 'var(--delete)';
          tint.style.background = keep ? 'rgba(48, 209, 88, 0.18)' : 'rgba(255, 69, 58, 0.18)';
        }
        const stampKeep = el.querySelector<HTMLElement>('.demo-card__stamp--keep');
        const stampDelete = el.querySelector<HTMLElement>('.demo-card__stamp--delete');
        if (stampKeep && stampDelete) {
          stampKeep.style.opacity = keep ? String(progress) : '0';
          stampDelete.style.opacity = keep ? '0' : String(progress);
          // Stamps slide in from their own edge as the drag builds up.
          stampKeep.style.transform = `translateX(${-24 * (1 - progress)}px) rotate(-16deg)`;
          stampDelete.style.transform = `translateX(${24 * (1 - progress)}px) rotate(16deg)`;
        }
      } else {
        const depth = Math.max(depthIndex - progress, 0);
        el.style.transform = `translate3d(0, ${depth * 12}px, 0) scale(${1 - depth * 0.05})`;
      }
    });
  }, [visible]);

  // Keep the cards positioned after React swaps them in.
  useEffect(paint);

  const stopAnimation = () => {
    cancelled.current.cancelled = true;
    cancelled.current = { cancelled: false };
  };

  const tween = (to: { x: number; y: number }, duration: number, ease: (t: number) => number) => {
    stopAnimation();
    const token = cancelled.current;
    const from = { ...offset.current };
    if (reduced()) {
      offset.current = { ...to };
      paint();
      return Promise.resolve(true);
    }
    const start = performance.now();
    return new Promise<boolean>((resolve) => {
      const frame = (now: number) => {
        if (token.cancelled) return resolve(false);
        const t = Math.min((now - start) / duration, 1);
        const k = ease(t);
        offset.current = { x: from.x + (to.x - from.x) * k, y: from.y + (to.y - from.y) * k };
        paint();
        if (t < 1) requestAnimationFrame(frame);
        else resolve(true);
      };
      requestAnimationFrame(frame);
    });
  };

  /** Critically damped spring back to the middle, continuing the release speed. */
  const springHome = (velocity: { x: number; y: number }) => {
    stopAnimation();
    const token = cancelled.current;
    if (reduced()) {
      offset.current = { x: 0, y: 0 };
      paint();
      return;
    }
    const stiffness = 420;
    const damping = 2 * Math.sqrt(stiffness);
    const v = { ...velocity };
    let last = performance.now();
    const frame = (now: number) => {
      if (token.cancelled) return;
      const dt = Math.min((now - last) / 1000, 1 / 30);
      last = now;
      (['x', 'y'] as const).forEach((axis) => {
        v[axis] += (-stiffness * offset.current[axis] - damping * v[axis]) * dt;
        offset.current[axis] += v[axis] * dt;
      });
      paint();
      if (Math.hypot(offset.current.x, offset.current.y) < 0.4 && Math.hypot(v.x, v.y) < 8) {
        offset.current = { x: 0, y: 0 };
        paint();
      } else requestAnimationFrame(frame);
    };
    requestAnimationFrame(frame);
  };

  const flyOut = async (decision: Decision, velocityX = 0, velocityY = 0) => {
    if (busy.current) return;
    busy.current = true;
    const width = stackWidth();
    const sign = decision === 'keep' ? 1 : -1;
    const exitX = sign * width * 1.6;
    const remaining = Math.abs(exitX - offset.current.x);

    let completed: boolean;
    if (Math.abs(velocityX) > 800 && Math.sign(velocityX) === sign) {
      // Thrown: keep the finger's speed and heading exactly.
      const seconds = Math.min(Math.max(remaining / Math.abs(velocityX), 0.12), 0.35);
      completed = await tween({ x: exitX, y: offset.current.y + velocityY * seconds }, seconds * 1000, linear);
    } else {
      completed = await tween({ x: exitX, y: offset.current.y + width * 0.08 }, 260, easeIn);
    }
    busy.current = false;
    if (!completed) return;

    const photo = photoAt(index.current);
    history.current.push({ index: index.current, decision });
    if (history.current.length > 20) history.current.shift();
    if (decision === 'delete') setTrash((t) => ({ count: t.count + 1, mb: t.mb + photo.mb }));

    index.current += 1;
    offset.current = { x: 0, y: 0 };
    setTop(index.current);
  };

  const undo = async () => {
    const last = history.current.pop();
    if (!last || busy.current) return;
    stopAnimation();
    const photo = photoAt(last.index);
    if (last.decision === 'delete') setTrash((t) => ({ count: Math.max(t.count - 1, 0), mb: Math.max(t.mb - photo.mb, 0) }));

    index.current = last.index;
    const sign = last.decision === 'keep' ? 1 : -1;
    offset.current = { x: sign * stackWidth() * 1.3, y: stackWidth() * 0.06 };
    setTop(index.current);
    await tween({ x: 0, y: 0 }, 380, easeOut);
  };

  // ---- Pointer dragging ----

  const onPointerDown = (e: React.PointerEvent) => {
    if (busy.current) return;
    const card = cardRefs.current.get(top);
    if (!card || !card.contains(e.target as Node)) return;
    lastInteraction.current = performance.now();
    stopAnimation();
    drag.current = { id: e.pointerId, startX: e.clientX - offset.current.x, startY: e.clientY - offset.current.y, samples: [] };
    card.setPointerCapture(e.pointerId);
  };

  const onPointerMove = (e: React.PointerEvent) => {
    const d = drag.current;
    if (!d || e.pointerId !== d.id) return;
    offset.current = { x: e.clientX - d.startX, y: (e.clientY - d.startY) * 0.6 };
    d.samples.push({ t: performance.now(), x: e.clientX, y: e.clientY });
    if (d.samples.length > 6) d.samples.shift();
    paint();
  };

  const onPointerEnd = (e: React.PointerEvent) => {
    const d = drag.current;
    if (!d || e.pointerId !== d.id) return;
    drag.current = null;
    lastInteraction.current = performance.now();

    let vx = 0;
    let vy = 0;
    const [first] = d.samples;
    const last = d.samples.at(-1);
    if (first && last && last !== first) {
      const dt = (last.t - first.t) / 1000;
      if (dt > 0 && performance.now() - last.t < 80) {
        vx = (last.x - first.x) / dt;
        vy = ((last.y - first.y) / dt) * 0.6;
      }
    }
    const x = offset.current.x;
    const width = stackWidth();
    const flung = Math.abs(vx) > 900 && (x === 0 || Math.sign(x) === Math.sign(vx));
    if (flung) void flyOut(vx > 0 ? 'keep' : 'delete', vx, vy);
    else if (Math.abs(x) > width * 0.35) void flyOut(x > 0 ? 'keep' : 'delete', vx, vy);
    else springHome({ x: vx, y: vy });
  };

  const onKeyDown = (e: React.KeyboardEvent) => {
    const decision = e.key === 'ArrowRight' ? 'keep' : e.key === 'ArrowLeft' ? 'delete' : null;
    if (decision) {
      e.preventDefault();
      lastInteraction.current = performance.now();
      void flyOut(decision);
    } else if (e.key === 'Backspace' || e.key.toLowerCase() === 'z') {
      e.preventDefault();
      lastInteraction.current = performance.now();
      void undo();
    }
  };

  // ---- Autoplay: hint at the swipe, then commit ----

  useEffect(() => {
    if (reduced()) return;
    let onScreen = false;
    const observer = new IntersectionObserver(([entry]) => (onScreen = Boolean(entry?.isIntersecting)), { threshold: 0.4 });
    if (stackRef.current?.parentElement) observer.observe(stackRef.current.parentElement);

    const timer = setInterval(async () => {
      if (!onScreen || document.hidden || busy.current || drag.current) return;
      if (performance.now() - lastInteraction.current < 6000) return;
      const decision = photoAt(index.current).verdict;
      const sign = decision === 'keep' ? 1 : -1;
      const peeked = await tween({ x: sign * stackWidth() * 0.28, y: 6 }, 520, easeOut);
      if (!peeked || drag.current) return;
      await new Promise((r) => setTimeout(r, 260));
      if (drag.current) return;
      if (performance.now() - lastInteraction.current >= 6000) await flyOut(decision);
      else springHome({ x: 0, y: 0 });
    }, 2300);

    return () => {
      clearInterval(timer);
      observer.disconnect();
    };
  }, []);

  const trashLabel = trash.count === 0 ? '🗑 0' : `🗑 ${trash.count} · ${trash.mb.toFixed(1)} MB`;

  return (
    <figure className="phone" aria-label="Interactive demo: drag the photo right to keep it or left to delete it">
      <div className="phone__screen">
        <div className="phone__status" aria-hidden="true">
          <span>9:41</span>
          <span className="phone__notch" />
          <span>100%</span>
        </div>
        <div className="demo__bar">
          <span className="demo__album">Camera Roll</span>
          <span className={`demo__pill${trash.count > 0 ? ' is-active' : ''}`}>
            <span key={trashLabel} className="is-in">
              {trashLabel}
            </span>
          </span>
        </div>
        <div className="demo__progress" aria-hidden="true">
          <ProgressBar reviewed={top} />
        </div>

        <div
          className="demo__stack"
          ref={stackRef}
          tabIndex={0}
          role="group"
          aria-label="Swipe demo. Press the right arrow to keep, left arrow to delete, Z to undo."
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerEnd}
          onPointerCancel={onPointerEnd}
          onKeyDown={onKeyDown}
        >
          {/* Painted back to front, so the top card is last in the DOM. */}
          {[...visible].reverse().map((cardIndex) => {
            const photo = photoAt(cardIndex);
            return (
              <div
                key={cardIndex}
                className="demo-card"
                ref={(el) => {
                  if (el) cardRefs.current.set(cardIndex, el);
                  else cardRefs.current.delete(cardIndex);
                }}
              >
                <div className={`demo-card__photo ${photo.scene}`} />
                <div className="demo-card__caption">
                  <span>{photo.caption}</span>
                  <span>{photo.date}</span>
                </div>
                <div className="demo-card__tint" />
                <div className="demo-card__stamp demo-card__stamp--keep">KEEP</div>
                <div className="demo-card__stamp demo-card__stamp--delete">DELETE</div>
              </div>
            );
          })}
        </div>

        <div className="demo__actions" aria-hidden="true">
          <button type="button" className="demo__btn demo__btn--delete" tabIndex={-1} onClick={() => void flyOut('delete')}>
            ✕
          </button>
          <button type="button" className="demo__btn demo__btn--undo" tabIndex={-1} onClick={() => void undo()}>
            ↺
          </button>
          <button type="button" className="demo__btn demo__btn--keep" tabIndex={-1} onClick={() => void flyOut('keep')}>
            ✓
          </button>
        </div>
      </div>
      <figcaption className="phone__hint">Try it: drag the photo</figcaption>
    </figure>
  );
}

function ProgressBar({ reviewed }: { reviewed: number }) {
  const ref = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    // Written through the CSSOM rather than a style attribute, so the site's
    // strict content security policy keeps working.
    ref.current?.style.setProperty('transform', `scaleX(${Math.max((reviewed % TOTAL) / TOTAL, 0.02)})`);
  }, [reviewed]);
  return <span ref={ref} />;
}
