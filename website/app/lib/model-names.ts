import type { ImplementationMetadata } from '../types/benchmark'

export const itemDisplayName = (item: {
  display_name?: string
  metadata?: ImplementationMetadata
  model?: string
  implementation?: string
}): string =>
  item.display_name ?? item.metadata?.display_name ?? item.model ?? item.implementation ?? 'Unknown'

export const getDisplayName = (
  implementation: string,
  metadata?: ImplementationMetadata,
): string => metadata?.display_name ?? implementation

export const getBaseModelName = (
  implementation: string,
  metadata?: ImplementationMetadata,
): string => metadata?.base_model_name ?? getDisplayName(implementation, metadata)

export const getModelFamily = (metadata?: ImplementationMetadata): string =>
  metadata?.family ?? metadata?.provider ?? 'Other'

export const getVariantLabel = (metadata?: ImplementationMetadata): string =>
  metadata?.variant_label ?? 'Legacy Variant'

export const getParamSummary = (metadata?: ImplementationMetadata): string[] =>
  (metadata?.param_summary ?? []).filter(summary => !summary.endsWith('Unknown'))
