import { useCallback, useEffect, useMemo, useState } from 'react'
import type { ModelRanking } from '../types/benchmark'
import { cn } from '../lib/utils'
import { getBaseModelName, getDisplayName, getModelFamily, getVariantLabel } from '../lib/model-names'

const PAGE_SIZE = 50

type RankingsSortField = 'score' | 'success' | 'quality' | 'name'
type SortDirection = 'asc' | 'desc'

interface RankingsTableProps {
  data: ModelRanking[]
  showStats?: boolean
}

interface RankingsStats {
  total: number
  providers: number
  newThisMonth: number
  newThisMonthLabel: string
  latestModel: string
  latestDate: string
}

const dateTime = (date: Date | string): number => {
  if (date instanceof Date) return date.getTime()
  const parsed = new Date(date)
  return Number.isNaN(parsed.getTime()) ? 0 : parsed.getTime()
}

const formatMonth = (date: Date | string): string => {
  if (date instanceof Date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`
  }

  if (/^\d{4}-\d{2}/.test(date)) return date.slice(0, 7)

  const parsed = new Date(date)
  if (Number.isNaN(parsed.getTime())) return '—'

  return `${parsed.getFullYear()}-${String(parsed.getMonth() + 1).padStart(2, '0')}`
}

const scoreClassName = (score: number): string => {
  if (score >= 70) return 'text-[var(--c-score-hi)]'
  if (score >= 50) return 'text-[var(--c-score-mid)]'
  return 'text-[var(--c-score-lo)]'
}

const isLegacyVariant = (variant: string): boolean =>
  variant === '' || variant === 'Default' || variant === 'Legacy Variant'

const formatTokens = (tokens: number): string => new Intl.NumberFormat().format(tokens)

const getProviderName = (model: ModelRanking): string => model.metadata.provider || getModelFamily(model.metadata)

const ProviderBadge = ({ provider }: { provider: string }) => (
  <span className="inline-block whitespace-nowrap border-[1.5px] border-[var(--c-border)] px-1.5 py-0.5 font-mono text-[11px] font-bold uppercase tracking-[0.05em] text-[var(--c-sub)]">
    {provider}
  </span>
)

const Rank = ({ value }: { value: number }) => {
  const isTopThree = value <= 3

  return (
    <div
      className={cn(
        'mx-auto flex h-7 w-7 shrink-0 items-center justify-center font-mono font-extrabold',
        isTopThree
          ? 'bg-[var(--c-accent)] text-white text-sm'
          : 'border-2 border-[var(--c-border)] bg-[var(--c-surface-2)] text-xs text-[var(--c-dim)]',
      )}
    >
      {value}
    </div>
  )
}

const ConfigCell = ({ model }: { model: ModelRanking }) => {
  const [expanded, setExpanded] = useState(false)
  const metadata = model.metadata
  const reasoningEffort = metadata.normalized.reasoning_effort
  const thinkingMode = metadata.normalized.thinking_mode
  const budgetTokens = metadata.normalized.budget_tokens
  const variantLabel = getVariantLabel(metadata)

  const hasEffort = reasoningEffort && reasoningEffort !== 'none' && reasoningEffort !== 'unknown'
  const hasThinking = thinkingMode && thinkingMode !== 'off' && thinkingMode !== 'unknown'
  const hasBudget = typeof budgetTokens === 'number' && budgetTokens > 0
  const hasDetails = hasThinking || hasBudget

  if (!hasEffort && !hasDetails) {
    if (!isLegacyVariant(variantLabel)) {
      return <span className="font-mono text-[11px] text-[var(--c-sub)]">{variantLabel}</span>
    }

    return <span className="text-[11px] text-[var(--c-dim)]">—</span>
  }

  const details = [
    hasEffort ? { label: 'Effort', value: reasoningEffort } : null,
    hasThinking ? { label: 'Thinking', value: thinkingMode } : null,
    hasBudget ? { label: 'Budget', value: `${formatTokens(budgetTokens)} tokens` } : null,
  ].filter((item): item is { label: string; value: string } => item !== null)

  return (
    <span className="relative inline-flex items-center gap-1.5 font-mono text-[11px]">
      {hasEffort && <span className="font-semibold text-[var(--c-fg)]">{reasoningEffort}</span>}
      {hasBudget && (
        <span className="hidden text-[var(--c-sub)] xl:inline">
          · {formatTokens(budgetTokens)} tokens
        </span>
      )}
      {hasDetails && (
        <button
          type="button"
          className={cn(
            'inline-flex h-[18px] w-[18px] items-center justify-center border-[1.5px] border-[var(--c-border)] text-[10px] font-bold transition-colors',
            expanded ? 'bg-[var(--c-surface-2)] text-[var(--c-fg)]' : 'bg-transparent text-[var(--c-dim)]',
          )}
          aria-label={expanded ? 'Hide model configuration' : 'Show model configuration'}
          onClick={(event) => {
            event.stopPropagation()
            setExpanded((current) => !current)
          }}
        >
          {expanded ? '−' : '+'}
        </button>
      )}
      {expanded && (
        <span className="absolute left-0 top-full z-20 mt-1 flex min-w-40 flex-col gap-1 border-2 border-[var(--c-fg)] bg-[var(--c-surface)] px-2.5 py-1.5 shadow-[3px_3px_0_var(--c-fg)]">
          {details.map((detail) => (
            <span key={detail.label} className="flex justify-between gap-3">
              <span className="text-[10px] font-bold uppercase text-[var(--c-dim)]">{detail.label}</span>
              <span className="font-semibold text-[var(--c-fg)]">{detail.value}</span>
            </span>
          ))}
        </span>
      )}
    </span>
  )
}

const Pagination = ({
  currentPage,
  totalPages,
  totalItems,
  onPageChange,
  position,
}: {
  currentPage: number
  totalPages: number
  totalItems: number
  onPageChange: (page: number) => void
  position: 'top' | 'bottom'
}) => {
  const firstItem = totalItems === 0 ? 0 : (currentPage - 1) * PAGE_SIZE + 1
  const lastItem = Math.min(currentPage * PAGE_SIZE, totalItems)

  const pages = useMemo(() => {
    const visible = Math.min(totalPages, 7)
    if (totalPages <= visible) return Array.from({ length: totalPages }, (_, index) => index + 1)

    if (currentPage <= 4) return Array.from({ length: visible }, (_, index) => index + 1)
    if (currentPage >= totalPages - 3) {
      return Array.from({ length: visible }, (_, index) => totalPages - visible + index + 1)
    }

    return Array.from({ length: visible }, (_, index) => currentPage - 3 + index)
  }, [currentPage, totalPages])

  if (totalPages <= 1 && totalItems > 0) {
    return null
  }

  return (
    <div
      className={cn(
        'flex flex-col gap-3 bg-[var(--c-surface-2)] px-4 py-3 sm:flex-row sm:items-center sm:justify-between',
        position === 'top' ? 'border-b-2 border-[var(--c-fg)]' : 'border-t-2 border-[var(--c-fg)]',
      )}
    >
      <span className="font-mono text-[11px] font-semibold text-[var(--c-dim)]">
        {firstItem}–{lastItem} of {totalItems}
      </span>
      <div className="flex min-w-0 overflow-x-auto">
        <button
          type="button"
          className="border-2 border-r border-[var(--c-fg)] bg-[var(--c-surface)] px-3.5 py-1.5 font-mono text-[11px] font-bold text-[var(--c-fg)] disabled:cursor-not-allowed disabled:bg-[var(--c-surface-2)] disabled:text-[var(--c-dim)]"
          disabled={currentPage === 1}
          onClick={() => onPageChange(Math.max(1, currentPage - 1))}
        >
          Prev
        </button>
        {pages.map((pageNumber) => (
          <button
            type="button"
            key={pageNumber}
            className={cn(
              'border-2 border-r border-l-0 border-[var(--c-fg)] px-3 py-1.5 font-mono text-[11px] font-bold',
              currentPage === pageNumber
                ? 'bg-[var(--c-fg)] text-[var(--c-surface)]'
                : 'bg-[var(--c-surface)] text-[var(--c-fg)]',
            )}
            onClick={() => onPageChange(pageNumber)}
          >
            {pageNumber}
          </button>
        ))}
        <button
          type="button"
          className="border-2 border-l-0 border-[var(--c-fg)] bg-[var(--c-surface)] px-3.5 py-1.5 font-mono text-[11px] font-bold text-[var(--c-fg)] disabled:cursor-not-allowed disabled:bg-[var(--c-surface-2)] disabled:text-[var(--c-dim)]"
          disabled={currentPage === totalPages || totalPages === 0}
          onClick={() => onPageChange(Math.min(totalPages, currentPage + 1))}
        >
          Next
        </button>
      </div>
    </div>
  )
}

export const RankingsTable = ({ data, showStats = true }: RankingsTableProps) => {
  const [searchTerm, setSearchTerm] = useState('')
  const [providerFilter, setProviderFilter] = useState<Set<string>>(new Set())
  const [selectedModels, setSelectedModels] = useState<Set<string>>(new Set())
  const [showSelectedOnly, setShowSelectedOnly] = useState(false)
  const [sortField, setSortField] = useState<RankingsSortField>('score')
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc')
  const [page, setPage] = useState(1)

  const providers = useMemo(() => {
    return Array.from(new Set(data.map((model) => getProviderName(model)))).sort()
  }, [data])

  const rankByImplementation = useMemo(() => {
    return new Map(data.map((model, index) => [model.implementation, index + 1]))
  }, [data])

  const stats = useMemo<RankingsStats>(() => {
    if (data.length === 0) {
      return {
        total: 0,
        providers: 0,
        newThisMonth: 0,
        newThisMonthLabel: 'models added',
        latestModel: '—',
        latestDate: '',
      }
    }

    const providerScores = data.reduce<Record<string, number[]>>((scores, model) => {
      const provider = getProviderName(model)
      scores[provider] ||= []
      scores[provider].push(model.score)
      return scores
    }, {})

    const latest = [...data].sort((a, b) => dateTime(b.date) - dateTime(a.date))[0]
    const latestMonth = latest ? formatMonth(latest.date) : ''
    const newThisMonth = latestMonth
      ? data.filter((model) => formatMonth(model.date) === latestMonth).length
      : 0

    return {
      total: data.length,
      providers: Object.keys(providerScores).length,
      newThisMonth,
      newThisMonthLabel: `${newThisMonth === 1 ? 'model' : 'models'} added`,
      latestModel: latest ? getBaseModelName(latest.implementation, latest.metadata) : '—',
      latestDate: latest ? formatMonth(latest.date) : '',
    }
  }, [data])

  const sortedAndFiltered = useMemo(() => {
    let filtered = data

    if (searchTerm.trim()) {
      const search = searchTerm.toLowerCase().trim()
      filtered = filtered.filter((model) => {
        const provider = getProviderName(model)
        const family = getModelFamily(model.metadata)
        const baseName = getBaseModelName(model.implementation, model.metadata)
        const displayName = getDisplayName(model.implementation, model.metadata)
        const variantLabel = getVariantLabel(model.metadata)

        return (
          displayName.toLowerCase().includes(search) ||
          baseName.toLowerCase().includes(search) ||
          variantLabel.toLowerCase().includes(search) ||
          provider.toLowerCase().includes(search) ||
          family.toLowerCase().includes(search) ||
          model.implementation.toLowerCase().includes(search)
        )
      })
    }

    if (providerFilter.size > 0) {
      filtered = filtered.filter((model) => providerFilter.has(getProviderName(model)))
    }

    if (showSelectedOnly && selectedModels.size > 0) {
      filtered = filtered.filter((model) => selectedModels.has(model.implementation))
    }

    return [...filtered].sort((a, b) => {
      if (sortField === 'name') {
        const aName = getBaseModelName(a.implementation, a.metadata)
        const bName = getBaseModelName(b.implementation, b.metadata)
        return sortDirection === 'asc' ? aName.localeCompare(bName) : bName.localeCompare(aName)
      }

      const aValue = sortField === 'score' ? a.score : sortField === 'success' ? a.success_rate : a.quality_score
      const bValue = sortField === 'score' ? b.score : sortField === 'success' ? b.success_rate : b.quality_score

      return sortDirection === 'asc' ? aValue - bValue : bValue - aValue
    })
  }, [data, providerFilter, searchTerm, selectedModels, showSelectedOnly, sortDirection, sortField])

  const totalPages = Math.ceil(sortedAndFiltered.length / PAGE_SIZE)
  const paginated = useMemo(
    () => sortedAndFiltered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE),
    [page, sortedAndFiltered],
  )

  useEffect(() => {
    setPage(1)
  }, [providerFilter, searchTerm, selectedModels, showSelectedOnly, sortDirection, sortField])

  const handleSort = (field: RankingsSortField) => {
    if (sortField === field) {
      setSortDirection((current) => (current === 'desc' ? 'asc' : 'desc'))
    } else {
      setSortField(field)
      setSortDirection(field === 'name' ? 'asc' : 'desc')
    }
  }

  const toggleModel = useCallback((implementation: string) => {
    setSelectedModels((current) => {
      const next = new Set(current)
      if (next.has(implementation)) {
        next.delete(implementation)
      } else {
        next.add(implementation)
      }
      return next
    })
  }, [])

  const clearAll = () => {
    setProviderFilter(new Set())
    setSelectedModels(new Set())
    setShowSelectedOnly(false)
  }

  const SortHeader = ({
    field,
    children,
    className,
    align = 'center',
  }: {
    field: RankingsSortField
    children: string
    className?: string
    align?: 'left' | 'center'
  }) => (
    <th
      className={cn(
        'cursor-pointer select-none whitespace-nowrap border-b-[3px] border-[var(--c-fg)] bg-[var(--c-surface-2)] px-3.5 py-3 font-sans text-[10px] font-extrabold uppercase tracking-[0.1em] text-[var(--c-dim)]',
        align === 'left' ? 'text-left' : 'text-center',
        className,
      )}
      onClick={() => handleSort(field)}
    >
      {children}
      {sortField === field ? (sortDirection === 'desc' ? ' ↓' : ' ↑') : ''}
    </th>
  )

  const isSameGroup = (model: ModelRanking, index: number) => {
    if (index === 0) return false
    const previous = paginated[index - 1]

    return (
      previous.metadata.base_model_name === model.metadata.base_model_name &&
      previous.metadata.provider === model.metadata.provider
    )
  }

  return (
    <div>
      {showStats && (
        <div className="mb-7 grid border-[3px] border-[var(--c-fg)] bg-[var(--c-surface)] shadow-[4px_4px_0_var(--c-fg)] sm:grid-cols-2 lg:grid-cols-4">
          {[
            { label: 'Models Tested', value: stats.total, numeric: true },
            { label: 'Providers', value: stats.providers, numeric: true },
            { label: 'New This Month', value: stats.newThisMonth, sub: stats.newThisMonthLabel, numeric: true },
            { label: 'Latest Added', value: stats.latestModel, sub: stats.latestDate },
          ].map((item, index) => (
            <div
              key={item.label}
              className={cn(
                'border-[var(--c-fg)] px-4 py-3 text-center',
                index < 3 ? 'border-b-2' : '',
                index % 2 === 0 ? 'sm:border-r-2' : '',
                index < 2 ? 'sm:border-b-2' : 'sm:border-b-0',
                index < 3 ? 'lg:border-r-2' : 'lg:border-r-0',
                'lg:border-b-0',
              )}
            >
              <div className="mb-1 font-mono text-[10px] font-bold uppercase tracking-[0.1em] text-[var(--c-dim)]">
                {item.label}
              </div>
              <div
                className={cn(
                  'break-words font-extrabold text-[var(--c-fg)]',
                  item.numeric ? 'font-mono text-[22px]' : 'font-sans text-base',
                )}
              >
                {item.value || '—'}
              </div>
              {item.sub ? <div className="mt-0.5 font-mono text-[10px] text-[var(--c-sub)]">{item.sub}</div> : null}
            </div>
          ))}
        </div>
      )}

      <div className="mb-4 flex flex-col gap-2.5">
        <div className="flex flex-wrap items-center gap-2">
          <input
            type="text"
            placeholder="Search models..."
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.target.value)}
            className="max-w-[300px] flex-[1_1_220px] border-2 border-[var(--c-fg)] bg-[var(--c-surface)] px-3 py-2 text-[13px] text-[var(--c-fg)] outline-none placeholder:text-[var(--c-dim)]"
          />
          {selectedModels.size > 0 && (
            <button
              type="button"
              onClick={() => setShowSelectedOnly((current) => !current)}
              className={cn(
                'border-2 border-[var(--c-fg)] px-3 py-1.5 font-mono text-[11px] font-bold uppercase tracking-[0.05em]',
                showSelectedOnly
                  ? 'bg-[var(--c-fg)] text-[var(--c-surface)]'
                  : 'bg-[var(--c-surface)] text-[var(--c-fg)]',
              )}
            >
              Show {selectedModels.size} selected
            </button>
          )}
          {(providerFilter.size > 0 || selectedModels.size > 0) && (
            <button
              type="button"
              onClick={clearAll}
              className="border-2 border-[var(--c-border)] bg-[var(--c-surface)] px-3 py-1.5 font-mono text-[11px] font-bold uppercase tracking-[0.05em] text-[var(--c-sub)]"
            >
              Clear all
            </button>
          )}
          <span className="ml-auto font-mono text-xs font-semibold text-[var(--c-dim)]">
            {sortedAndFiltered.length} models
          </span>
        </div>

        <div
          className={cn(
            'flex flex-wrap gap-1 transition-opacity',
            showSelectedOnly ? 'pointer-events-none opacity-35' : 'opacity-100',
          )}
        >
          {providers.map((provider) => {
            const active = providerFilter.has(provider)

            return (
              <button
                type="button"
                key={provider}
                onClick={() => {
                  setProviderFilter((current) => {
                    const next = new Set(current)
                    if (active) {
                      next.delete(provider)
                    } else {
                      next.add(provider)
                    }
                    return next
                  })
                }}
                className={cn(
                  'px-2.5 py-1 font-mono text-[11px] font-bold uppercase tracking-[0.04em] transition-colors',
                  active
                    ? 'border-2 border-[var(--c-fg)] bg-[var(--c-fg)] text-[var(--c-surface)]'
                    : 'border-[1.5px] border-[var(--c-border)] bg-[var(--c-surface)] text-[var(--c-sub)]',
                )}
              >
                {provider}
              </button>
            )
          })}
        </div>
      </div>

      <div className="overflow-hidden border-[3px] border-[var(--c-fg)] bg-[var(--c-surface)] shadow-[4px_4px_0_var(--c-fg)]">
        <Pagination
          currentPage={page}
          totalPages={totalPages}
          totalItems={sortedAndFiltered.length}
          position="top"
          onPageChange={setPage}
        />

        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead>
              <tr>
                <th className="w-10 border-b-[3px] border-[var(--c-fg)] bg-[var(--c-surface-2)] px-2 py-3 font-mono text-[10px] font-bold uppercase tracking-[0.08em] text-[var(--c-dim)]">
                  Sel
                </th>
                <th className="w-11 border-b-[3px] border-[var(--c-fg)] bg-[var(--c-surface-2)] px-2 py-3 font-sans text-[10px] font-extrabold uppercase tracking-[0.1em] text-[var(--c-dim)]">
                  #
                </th>
                <SortHeader field="name" align="left">
                  Model
                </SortHeader>
                <th className="hidden border-b-[3px] border-[var(--c-fg)] bg-[var(--c-surface-2)] px-3.5 py-3 font-sans text-[10px] font-extrabold uppercase tracking-[0.1em] text-[var(--c-dim)] min-[860px]:table-cell">
                  Config
                </th>
                <SortHeader field="score">Score</SortHeader>
                <SortHeader field="success">Success</SortHeader>
                <SortHeader field="quality" className="hidden min-[640px]:table-cell">
                  Quality
                </SortHeader>
                <th className="hidden border-b-[3px] border-[var(--c-fg)] bg-[var(--c-surface-2)] px-3.5 py-3 text-center font-sans text-[10px] font-extrabold uppercase tracking-[0.1em] text-[var(--c-dim)] min-[640px]:table-cell">
                  Date
                </th>
              </tr>
            </thead>
            <tbody>
              {paginated.map((model, index) => {
                const sameGroup = isSameGroup(model, index)
                const selected = selectedModels.has(model.implementation)
                const provider = getProviderName(model)
                const baseName = getBaseModelName(model.implementation, model.metadata)
                const overallRank = rankByImplementation.get(model.implementation) ?? 0

                return (
                  <tr
                    key={model.implementation}
                    className={cn(
                      'cursor-pointer transition-colors hover:bg-[var(--c-hover)]',
                      sameGroup ? 'border-t border-dashed border-[var(--c-border-light)] bg-[var(--c-surface-2)]' : '',
                      !sameGroup && index > 0 ? 'border-t border-[var(--c-border)]' : '',
                      selected ? 'bg-[var(--c-selected)]' : '',
                    )}
                    onClick={() => toggleModel(model.implementation)}
                  >
                    <td className="px-2 py-2.5 text-center">
                      <input
                        type="checkbox"
                        checked={selected}
                        className="h-[15px] w-[15px] cursor-pointer accent-[var(--c-accent)]"
                        onChange={() => toggleModel(model.implementation)}
                        onClick={(event) => event.stopPropagation()}
                        aria-label={`Select ${baseName}`}
                      />
                    </td>
                    <td className="px-2 py-2.5 text-center">
                      <Rank value={overallRank} />
                    </td>
                    <td className="px-3.5 py-2.5">
                      <div className="flex min-w-52 flex-col gap-1.5">
                        <div className="flex items-center gap-2">
                          {sameGroup ? (
                            <span className="text-[13px] text-[var(--c-sub)]">↳ {baseName}</span>
                          ) : (
                            <span className="text-sm font-bold text-[var(--c-fg)]">{baseName}</span>
                          )}
                          {!sameGroup && <ProviderBadge provider={provider} />}
                        </div>
                        <div className="flex items-center gap-1.5 font-mono text-[10px] text-[var(--c-dim)] min-[860px]:hidden">
                          <span className="font-bold uppercase tracking-[0.08em]">Config</span>
                          <ConfigCell model={model} />
                        </div>
                      </div>
                    </td>
                    <td className="hidden px-3.5 py-2.5 min-[860px]:table-cell">
                      <ConfigCell model={model} />
                    </td>
                    <td className={cn('px-3.5 py-2.5 text-center font-mono text-[15px] font-bold', scoreClassName(model.score))}>
                      {model.score.toFixed(1)}
                    </td>
                    <td className="px-3.5 py-2.5 text-center font-mono text-[13px] font-semibold text-[var(--c-fg)]">
                      {(model.success_rate * 100).toFixed(1)}%
                    </td>
                    <td className="hidden px-3.5 py-2.5 text-center font-mono text-[13px] text-[var(--c-fg)] min-[640px]:table-cell">
                      {model.quality_score.toFixed(0)}
                    </td>
                    <td className="hidden px-3.5 py-2.5 text-center font-mono text-xs text-[var(--c-sub)] min-[640px]:table-cell">
                      {formatMonth(model.date)}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>

        <Pagination
          currentPage={page}
          totalPages={totalPages}
          totalItems={sortedAndFiltered.length}
          position="bottom"
          onPageChange={setPage}
        />

        {sortedAndFiltered.length === 0 && (
          <div className="px-4 py-12 text-center font-mono text-sm font-semibold text-[var(--c-dim)]">
            No models found.
          </div>
        )}
      </div>
    </div>
  )
}
