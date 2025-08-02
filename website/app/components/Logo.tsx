import { cn } from "../lib/utils"

interface LogoProps {
  className?: string
  variant?: "full" | "icon"
  size?: "sm" | "md" | "lg"
}

export const Logo = ({ className, variant = "full", size = "md" }: LogoProps) => {
  const sizeClasses = {
    sm: {
      icon: "h-6 w-6",
      text: "text-lg",
      container: "gap-2"
    },
    md: {
      icon: "h-8 w-8",
      text: "text-xl",
      container: "gap-2"
    },
    lg: {
      icon: "h-12 w-12",
      text: "text-4xl",
      container: "gap-3"
    }
  }

  const sizes = sizeClasses[size]

  return (
    <div className={cn("flex items-center", sizes.container, className)}>
      {/* Logo Icon */}
      <div className={cn(
        "rounded-xl bg-gradient-to-br from-blue-500 via-indigo-600 to-purple-600 flex items-center justify-center shadow-lg",
        sizes.icon
      )}>
        {/* Benchmark chart icon */}
        <svg
          viewBox="0 0 24 24"
          fill="none"
          className="w-2/3 h-2/3 text-white"
        >
          <path
            d="M3 17h4V10H3v7zm6 0h4V7H9v10zm6 0h4V4h-4v13z"
            fill="currentColor"
          />
          <circle cx="5" cy="8" r="1" fill="currentColor" opacity="0.7" />
          <circle cx="11" cy="5" r="1" fill="currentColor" opacity="0.7" />
          <circle cx="17" cy="2" r="1" fill="currentColor" opacity="0.7" />
        </svg>
      </div>

      {/* Logo Text */}
      {variant === "full" && (
        <div className="flex flex-col leading-tight">
          <span className={cn(
            "font-bold bg-gradient-to-r from-slate-900 via-blue-800 to-indigo-900 dark:from-slate-100 dark:via-blue-200 dark:to-indigo-200 bg-clip-text text-transparent",
            sizes.text
          )}>
            Ruby LLM benchmarks
          </span>
          {size === "lg" && (
            <span className="text-sm text-muted-foreground font-medium -mt-1">
              AI Model Performance Dashboard
            </span>
          )}
        </div>
      )}
    </div>
  )
}