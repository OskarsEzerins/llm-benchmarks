import { Link } from 'react-router'
import { ChevronLeft, ChevronRight } from 'lucide-react'

interface BreadcrumbItem {
  label: string
  href?: string
}

interface BreadcrumbsProps {
  items: BreadcrumbItem[]
  showBackButton?: boolean
  backButtonLabel?: string
}

export const Breadcrumbs = ({ 
  items, 
  showBackButton = false, 
  backButtonLabel = "Back to Overall Rankings" 
}: BreadcrumbsProps) => {
  const backHref = items.length > 1 ? items[0].href || '/' : '/'

  return (
    <nav className="flex items-center gap-2 text-sm text-muted-foreground mb-6">
      {showBackButton && (
        <Link
          to={backHref}
          className="flex items-center gap-1 hover:text-foreground transition-colors"
        >
          <ChevronLeft className="h-4 w-4" />
          {backButtonLabel}
        </Link>
      )}
      
      {!showBackButton && items.length > 0 && (
        <div className="flex items-center gap-2">
          {items.map((item, index) => (
            <div key={index} className="flex items-center gap-2">
              {index > 0 && <ChevronRight className="h-3 w-3" />}
              {item.href && index < items.length - 1 ? (
                <Link
                  to={item.href}
                  className="hover:text-foreground transition-colors"
                >
                  {item.label}
                </Link>
              ) : (
                <span className={index === items.length - 1 ? "text-foreground font-medium" : ""}>
                  {item.label}
                </span>
              )}
            </div>
          ))}
        </div>
      )}
    </nav>
  )
}