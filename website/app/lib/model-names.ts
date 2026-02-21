// Model display name and provider lookup — source of truth is config/model_names.json at the repo root.
// Used by components that receive benchmark result data (not manifest data).
// Components that have access to manifest ImplementationEntry objects should
// use entry.display_name / entry.provider directly instead of calling these functions.
import modelNamesJson from '../../public/data/model_names.json'

type ModelEntry = { display_name: string; provider: string }
const MODEL_DATA: Record<string, ModelEntry> = modelNamesJson as Record<string, ModelEntry>

const MODEL_DISPLAY_NAMES: Record<string, string> = Object.fromEntries(
  Object.entries(MODEL_DATA).map(([k, v]) => [k, v.display_name])
)

/** Returns the display name for an item that carries optional display_name + model slug. */
export const itemDisplayName = (item: { display_name?: string; model: string }): string =>
  item.display_name ?? item.model

/**
 * Returns the display name for a model slug.
 * Falls back to the raw slug if not found in the JSON config.
 */
export const getDisplayName = (slug: string): string =>
  MODEL_DISPLAY_NAMES[slug] ?? slug

/**
 * Returns the provider/family for a model slug.
 * Falls back to 'Other' if the slug is not in the JSON config.
 */
export const getModelFamily = (slug: string): string =>
  MODEL_DATA[slug]?.provider ?? 'Other'
