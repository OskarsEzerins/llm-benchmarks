// Model name normalization utilities for better display names

interface ModelNormalizationRule {
  pattern: RegExp
  replacement: string
}

const MODEL_NORMALIZATION_RULES: ModelNormalizationRule[] = [
  // OpenAI models
  { pattern: /^openai[_\s]*o[_\s]*1[_\s]*mini/i, replacement: 'OpenAI o1-mini' },
  { pattern: /^openai[_\s]*o[_\s]*1[_\s]*preview/i, replacement: 'OpenAI o1-preview' },
  { pattern: /^openai[_\s]*o[_\s]*1(?![\w\d])/i, replacement: 'OpenAI o1' },
  { pattern: /^openai[_\s]*o[_\s]*3[_\s]*mini/i, replacement: 'OpenAI o3-mini' },
  { pattern: /^openai[_\s]*o[_\s]*4[_\s]*mini/i, replacement: 'OpenAI o4-mini' },
  { pattern: /^openai[_\s]*4[_\s]*o[_\s]*latest/i, replacement: 'OpenAI GPT-4o (Latest)' },
  { pattern: /^openai[_\s]*4[_\s]*o[_\s]*mini/i, replacement: 'OpenAI GPT-4o mini' },
  { pattern: /^openai[_\s]*4[_\s]*o/i, replacement: 'OpenAI GPT-4o' },
  { pattern: /^openai[_\s]*4[_\s]*turbo/i, replacement: 'OpenAI GPT-4 Turbo' },
  { pattern: /^openai[_\s]*4[_\s]*1[_\s]*mini/i, replacement: 'OpenAI GPT-4.1 mini' },
  { pattern: /^openai[_\s]*4[_\s]*1[_\s]*nano/i, replacement: 'OpenAI GPT-4.1 nano' },
  { pattern: /^openai[_\s]*4[_\s]*1(?![\w\d])/i, replacement: 'OpenAI 4.1' },
  { pattern: /^openai[_\s]*4(?![\w\d])/i, replacement: 'OpenAI GPT-4' },
  { pattern: /^openai[_\s]*3[_\s]*5[_\s]*turbo/i, replacement: 'OpenAI GPT-3.5 Turbo' },
  { pattern: /^openai[_\s]*chat[_\s]*4o[_\s]*latest/i, replacement: 'OpenAI GPT-4o (Latest)' },

  // Claude models
  { pattern: /^claude[_\s]*sonnet[_\s]*4/i, replacement: 'Claude 4 Sonnet' },
  { pattern: /^claude[_\s]*opus[_\s]*4/i, replacement: 'Claude 4 Opus' },
  { pattern: /^claude[_\s]*3[_\s]*7[_\s]*sonnet[_\s]*thinking/i, replacement: 'Claude 3.7 Sonnet (Thinking)' },
  { pattern: /^claude[_\s]*3[_\s]*7[_\s]*sonnet/i, replacement: 'Claude 3.7 Sonnet' },
  { pattern: /^claude[_\s]*3[_\s]*5[_\s]*sonnet/i, replacement: 'Claude 3.5 Sonnet' },
  { pattern: /^claude[_\s]*3[_\s]*5[_\s]*haiku/i, replacement: 'Claude 3.5 Haiku' },
  { pattern: /^claude[_\s]*3[_\s]*haiku/i, replacement: 'Claude 3 Haiku' },
  { pattern: /^claude[_\s]*3[_\s]*opus/i, replacement: 'Claude 3 Opus' },
  { pattern: /^claude[_\s]*3[_\s]*sonnet/i, replacement: 'Claude 3 Sonnet' },

  // Gemini models
  { pattern: /^gemini[_\s]*2[_\s]*5[_\s]*pro/i, replacement: 'Gemini 2.5 Pro' },
  { pattern: /^gemini[_\s]*2[_\s]*5[_\s]*flash[_\s]*lite/i, replacement: 'Gemini 2.5 Flash Lite' },
  { pattern: /^gemini[_\s]*2[_\s]*5[_\s]*flash/i, replacement: 'Gemini 2.5 Flash' },
  { pattern: /^gemini[_\s]*2[_\s]*0[_\s]*flash[_\s]*001/i, replacement: 'Gemini 2.0 Flash-001' },
  { pattern: /^gemini[_\s]*2[_\s]*0[_\s]*flash/i, replacement: 'Gemini 2.0 Flash' },
  { pattern: /^gemini[_\s]*1[_\s]*5[_\s]*pro/i, replacement: 'Gemini 1.5 Pro' },
  { pattern: /^gemini[_\s]*1[_\s]*5[_\s]*flash/i, replacement: 'Gemini 1.5 Flash' },

  // DeepSeek models
  { pattern: /^deepseek[_\s]*v[_\s]*3/i, replacement: 'DeepSeek V3' },
  { pattern: /^deepseek[_\s]*r1/i, replacement: 'DeepSeek R1' },
  { pattern: /^deepseek[_\s]*coder/i, replacement: 'DeepSeek Coder' },

  // Llama models
  { pattern: /^llama[_\s]*4[_\s]*scout/i, replacement: 'Llama 4 Scout' },
  { pattern: /^llama[_\s]*4[_\s]*maverick/i, replacement: 'Llama 4 Maverick' },
  { pattern: /^llama[_\s]*3[_\s]*2/i, replacement: 'Llama 3.2' },
  { pattern: /^llama[_\s]*3[_\s]*1/i, replacement: 'Llama 3.1' },
  { pattern: /^llama[_\s]*3/i, replacement: 'Llama 3' },

  // Grok models
  { pattern: /^grok[_\s]*4/i, replacement: 'Grok 4' },
  { pattern: /^grok[_\s]*3[_\s]*mini/i, replacement: 'Grok 3 Mini' },
  { pattern: /^grok[_\s]*3/i, replacement: 'Grok 3' },
  { pattern: /^grok[_\s]*2/i, replacement: 'Grok 2' },

  // Other models
  { pattern: /^mistral[_\s]*medium[_\s]*3/i, replacement: 'Mistral Medium 3' },
  { pattern: /^codestral[_\s]*2508/i, replacement: 'Codestral 25.08' },
  { pattern: /^qwen[_\s]*3[_\s]*coder/i, replacement: 'Qwen 3 Coder' },
  { pattern: /^qwen[_\s]*3\.14b/i, replacement: 'Qwen 3.14B' },
  { pattern: /^coder[_\s]*large/i, replacement: 'Coder Large' },
  { pattern: /^nova[_\s]*pro[_\s]*v[_\s]*1/i, replacement: 'Nova Pro V1' },
  { pattern: /^nova[_\s]*lite[_\s]*v[_\s]*1/i, replacement: 'Nova Lite V1' },
  { pattern: /^nova[_\s]*micro[_\s]*v[_\s]*1/i, replacement: 'Nova Micro V1' },
  { pattern: /^kimi[_\s]*k[_\s]*2/i, replacement: 'Kimi K2' },
  { pattern: /^magnum[_\s]*v[_\s]*4[_\s]*72b/i, replacement: 'Magnum V4 72B' },
  { pattern: /^gemma[_\s]*3[_\s]*4b[_\s]*it/i, replacement: 'Gemma 3 4B IT' },
  { pattern: /^command[_\s]*a/i, replacement: 'Command A' },
  { pattern: /^r[_\s]*1(?![\w\d])/i, replacement: 'R1' },
]

