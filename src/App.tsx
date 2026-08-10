import { NavLink, Route, Routes, useLocation } from "react-router-dom";
import { motion } from "framer-motion";
import { StreakBadge } from "./components/StreakBadge";
import { HomeScreen } from "./features/home/HomeScreen";
import { PathScreen } from "./features/path/PathScreen";
import { ChallengeScreen } from "./features/challenge/ChallengeScreen";
import { LessonScreen } from "./features/lesson/LessonScreen";
import { CompeteScreen } from "./features/compete/CompeteScreen";
import { ProfileScreen } from "./features/profile/ProfileScreen";

const navItems = [
  { to: "/", label: "Home", end: true },
  { to: "/academy", label: "Academy" },
  { to: "/gauntlet", label: "Gauntlet" },
  { to: "/compete", label: "Compete" },
  { to: "/profile", label: "About" },
];

export function App() {
  const location = useLocation();

  return (
    <div className="flex min-h-full flex-col">
      <header className="sticky top-0 z-30 backdrop-blur-md" style={{ background: "rgba(242,242,235,0.9)", borderBottom: "1px solid rgba(32,46,68,0.1)" }}>
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-6 py-3 lg:px-8">
          <NavLink to="/" className="group flex items-center gap-1 transition-opacity hover:opacity-75">
            <span className="font-mono text-[0.6rem] font-bold uppercase tracking-[0.2em]" style={{ color: "#4A5568" }}>
              Forge
            </span>
            <span style={{ color: "#EA580C", fontSize: "0.4rem", lineHeight: 1 }}>◆</span>
            <span className="font-display text-[1.15rem] font-black leading-none tracking-tight" style={{ color: "#1A202C" }}>
              Code
            </span>
          </NavLink>

          <nav className="flex items-center gap-0.5">
            {navItems.map((item) => {
              const active =
                item.end ? location.pathname === "/" : location.pathname.startsWith(item.to);
              return (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.end}
                  className="relative rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors"
                  style={{ color: active ? "#1A202C" : "#4A5568" }}
                  data-active={active}
                >
                  {active && (
                    <motion.span
                      layoutId="nav-active"
                      className="absolute inset-0 -z-10 rounded-full"
                      style={{ background: "rgba(32,46,68,0.1)" }}
                      transition={{ type: "spring", stiffness: 420, damping: 34 }}
                    />
                  )}
                  {item.label}
                </NavLink>
              );
            })}
            <div className="ml-3 hidden sm:block">
              <StreakBadge />
            </div>
          </nav>
        </div>
      </header>

      <main className="flex-1">
        <Routes>
          <Route path="/" element={<HomeScreen />} />
          <Route path="/academy" element={<PathScreen track="academy" />} />
          <Route path="/gauntlet" element={<PathScreen track="gauntlet" />} />
          <Route path="/challenge/:id" element={<ChallengeScreen />} />
          <Route path="/lesson/:id" element={<LessonScreen />} />
          <Route path="/compete" element={<CompeteScreen />} />
          <Route path="/profile" element={<ProfileScreen />} />
          <Route path="*" element={<HomeScreen />} />
        </Routes>
      </main>

      <footer className="relative">
        <div className="absolute inset-x-0 top-0 h-px" style={{ background: "linear-gradient(90deg, transparent, rgba(234,88,12,0.2), rgba(74,144,196,0.1), transparent)" }} />
        <div className="mx-auto max-w-6xl px-6 py-5 text-center font-mono text-xs text-dim lg:px-8" />
      </footer>
    </div>
  );
}
