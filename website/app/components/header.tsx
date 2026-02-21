import { Link, useLocation } from "react-router"
import { Github, Menu, X, ChevronDown, Code, Trophy, BarChart3 } from "lucide-react"
import { useState } from "react"
import { ThemeToggle } from "./theme-toggle"
import { Button } from "./ui/button"
import { Logo } from "./logo"
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
} from "./ui/navigation-menu"

const BENCHMARK_LINKS = [
  { to: "/benchmarks/calendar", label: "Calendar" },
  { to: "/benchmarks/parking-garage", label: "Parking Garage" },
  { to: "/benchmarks/school-library", label: "School Library" },
  { to: "/benchmarks/vending-machine", label: "Vending Machine" },
]

export const Header = () => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const [isBenchmarksOpen, setIsBenchmarksOpen] = useState(false)
  const location = useLocation()

  const isActive = (path: string) => {
    if (path === "/") {
      return location.pathname === "/"
    }
    return location.pathname.startsWith(path)
  }

  const getMobileLinkClassName = (path: string) => {
    const base = "block py-2 px-3 text-sm font-medium transition-colors hover:text-foreground/80 relative"
    const active = "text-foreground font-semibold bg-primary/10 border-l-4 border-primary shadow-md"
    const inactive = "text-foreground/60"
    return `${base} ${isActive(path) ? active : inactive}`
  }

  return (
    <header className="sticky top-0 z-50 w-full border-b-2 border-border bg-background shadow-lg">
      <div className="container mx-auto flex h-16 items-center justify-between px-4">
        <div className="flex items-center">
          <Link to="/" className="transition-opacity hover:opacity-80">
            <Logo size="md" />
          </Link>
        </div>

        {/* Desktop nav */}
        <nav className="hidden md:flex items-center text-sm font-medium">
          <NavigationMenu>
            <NavigationMenuList>
              <NavigationMenuItem>
                <NavigationMenuLink asChild className="flex-row items-center">
                  <Link
                    to="/"
                    className={`flex items-center gap-1.5 px-4 py-2 rounded-md transition-colors hover:text-foreground/80 relative ${isActive("/") ? "text-foreground font-semibold after:absolute after:bottom-[-1px] after:left-0 after:right-0 after:h-0.5 after:bg-primary after:rounded-full" : "text-foreground/60"}`}
                  >
                    <Trophy className="h-3.5 w-3.5" />
                    Rankings
                  </Link>
                </NavigationMenuLink>
              </NavigationMenuItem>

              <NavigationMenuItem>
                <NavigationMenuTrigger
                  className={`flex items-center gap-1.5 transition-colors ${isActive("/benchmarks") ? "text-foreground font-semibold" : "text-foreground/60"}`}
                >
                  <BarChart3 className="h-3.5 w-3.5" />
                  Benchmarks
                </NavigationMenuTrigger>
                <NavigationMenuContent>
                  <ul className="grid w-[240px] gap-1 p-2">
                    {BENCHMARK_LINKS.map((link) => (
                      <li key={link.to}>
                        <NavigationMenuLink asChild>
                          <Link
                            to={link.to}
                            className={`block select-none rounded-sm px-3 py-2 text-sm transition-colors hover:bg-accent hover:text-accent-foreground ${
                              isActive(link.to) ? "bg-accent/50 font-medium" : ""
                            }`}
                          >
                            {link.label}
                          </Link>
                        </NavigationMenuLink>
                      </li>
                    ))}
                  </ul>
                </NavigationMenuContent>
              </NavigationMenuItem>

              <NavigationMenuItem>
                <NavigationMenuLink asChild className="flex-row items-center">
                  <Link
                    to="/comparison"
                    className={`flex items-center gap-1.5 px-4 py-2 rounded-md transition-colors hover:text-foreground/80 relative ${isActive("/comparison") ? "text-foreground font-semibold after:absolute after:bottom-[-1px] after:left-0 after:right-0 after:h-0.5 after:bg-primary after:rounded-full" : "text-foreground/60"}`}
                  >
                    <Code className="h-3.5 w-3.5" />
                    Comparison
                  </Link>
                </NavigationMenuLink>
              </NavigationMenuItem>
            </NavigationMenuList>
          </NavigationMenu>
        </nav>

        <div className="flex items-center space-x-2">
          <Button variant="ghost" size="icon" asChild>
            <a
              href="https://github.com/OskarsEzerins/llm-benchmarks"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="View source on GitHub"
            >
              <Github className="h-4 w-4" />
            </a>
          </Button>
          <ThemeToggle />

          {/* Mobile menu toggle */}
          <Button
            variant="ghost"
            size="icon"
            className="md:hidden"
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            aria-label="Toggle mobile menu"
          >
            {isMobileMenuOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
          </Button>
        </div>
      </div>

      {/* Mobile menu */}
      {isMobileMenuOpen && (
        <div className="md:hidden border-t-2 border-border bg-background shadow-lg">
          <nav className="container mx-auto px-4 py-4 space-y-1">
            <Link
              to="/"
              className={getMobileLinkClassName("/")}
              onClick={() => setIsMobileMenuOpen(false)}
            >
              <span className="flex items-center gap-2">
                <Trophy className="h-3.5 w-3.5" />
                Rankings
              </span>
            </Link>

            {/* Benchmarks accordion group */}
            <div>
              <button
                onClick={() => setIsBenchmarksOpen(!isBenchmarksOpen)}
                aria-expanded={isBenchmarksOpen}
                className={`w-full flex items-center justify-between py-2 px-3 text-sm font-medium transition-colors hover:text-foreground/80 ${
                  isActive("/benchmarks") ? "text-foreground font-semibold" : "text-foreground/60"
                }`}
              >
                <span className="flex items-center gap-2">
                  <BarChart3 className="h-3.5 w-3.5" />
                  Benchmarks
                </span>
                <ChevronDown className={`h-4 w-4 transition-transform ${isBenchmarksOpen ? "rotate-180" : ""}`} />
              </button>
              {isBenchmarksOpen && (
                <div className="ml-6 space-y-1 border-l-2 border-border pl-2">
                  {BENCHMARK_LINKS.map((link) => (
                    <Link
                      key={link.to}
                      to={link.to}
                      className={getMobileLinkClassName(link.to)}
                      onClick={() => setIsMobileMenuOpen(false)}
                    >
                      {link.label}
                    </Link>
                  ))}
                </div>
              )}
            </div>

            <Link
              to="/comparison"
              className={getMobileLinkClassName("/comparison")}
              onClick={() => setIsMobileMenuOpen(false)}
            >
              <span className="flex items-center gap-2">
                <Code className="h-3.5 w-3.5" />
                Comparison
              </span>
            </Link>
          </nav>
        </div>
      )}
    </header>
  )
}
