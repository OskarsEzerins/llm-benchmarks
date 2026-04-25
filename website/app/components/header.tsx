import { Link, useLocation } from "react-router"
import { Github } from "lucide-react"
import { ThemeToggle } from "./theme-toggle"

const NAV_LINKS = [
  { to: "/", label: "Rankings", match: "/" },
  { to: "/benchmarks/calendar", label: "Benchmarks", match: "/benchmarks" },
  { to: "/comparison", label: "Compare", match: "/comparison" },
]

export const Header = () => {
  const location = useLocation()

  const isActive = (match: string) => {
    if (match === "/") return location.pathname === "/"
    return location.pathname.startsWith(match)
  }

  return (
    <header className="sticky top-0 z-50 h-[52px] border-b-[3px] border-[var(--c-fg)] bg-[var(--c-surface)]">
      <div className="mx-auto flex h-full max-w-[1128px] items-center justify-between px-3 sm:px-5 lg:px-6">
        <Link to="/" className="flex min-w-0 items-center gap-2.5 text-[var(--c-fg)]">
          <span className="flex h-7 w-7 shrink-0 items-center justify-center bg-[var(--c-accent)] font-mono text-[15px] font-bold text-white">
            R
          </span>
          <span className="hidden whitespace-nowrap text-[15px] font-extrabold uppercase text-[var(--c-fg)] sm:inline">
            Ruby LLM Benchmarks
          </span>
        </Link>

        <div className="flex items-center">
          <nav className="flex text-[11px] font-bold uppercase tracking-[0.04em] sm:text-xs">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.to}
                to={link.to}
                className={`border-l-2 border-[var(--c-fg)] px-2.5 py-2 no-underline transition-colors sm:px-4 ${
                  isActive(link.match)
                    ? "bg-[var(--c-surface-2)] text-[var(--c-accent)]"
                    : "text-[var(--c-sub)] hover:bg-[var(--c-surface-2)] hover:text-[var(--c-fg)]"
                }`}
              >
                {link.label}
              </Link>
            ))}
          </nav>

          <a
            href="https://github.com/OskarsEzerins/llm-benchmarks"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="View source on GitHub"
            className="ml-2 hidden h-8 w-8 items-center justify-center border-2 border-[var(--c-fg)] bg-[var(--c-surface)] text-[var(--c-fg)] min-[460px]:flex"
          >
            <Github className="h-4 w-4" />
          </a>
          <ThemeToggle className="ml-1 hidden min-[520px]:inline-flex" />
        </div>
      </div>
    </header>
  )
}
