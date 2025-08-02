export const getDifficultyLabel = (successRate: number) => {
  if (successRate >= 70) return 'Easy'
  if (successRate >= 50) return 'Medium'
  return 'Hard'
}

export const getDifficultyLabelUppercase = (successRate: number) => {
  if (successRate >= 70) return 'EASY'
  if (successRate >= 50) return 'MEDIUM'
  return 'HARD'
}

export const getDifficultyVariant = (successRate: number): "default" | "secondary" | "destructive" | "outline" => {
  if (successRate >= 70) return 'outline'
  if (successRate >= 50) return 'secondary'
  return 'destructive'
}

export const getDifficultyColor = (successRate: number) => {
  if (successRate >= 70) return 'text-emerald-600 dark:text-emerald-400'
  if (successRate >= 50) return 'text-amber-600 dark:text-amber-400'
  return 'text-red-600 dark:text-red-400'
}
