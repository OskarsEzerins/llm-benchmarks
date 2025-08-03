import React, { useState, useMemo } from 'react'
import type { ModelRanking, BenchmarkType } from '../types/benchmark'
import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { Badge } from './ui/badge'
import { Button } from './ui/button'
import { ChevronUp, ChevronDown, Search, Filter } from 'lucide-react'
import { formatDateShort } from '../lib/data'
import { normalizeModelName, getModelFamily } from '../lib/model-name-utils'

interface DataTableProps {
  data: ModelRanking[]
  allData?: Record<BenchmarkType, any>
  title?: string
}

type SortField = 'implementation' | 'score' | 'success_rate' | 'quality_score' | 'date'
type SortDirection = 'asc' | 'desc'

const getScoreColor = (score: number): string => {
  if (score >= 80) return 'bg-emerald-500 text-white dark:bg-emerald-600 dark:text-white shadow-md border-emerald-600 dark:border-emerald-400'
  if (score >= 60) return 'bg-blue-500 text-white dark:bg-blue-600 dark:text-white shadow-md border-blue-600 dark:border-blue-400'
  if (score >= 40) return 'bg-amber-500 text-white dark:bg-amber-600 dark:text-white shadow-md border-amber-600 dark:border-amber-400'
  return 'bg-red-500 text-white dark:bg-red-600 dark:text-white shadow-md border-red-600 dark:border-red-400'
}

const getSuccessRateColor = (rate: number): string => {
  if (rate >= 0.9) return 'text-emerald-600 dark:text-emerald-400 font-bold text-sm'
  if (rate >= 0.7) return 'text-blue-600 dark:text-blue-400 font-bold text-sm'
  if (rate >= 0.5) return 'text-amber-600 dark:text-amber-400 font-bold text-sm'
  return 'text-red-600 dark:text-red-400 font-bold text-sm'
}

