import { useState, useMemo, useCallback } from 'react'
import { ArrowLeftRight, ChevronDown, Check } from 'lucide-react'
import { Button } from './ui/button'
import { Popover, PopoverContent, PopoverTrigger } from './ui/popover'
import { Command, CommandEmpty, CommandInput, CommandItem, CommandList } from './ui/command'
import { normalizeModelName } from '../lib/model-name-utils'
import { formatLabel } from '../lib/utils'
import type { CompareItem, ImplementationEntry } from '../types/benchmark'

interface ComparisonControlsProps {
  items: CompareItem[]
  allImplementations: ImplementationEntry[]
  onItemsChange: (items: CompareItem[]) => void
}

// Returns the set of tasks where both models have an implementation of the same type
const computeSharedTasks = (
  items: CompareItem[],
  allImplementations: ImplementationEntry[],
): string[] => {
  if (items.length !== 2) return []
  const [a, b] = items
  if (a.type !== b.type) return []

  const tasksForA = new Set(
    allImplementations
      .filter(i => i.type === a.type && i.model === a.model)
      .map(i => i.task),
  )
  const tasksForB = new Set(
    allImplementations
      .filter(i => i.type === b.type && i.model === b.model)
      .map(i => i.task),
  )

  return [...tasksForA].filter(t => tasksForB.has(t)).sort()
}

interface ModelSelectorProps {
  label: string
  currentItem: CompareItem
  allImplementations: ImplementationEntry[]
  onSelect: (model: string) => void
}

const ModelSelector = ({ label, currentItem, allImplementations, onSelect }: ModelSelectorProps) => {
  const [open, setOpen] = useState(false)

  // Models available for the same type+task as the current item
  const candidates = useMemo(
    () =>
      allImplementations.filter(
        i => i.type === currentItem.type && i.task === currentItem.task,
      ),
    [allImplementations, currentItem.type, currentItem.task],
  )

  const handleSelect = useCallback(
    (model: string) => {
      onSelect(model)
      setOpen(false)
    },
    [onSelect],
  )

  const displayName = normalizeModelName(currentItem.model)

  return (
    <div className="flex-1 min-w-0">
      <span className="block text-[10px] font-semibold uppercase tracking-wider text-muted-foreground mb-1">
        {label}
      </span>
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <button
            type="button"
            aria-haspopup="listbox"
            aria-expanded={open}
            className="w-full flex items-center justify-between gap-2 px-3 py-1.5 h-9 rounded-md border border-input bg-background text-sm hover:bg-accent hover:text-accent-foreground transition-colors text-left focus:outline-none focus:ring-2 focus:ring-ring"
          >
            <span className="truncate font-medium">{displayName}</span>
            <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
          </button>
        </PopoverTrigger>
        <PopoverContent className="w-[280px] p-0" align="start">
          <Command>
            <CommandInput placeholder="Search models..." />
            <CommandList>
              <CommandEmpty>No models found.</CommandEmpty>
              {candidates.map(i => (
                <CommandItem
                  key={i.model}
                  value={normalizeModelName(i.model)}
                  onSelect={() => handleSelect(i.model)}
                  className="cursor-pointer"
                >
                  <Check
                    className={`mr-2 h-4 w-4 shrink-0 ${i.model === currentItem.model ? 'opacity-100' : 'opacity-0'}`}
                  />
                  {normalizeModelName(i.model)}
                </CommandItem>
              ))}
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>
    </div>
  )
}

export const ComparisonControls = ({ items, allImplementations, onItemsChange }: ComparisonControlsProps) => {
  const sharedTasks = useMemo(
    () => computeSharedTasks(items, allImplementations),
    [items, allImplementations],
  )

  const currentTask = items.length > 0 ? items[0].task : null

  const handleTaskSwitch = useCallback((task: string) => {
    onItemsChange(items.map(item => ({ ...item, task })))
  }, [items, onItemsChange])

  const handleSwap = useCallback(() => {
    if (items.length !== 2) return
    onItemsChange([items[1], items[0]])
  }, [items, onItemsChange])

  const handleModelChange = useCallback((side: 0 | 1, model: string) => {
    const newItems = [...items]
    newItems[side] = { ...newItems[side], model }
    onItemsChange(newItems)
  }, [items, onItemsChange])

  if (items.length !== 2) return null

  return (
    <div className="border border-border rounded-lg bg-card/60 backdrop-blur-sm overflow-hidden">
      {/* Task switcher row — only shown when there are 2+ shared tasks */}
      {sharedTasks.length >= 2 && (
        <div className="flex items-center gap-2 px-4 py-2.5 border-b border-border bg-muted/40 overflow-x-auto">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground shrink-0">
            Task:
          </span>
          <div className="flex items-center gap-1.5 flex-wrap">
            {sharedTasks.map(task => (
              <button
                key={task}
                type="button"
                onClick={() => handleTaskSwitch(task)}
                className={`px-3 py-1 rounded-full text-xs font-medium transition-colors whitespace-nowrap focus:outline-none focus:ring-2 focus:ring-ring ${
                  task === currentTask
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-background border border-border text-muted-foreground hover:text-foreground hover:border-foreground/30'
                }`}
                aria-pressed={task === currentTask}
              >
                {formatLabel(task)}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Model selectors row */}
      <div className="flex items-end gap-2 px-4 py-3">
        <ModelSelector
          label="Model A"
          currentItem={items[0]}
          allImplementations={allImplementations}
          onSelect={model => handleModelChange(0, model)}
        />

        <Button
          variant="outline"
          size="icon"
          onClick={handleSwap}
          aria-label="Swap models"
          title="Swap Model A and Model B"
          className="shrink-0 h-9 w-9 mb-0.5"
        >
          <ArrowLeftRight className="h-4 w-4" />
        </Button>

        <ModelSelector
          label="Model B"
          currentItem={items[1]}
          allImplementations={allImplementations}
          onSelect={model => handleModelChange(1, model)}
        />
      </div>
    </div>
  )
}
