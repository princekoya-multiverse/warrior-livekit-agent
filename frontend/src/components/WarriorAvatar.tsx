import { useEffect, useRef } from "react";

interface WarriorAvatarProps {
  /** Audio amplitude 0..1 that drives mouth movement (lip-sync). */
  amplitude: number;
  /** Whether the agent is currently connected/active. */
  active: boolean;
}

/**
 * WarriorAvatar
 *
 * A canvas-rendered, stylised warrior face. The mouth opening is driven by the
 * incoming audio amplitude to create a lightweight lip-sync effect — no WebGL,
 * no GPU, no external model. A subtle "breathing" glow indicates an active,
 * listening agent. Warrior-themed: dark background, gold accents.
 */
export function WarriorAvatar({ amplitude, active }: WarriorAvatarProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const ampRef = useRef(0);
  const activeRef = useRef(active);
  const tRef = useRef(0);

  useEffect(() => {
    ampRef.current = amplitude;
  }, [amplitude]);
  useEffect(() => {
    activeRef.current = active;
  }, [active]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d")!;
    let raf = 0;

    const GOLD = "#c8a24a";
    const GOLD_DIM = "rgba(200,162,74,0.35)";

    const resize = () => {
      const dpr = window.devicePixelRatio || 1;
      const size = Math.min(canvas.clientWidth, canvas.clientHeight);
      canvas.width = size * dpr;
      canvas.height = size * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    resize();
    window.addEventListener("resize", resize);

    const draw = () => {
      tRef.current += 0.016;
      const t = tRef.current;
      const amp = ampRef.current;
      const on = activeRef.current;
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      const cx = w / 2;
      const cy = h / 2;
      const R = Math.min(w, h) * 0.34;

      ctx.clearRect(0, 0, w, h);

      // Outer pulsing aura — breathing when idle, reactive when speaking.
      const pulse = on ? 0.5 + 0.5 * Math.sin(t * 1.5) : 0;
      const auraR = R * (1.5 + amp * 0.6 + pulse * 0.08);
      const grad = ctx.createRadialGradient(cx, cy, R * 0.6, cx, cy, auraR);
      grad.addColorStop(0, `rgba(200,162,74,${0.18 + amp * 0.4})`);
      grad.addColorStop(1, "rgba(200,162,74,0)");
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.arc(cx, cy, auraR, 0, Math.PI * 2);
      ctx.fill();

      // Head / helmet circle.
      ctx.lineWidth = 3;
      ctx.strokeStyle = GOLD;
      ctx.fillStyle = "#11161f";
      ctx.beginPath();
      ctx.arc(cx, cy, R, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      // Helmet crest (warrior mohawk).
      ctx.fillStyle = GOLD;
      ctx.beginPath();
      ctx.moveTo(cx, cy - R * 1.32);
      ctx.lineTo(cx - R * 0.16, cy - R * 0.95);
      ctx.lineTo(cx + R * 0.16, cy - R * 0.95);
      ctx.closePath();
      ctx.fill();

      // Eyes (glow brighter when active).
      const eyeY = cy - R * 0.18;
      const eyeDx = R * 0.42;
      const eyeGlow = on ? 0.6 + amp * 0.4 : 0.3;
      ctx.fillStyle = `rgba(200,162,74,${eyeGlow})`;
      for (const dx of [-eyeDx, eyeDx]) {
        ctx.beginPath();
        ctx.ellipse(cx + dx, eyeY, R * 0.12, R * 0.07, 0, 0, Math.PI * 2);
        ctx.fill();
      }

      // Nose guard line.
      ctx.strokeStyle = GOLD_DIM;
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(cx, eyeY + R * 0.05);
      ctx.lineTo(cx, cy + R * 0.18);
      ctx.stroke();

      // Mouth — driven by amplitude (lip-sync).
      const mouthY = cy + R * 0.42;
      const mouthW = R * 0.5;
      const openness = Math.max(0.04, amp) * R * 0.45;
      ctx.fillStyle = "#1c2430";
      ctx.strokeStyle = GOLD;
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.ellipse(cx, mouthY, mouthW * 0.5, openness, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      raf = requestAnimationFrame(draw);
    };
    draw();

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
    };
  }, []);

  return <canvas ref={canvasRef} className="warrior-avatar-canvas" />;
}
