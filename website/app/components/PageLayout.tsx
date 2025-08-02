import type { ReactNode } from 'react'
import { Header } from './Header'
import { Footer } from './Footer'

interface PageLayoutProps {
  children: ReactNode
}

export const PageLayout = ({ children }: PageLayoutProps) => (
  <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-indigo-50/20 dark:from-slate-950 dark:via-slate-900 dark:to-slate-900 flex flex-col">
    <Header />
    <main className="flex-1">
      {children}
    </main>
    <Footer />
  </div>
)

interface PageContentProps {
  children: ReactNode
}

export const PageContent = ({ children }: PageContentProps) => (
  <div className="container mx-auto px-4 py-8 max-w-7xl space-y-12">
    {children}
  </div>
)
