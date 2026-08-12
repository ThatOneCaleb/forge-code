import { useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { EmberCoin } from "./EmberCoin";

interface EmberToastProps {
  amount: number;
  onDone: () => void;
}

export function EmberToast({ amount, onDone }: EmberToastProps) {
  useEffect(() => {
    const t = setTimeout(onDone, 2600);
    return () => clearTimeout(t);
  }, [onDone]);

  return (
    <motion.div
      initial={{ y: 40, opacity: 0, scale: 0.88 }}
      animate={{ y: 0, opacity: 1, scale: 1 }}
      exit={{ y: -24, opacity: 0, scale: 0.92 }}
      transition={{ type: "spring", stiffness: 380, damping: 22 }}
      style={{
        position: "fixed",
        bottom: 40,
        left: "50%",
        transform: "translateX(-50%)",
        zIndex: 100,
        display: "flex",
        alignItems: "center",
        gap: 10,
        background: "#1A1D23",
        border: "1px solid rgba(234,88,12,0.35)",
        borderRadius: 12,
        padding: "12px 20px 12px 14px",
        boxShadow:
          "0 8px 32px rgba(0,0,0,0.5), 0 0 0 1px rgba(234,88,12,0.1) inset, 0 4px 24px rgba(234,88,12,0.2)",
        pointerEvents: "none",
        whiteSpace: "nowrap",
      }}
    >
      <motion.div
        animate={{ rotate: [0, -15, 15, -8, 8, 0], scale: [1, 1.15, 1] }}
        transition={{ duration: 0.6, delay: 0.15 }}
      >
        <EmberCoin size={28} glow />
      </motion.div>

      <div style={{ display: "flex", flexDirection: "column", lineHeight: 1.2 }}>
        <span
          style={{
            fontFamily: '"Chakra Petch", sans-serif',
            fontSize: 18,
            fontWeight: 700,
            color: "#E9EAEE",
            letterSpacing: "-0.01em",
          }}
        >
          +{amount}
        </span>
        <span
          style={{
            fontFamily: '"JetBrains Mono", monospace',
            fontSize: 10,
            color: "#EA580C",
            letterSpacing: "0.12em",
            textTransform: "uppercase",
          }}
        >
          embers
        </span>
      </div>
    </motion.div>
  );
}

export function EmberToastWrapper({
  show,
  amount,
  onDone,
}: {
  show: boolean;
  amount: number;
  onDone: () => void;
}) {
  return (
    <AnimatePresence>
      {show && <EmberToast amount={amount} onDone={onDone} />}
    </AnimatePresence>
  );
}
