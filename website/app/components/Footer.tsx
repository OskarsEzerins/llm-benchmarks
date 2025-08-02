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
    <footer className="border-t-4 border-slate-800 dark:border-slate-300 bg-slate-100 dark:bg-slate-900 mt-16">
      <div className="container mx-auto px-4 py-8 max-w-7xl">
        <div className="flex flex-col items-center justify-center space-y-6">
          {/* Links Section */}
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
                  className="group flex items-center gap-2 px-4 py-2 rounded-lg border-2 border-slate-800 dark:border-slate-300 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-300 font-bold uppercase tracking-wider text-sm transition-all duration-200 hover:translate-x-1 hover:translate-y-1 hover:shadow-lg hover:bg-slate-50 dark:hover:bg-slate-700"
                >
                  <Icon className="h-4 w-4" />
                  <span className="hidden sm:inline">{link.label}</span>
                </a>
              )
            })}
          </div>

          {/* Copyright Section */}
          <div className="text-center">
            <p className="text-sm font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400">
              © {currentYear} Oskars Ezeriņš
            </p>
            <p className="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-500 mt-1">
              Ruby LLM benchmarks Dashboard
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}