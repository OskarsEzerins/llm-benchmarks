import type { ReactNode } from 'react'
import { Badge } from './ui/badge'

interface SectionHeaderProps {
  icon: ReactNode
  title: string
  badge?: {
    text: string
    variant?: "default" | "secondary" | "destructive" | "outline"
  }
}

export const SectionHeader = ({ icon, title, badge }: SectionHeaderProps) => (
  <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-3 mb-4 sm:mb-6">
    <div className="flex items-center gap-2 sm:gap-3">
      {icon}
      <h2 className="text-xl sm:text-2xl lg:text-3xl font-bold text-foreground break-words">
        {title}
      </h2>
    </div>
    {badge && (
      <Badge variant={badge.variant || "secondary"} className="self-start sm:self-auto">
        {badge.text}
      </Badge>
    )}
  </div>
)
