import type { ReactNode } from 'react'
import { Header } from './header'
import { Footer } from './footer'

interface PageLayoutProps {
  children: ReactNode
}

export const PageLayout = ({ children }: PageLayoutProps) => (
  <div className="flex min-h-screen flex-col bg-[var(--c-bg)] text-[var(--c-fg)]">
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
  <div className="mx-auto max-w-[1080px] px-5 py-8 pb-20">
    {children}
  </div>
)