export const DataTable: React.FC<DataTableProps> = ({
  data,
  allData = {},
  title = "All Models Performance"
}) => {
  const [sortField, setSortField] = useState<SortField>('score')
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc')
  const [searchTerm, setSearchTerm] = useState('')
  const [familyFilter, setFamilyFilter] = useState<string>('all')

  const modelFamilies = useMemo(() => {
    const families = new Set(data.map(model => getModelFamily(model.implementation)))
    return Array.from(families).sort()
  }, [data])

  const sortedAndFilteredData = useMemo(() => {
    let filtered = data

    // Apply search filter
    if (searchTerm) {
      filtered = filtered.filter(model =>
        normalizeModelName(model.implementation).toLowerCase().includes(searchTerm.toLowerCase()) ||
        model.implementation.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }

    // Apply family filter
    if (familyFilter !== 'all') {
      filtered = filtered.filter(model => getModelFamily(model.implementation) === familyFilter)
    }

    // Apply sorting
    return filtered.sort((a, b) => {
      let aValue: number | string | Date = a[sortField]
      let bValue: number | string | Date = b[sortField]

      if (sortField === 'implementation') {
        aValue = normalizeModelName(a.implementation)
        bValue = normalizeModelName(b.implementation)
      }

      if (sortField === 'date') {
        aValue = a.date.getTime()
        bValue = b.date.getTime()
      }

      if (typeof aValue === 'string' && typeof bValue === 'string') {
        return sortDirection === 'asc'
          ? aValue.localeCompare(bValue)
          : bValue.localeCompare(aValue)
      }

      return sortDirection === 'asc'
        ? (aValue as number) - (bValue as number)
        : (bValue as number) - (aValue as number)
    })
  }, [data, sortField, sortDirection, searchTerm, familyFilter])

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDirection(field === 'implementation' ? 'asc' : 'desc')
    }
  }

  const SortButton: React.FC<{ field: SortField; children: React.ReactNode; className?: string }> = ({
    field,
    children,
    className = ""
  }) => (
    <Button
      variant="ghost"
      size="sm"
      onClick={() => handleSort(field)}
      className={`justify-start h-auto p-1 text-left font-medium ${className}`}
    >
      {children}
      {sortField === field && (
        sortDirection === 'asc' ? <ChevronUp className="h-4 w-4 ml-1" /> : <ChevronDown className="h-4 w-4 ml-1" />
      )}
    </Button>
  )

  return (
    <Card className="border-0 shadow-lg">
      <CardHeader className="pb-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <CardTitle className="text-2xl font-bold">{title}</CardTitle>
          <div className="flex flex-col sm:flex-row gap-3">
            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <input
                type="text"
                placeholder="Search models..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9 pr-3 py-2 border-2 border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent shadow-lg"
              />
            </div>
            {/* Family Filter */}
            <div className="relative">
              <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <select
                value={familyFilter}
                onChange={(e) => setFamilyFilter(e.target.value)}
                className="pl-9 pr-8 py-2 border-2 border-border bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent appearance-none shadow-lg"
              >
                <option value="all">All Families</option>
                {modelFamilies.map(family => (
                  <option key={family} value={family}>{family}</option>
                ))}
              </select>
            </div>
          </div>
        </div>
        <div className="text-sm text-muted-foreground">
          Showing {sortedAndFilteredData.length} of {data.length} models
        </div>
      </CardHeader>

      <CardContent className="p-0">
        <div className="overflow-x-auto">
          <table className="w-full max-w-7xl">
            <thead>
              <tr className="border-b border-border">
                <th className="text-left p-3 font-medium w-32 lg:w-40">
                  <SortButton field="implementation">Model</SortButton>
                </th>
                <th className="text-left p-3 font-medium hidden sm:table-cell w-12">Family</th>
                <th className="text-left p-3 font-medium hidden md:table-cell w-14">
                  <SortButton field="date">Date</SortButton>
                </th>
                <th className="text-center p-3 font-medium w-12">
                  <SortButton field="score">Score</SortButton>
                </th>
                <th className="text-center p-3 font-medium w-14">
                  <SortButton field="success_rate" className="flex-row-reverse">Success Rate</SortButton>
                </th>
                <th className="text-center p-3 font-medium hidden lg:table-cell w-16">
                  <SortButton field="quality_score" className="flex-row-reverse">Quality Score</SortButton>
                </th>
              </tr>
            </thead>
            <tbody>
              {sortedAndFilteredData.map((model, index) => (
                <tr key={model.implementation} className="border-b border-border/50 hover:bg-muted/50 transition-colors">
                  <td className="p-3 w-32 lg:w-40">
                    <div className="flex items-center gap-2">
                      <div className="flex-shrink-0 w-6 h-6 bg-primary/10 border-2 border-primary/20 flex items-center justify-center text-xs font-medium text-primary">
                        {sortedAndFilteredData.findIndex(m => m.implementation === model.implementation) + 1}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="font-medium text-foreground text-sm truncate">
                          {normalizeModelName(model.implementation)}
                        </div>
                        <div className="text-xs text-muted-foreground sm:hidden truncate">
                          {getModelFamily(model.implementation)} • {formatDateShort(model.date)}
                        </div>
                        <div className="text-xs text-muted-foreground md:hidden sm:block truncate">
                          {formatDateShort(model.date)}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="p-3 hidden sm:table-cell w-12">
                    <Badge variant="outline" className="text-xs px-1 py-0.5">
                      {getModelFamily(model.implementation)}
                    </Badge>
                  </td>
                  <td className="p-3 hidden md:table-cell w-14">
                    <div className="text-sm text-foreground">
                      <div className="font-medium text-xs">{formatDateShort(model.date)}</div>
                    </div>
                  </td>
                  <td className="p-3 text-center w-12">
                    <Badge className={`text-sm font-bold px-2 py-1 border-2 ${getScoreColor(model.score)}`}>
                      {model.score.toFixed(1)}
                    </Badge>
                  </td>
                  <td className="p-3 text-center w-14">
                    <span className={getSuccessRateColor(model.success_rate)}>
                      {(model.success_rate * 100).toFixed(1)}%
                    </span>
                  </td>
                  <td className="p-3 text-center hidden lg:table-cell w-16">
                    <span className={getSuccessRateColor(model.quality_score / 100)}>
                      {(model.quality_score).toFixed(1)}%
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {sortedAndFilteredData.length === 0 && (
          <div className="text-center py-12 text-muted-foreground">
            <Search className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p className="text-lg">No models found matching your criteria</p>
            <p className="text-sm">Try adjusting your search or filter settings</p>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
