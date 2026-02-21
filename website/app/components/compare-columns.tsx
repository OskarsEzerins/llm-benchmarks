import { useState, useEffect } from 'react'
import { Loader2 } from 'lucide-react'
import { ColorSchemeType } from 'diff2html/lib/types'
import { loadImplementationSource } from '../lib/implementations-data'
import { itemDisplayName } from '../lib/model-names'
import 'diff2html/bundles/css/diff2html.min.css'
import type { CompareItem } from '../types/benchmark'

interface CompareColumnsProps {
  items: CompareItem[]
}

// Scoped CSS overrides — only target code content cell for word wrap
const DIFF_WRAP_STYLE = `
.diff-wrap-container .d2h-code-line-ctn pre {
  white-space: pre-wrap;
  word-wrap: break-word;
  overflow-wrap: anywhere;
}
.diff-wrap-container .d2h-file-header {
  display: none;
}
`

export const CompareColumns = ({ items }: CompareColumnsProps) => {
  const [diffHtml, setDiffHtml] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const isTwoSameTask =
    items.length === 2 && items[0].task === items[1].task && items[0].type === items[1].type

  useEffect(() => {
    if (!isTwoSameTask) return

    let cancelled = false
    setLoading(true)
    setDiffHtml(null)
    setError(null)

    const [a, b] = items

    Promise.all([
      loadImplementationSource(a.type, a.task, a.model),
      loadImplementationSource(b.type, b.task, b.model),
    ])
      .then(async ([sourceA, sourceB]) => {
        if (cancelled) return

        if (!sourceA || !sourceB) {
          setError('Failed to load one or both source files.')
          return
        }

        const { createTwoFilesPatch } = await import('diff')
        const { html } = await import('diff2html')

        // Use the same filename for both sides so diff2html does not show a "RENAMED" badge.
        // Model names go into the header label via oldHeader/newHeader, not the file path.
        const fileName = 'implementation.rb'

        const patch = createTwoFilesPatch(
          fileName,
          fileName,
          sourceA,
          sourceB,
          itemDisplayName(a),
          itemDisplayName(b),
          { context: 5 },
        )

        const rendered = html(patch, {
          outputFormat: 'side-by-side',
          drawFileList: false,
          matching: 'lines',
          renderNothingWhenEmpty: false,
          colorScheme: ColorSchemeType.AUTO,
        })

        if (!cancelled) {
          setDiffHtml(rendered)
        }
      })
      .catch(() => {
        if (!cancelled) {
          setError('Failed to generate diff.')
        }
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false)
        }
      })

    return () => {
      cancelled = true
    }
  }, [items, isTwoSameTask])

  if (!isTwoSameTask) {
    return (
      <div className="border rounded-lg bg-muted p-8 text-center">
        <p className="text-muted-foreground font-medium">
          Diff view requires exactly 2 implementations of the same task.
        </p>
        <p className="text-muted-foreground text-sm mt-1">
          {items.length !== 2
            ? `${items.length} implementation${items.length !== 1 ? 's' : ''} selected — select exactly 2.`
            : 'The selected implementations are from different tasks.'}
        </p>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="border rounded-lg bg-muted p-12 flex items-center justify-center min-h-[200px]">
        <div className="flex items-center gap-2 text-muted-foreground">
          <Loader2 className="h-5 w-5 animate-spin" />
          <span>Loading diff...</span>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="border rounded-lg bg-destructive/10 p-8 text-center min-h-[200px] flex items-center justify-center">
        <p className="text-destructive">{error}</p>
      </div>
    )
  }

  if (!diffHtml) return null

  return (
    <>
      {/* Inject line-wrap styles once per render tree */}
      <style dangerouslySetInnerHTML={{ __html: DIFF_WRAP_STYLE }} />

      {/* Responsive max-width: full on smaller viewports, capped at 1400px on 2xl+ */}
      <div className="w-full 2xl:max-w-[1400px] 2xl:mx-auto">
        <div
          className="diff-wrap-container border rounded-lg overflow-hidden text-sm"
          dangerouslySetInnerHTML={{ __html: diffHtml }}
        />
      </div>
    </>
  )
}
