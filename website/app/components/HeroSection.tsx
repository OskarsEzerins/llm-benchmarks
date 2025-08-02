import type { ReactNode } from 'react'
import { Logo } from './Logo'

interface HeroSectionProps {
  title: string
  subtitle: string
  children?: ReactNode
}

export const HeroSection = ({ title, subtitle, children }: HeroSectionProps) => (
  <div className="border-b-4 border-border bg-background shadow-2xl">
    <div className="container mx-auto px-4 py-12 sm:py-16 lg:py-20 max-w-7xl">
      <div className="text-center max-w-4xl mx-auto">
        <div className="flex flex-col items-center justify-center mb-4">
          <Logo size="lg" className="mb-6" />
        </div>
        <p className="text-lg sm:text-xl lg:text-2xl text-muted-foreground mb-8 font-medium">
          {subtitle}
        </p>
        {children}
      </div>
    </div>
  </div>
)
