import type { ReactNode } from 'react'
import { PageLayout, PageContent } from './page-layout'

interface BenchmarkPageLayoutProps {
  header: ReactNode
  children: ReactNode
}

export const BenchmarkPageLayout = ({ header, children }: BenchmarkPageLayoutProps) => (
  <PageLayout>
    {header}
    <PageContent>
      {children}
    </PageContent>
  </PageLayout>
)

interface BenchmarkPageContentProps {
  children: ReactNode
}

export const BenchmarkPageContent = ({ children }: BenchmarkPageContentProps) => (
  <>{children}</>
)
