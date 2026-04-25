import { Github, Globe, Linkedin, Mail } from 'lucide-react'

export const Footer = () => {
  const currentYear = new Date().getFullYear()
  
  const links = [
    {
      href: 'https://github.com/oskarsezerins',
      icon: Github,
      label: 'GitHub',
      ariaLabel: 'Visit Oskars on GitHub'
    },
    {
      href: 'https://oskarsezerins.site',
      icon: Globe,
      label: 'Website',
      ariaLabel: 'Visit Oskars personal website'
    },
    {
      href: 'https://www.linkedin.com/in/oskars-ezeri%C5%86%C5%A1-9339961a6',
      icon: Linkedin,
      label: 'LinkedIn',
      ariaLabel: 'Connect with Oskars on LinkedIn'
    },
    {
      href: 'mailto:dev@oskarsezerins.site',
      icon: Mail,
      label: 'Email',
      ariaLabel: 'Send email to Oskars'
    }
  ]

  return (
    <footer className="mt-16 border-t-[3px] border-[var(--c-fg)] bg-[var(--c-surface-2)]">
      <div className="mx-auto max-w-[1080px] px-5 py-8">
        <div className="flex flex-col items-center justify-center space-y-6">
          <div className="flex flex-wrap items-center justify-center gap-6">
            {links.map((link) => {
              const Icon = link.icon
              return (
                <a
                  key={link.label}
                  href={link.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={link.ariaLabel}
                  className="flex items-center gap-2 border-2 border-[var(--c-fg)] bg-[var(--c-surface)] px-4 py-2 text-sm font-bold uppercase tracking-[0.05em] text-[var(--c-fg)] transition-colors hover:bg-[var(--c-fg)] hover:text-[var(--c-surface)]"
                >
                  <Icon className="h-4 w-4" />
                  <span className="hidden sm:inline">{link.label}</span>
                </a>
              )
            })}
          </div>

          <div className="text-center">
            <p className="text-sm font-bold uppercase tracking-[0.05em] text-[var(--c-sub)]">
              © {currentYear} Oskars Ezeriņš
            </p>
            <p className="mt-1 text-xs font-medium uppercase tracking-[0.04em] text-[var(--c-dim)]">
              Ruby LLM benchmarks Dashboard
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}