const PROVIDER_ALIASES: Record<string, string> = {
  'openai': 'OpenAI',
  'claude': 'Claude',
  'gemini': 'Google',
  'deepseek': 'DeepSeek',
  'llama': 'Meta',
  'grok': 'xAI',
  'mistral': 'Mistral',
  'codestral': 'Mistral',
  'qwen': 'Alibaba',
  'nova': 'Amazon',
  'kimi': 'Moonshot',
  'magnum': 'NousResearch',
  'gemma': 'Google',
  'command': 'Cohere',
  'r1': 'DeepSeek'
}

/**
 * Normalizes a model implementation name for better display
 */
export const normalizeModelName = (implementation: string): string => {
  if (!implementation) return 'Unknown Model'

  // Remove date suffixes like "_openrouter_08_2025" or "_08_2025"
  // Be more specific to avoid removing model version numbers like "_4_1"
  let normalized = implementation
    .replace(/_openrouter_\d{2}_\d{4}$/g, '')
    .replace(/_\d{2}_\d{4}$/g, '')
    .trim()

  // Apply specific normalization rules
  for (const rule of MODEL_NORMALIZATION_RULES) {
    if (rule.pattern.test(normalized)) {
      return rule.replacement
    }
  }

  // Fallback: Generic formatting for unmatched models
  return formatGenericModelName(normalized)
}

/**
 * Generic formatting for model names that don't match specific rules
 */
const formatGenericModelName = (name: string): string => {
  return name
    .split(/[_\s]+/)
    .map(part => {
      // Handle version numbers like "3.5" or "4o"
      if (/^\d+(\.\d+)?[a-z]*$/i.test(part)) {
        return part.toLowerCase()
      }
      // Capitalize first letter of each word
      return part.charAt(0).toUpperCase() + part.slice(1).toLowerCase()
    })
    .join(' ')
    .replace(/\s+/g, ' ')
    .trim()
}

/**
 * Extracts the model family/provider from implementation name
 */
export const getModelFamily = (implementation: string): string => {
  const normalized = implementation.toLowerCase()

  for (const [provider, displayName] of Object.entries(PROVIDER_ALIASES)) {
    if (normalized.includes(provider)) {
      return displayName
    }
  }

  return 'Other'
}

/**
 * Gets a consistent model identifier for grouping/comparison
 */
export const getModelId = (implementation: string): string => {
  return implementation
    .replace(/_openrouter_\d+_\d+$/g, '')
    .replace(/_\d+_\d+$/g, '')
    .toLowerCase()
    .trim()
}
