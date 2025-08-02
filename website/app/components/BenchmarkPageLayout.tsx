import type { ReactNode } from 'react'
import { Separator } from './ui/separator'
import { PageLayout, PageContent } from './PageLayout'

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
  children: ReactNode[]
}

export const BenchmarkPageContent = ({ children }: BenchmarkPageContentProps) => (
  <>
    {children.map((child, index) => (
      <div key={index}>
        {child}
        {index < children.length - 1 && <Separator />}
      </div>
    ))}
  </>
)
