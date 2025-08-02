import { Moon, Sun, Monitor } from "lucide-react"

import { Button } from "~/components/ui/button"
import { useTheme } from "~/lib/theme-provider"

export const ThemeToggle = () => {
  const { theme, setTheme } = useTheme()

  const toggleTheme = () => {
    if (theme === "light") {
      setTheme("dark")
    } else if (theme === "dark") {
      setTheme("system")
    } else {
      setTheme("light")
    }
  }

  const getIcon = () => {
    if (theme === "dark") {
      return <Moon className="h-4 w-4" />
    }
    if (theme === "light") {
      return <Sun className="h-4 w-4" />
    }
    return <Monitor className="h-4 w-4" />
  }

  const getLabel = () => {
    if (theme === "light") return "Switch to dark mode"
    if (theme === "dark") return "Switch to system mode"
    return "Switch to light mode"
  }

  return (
    <Button
      variant="outline"
      size="icon"
      onClick={toggleTheme}
      aria-label={getLabel()}
      className="relative"
    >
      {getIcon()}
      <span className="sr-only">{getLabel()}</span>
    </Button>
  )
}
