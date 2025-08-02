import type { ModelRanking } from '../types/benchmark'
import { ModelRankingCard } from './ModelRankingCard'
import { SectionHeader } from './SectionHeader'
import { Trophy, Crown, Medal } from 'lucide-react'

interface TopPerformerSectionProps {
  topModels?: ModelRanking[]
  topModel?: ModelRanking // Backwards compatibility
  championTitle: string
  useHomeStyle?: boolean
}

export const TopPerformerSection = ({ topModels, topModel, championTitle, useHomeStyle = false }: TopPerformerSectionProps) => {
  // Support both old (single topModel) and new (multiple topModels) interfaces
  const models = topModels || (topModel ? [topModel] : [])

  if (models.length === 0) return null

  const icon = useHomeStyle ? (
    <Crown className="h-6 w-6 text-yellow-500" />
  ) : (
    <Trophy className="h-6 w-6 text-yellow-500" />
  )

  const isMultipleModels = models.length > 1

  return (
    <section>
      <SectionHeader
        icon={icon}
        title={isMultipleModels ? "Top Performers" : "Top Performer"}
        badge={{ text: championTitle }}
      />
      {isMultipleModels ? (
        <div className="grid gap-6 md:grid-cols-1 lg:grid-cols-3 max-w-6xl mx-auto">
          {models.slice(0, 3).map((model, index) => (
            <div key={model.implementation} className={`${index === 0 ? 'lg:order-2' : index === 1 ? 'lg:order-1' : 'lg:order-3'} ${index === 0 ? 'lg:scale-110 lg:-mt-4' : ''}`}>
              <ModelRankingCard
                model={model}
                rank={index + 1}
              />
            </div>
          ))}
        </div>
      ) : (
        <div className="max-w-md mx-auto">
          <ModelRankingCard model={models[0]} rank={1} />
        </div>
      )}
    </section>
  )
}
