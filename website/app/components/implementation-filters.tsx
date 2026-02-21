import { Search, X } from 'lucide-react'
import { Button } from './ui/button'
import { formatLabel } from '../lib/utils'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select'

interface ImplementationFiltersProps {
  types: string[]
  tasks: string[]
  families: string[]
  selectedType: string
  selectedTask: string
  selectedFamily: string
  searchTerm: string
  onTypeChange: (value: string) => void
  onTaskChange: (value: string) => void
  onFamilyChange: (value: string) => void
  onSearchChange: (value: string) => void
  onClear: () => void
  hasActiveFilters: boolean
}

export const ImplementationFilters = ({
  types,
  tasks,
  families,
  selectedType,
  selectedTask,
  selectedFamily,
  searchTerm,
  onTypeChange,
  onTaskChange,
  onFamilyChange,
  onSearchChange,
  onClear,
  hasActiveFilters,
}: ImplementationFiltersProps) => (
  <div className="space-y-4">
    {/* Mobile: toggle is handled by parent via collapsible */}
    <div className="flex flex-col sm:flex-row gap-3">
      <Select value={selectedType} onValueChange={onTypeChange}>
        <SelectTrigger className="w-full sm:w-[180px]">
          <SelectValue placeholder="All Types" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">All Types</SelectItem>
          {types.map(type => (
            <SelectItem key={type} value={type}>{formatLabel(type)}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select value={selectedTask} onValueChange={onTaskChange}>
        <SelectTrigger className="w-full sm:w-[180px]">
          <SelectValue placeholder="All Tasks" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">All Tasks</SelectItem>
          {tasks.map(task => (
            <SelectItem key={task} value={task}>{formatLabel(task)}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select value={selectedFamily} onValueChange={onFamilyChange}>
        <SelectTrigger className="w-full sm:w-[180px]">
          <SelectValue placeholder="All Families" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">All Families</SelectItem>
          {families.map(family => (
            <SelectItem key={family} value={family}>{family}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <div className="relative flex-1 min-w-0">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <input
          type="text"
          placeholder="Search models..."
          aria-label="Search models"
          value={searchTerm}
          onChange={(e) => onSearchChange(e.target.value)}
          className="w-full pl-9 pr-3 py-2 h-9 border border-input bg-transparent rounded-md text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent"
        />
      </div>

      {hasActiveFilters && (
        <Button variant="ghost" size="sm" onClick={onClear} className="h-9 px-3">
          <X className="h-4 w-4 mr-1" />
          Clear
        </Button>
      )}
    </div>
  </div>
)
