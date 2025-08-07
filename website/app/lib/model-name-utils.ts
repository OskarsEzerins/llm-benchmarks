// Model name normalization utilities for better display names

interface ModelNormalizationRule {
  pattern: RegExp
  replacement?: string
  transform?: (match: RegExpMatchArray) => string
}

const MODEL_NORMALIZATION_RULES: ModelNormalizationRule[] = [
  // OpenAI models with flexible versioning
  { pattern: /^openai[_\s]*o[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*mini[_\s]*high/i, transform: (m: RegExpMatchArray) => `OpenAI o${m[1].replace(/[_\s]+/g, '.')}-mini (High)` },
  { pattern: /^openai[_\s]*o[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*mini/i, transform: (m: RegExpMatchArray) => `OpenAI o${m[1].replace(/[_\s]+/g, '.')}-mini` },
  { pattern: /^openai[_\s]*o[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*preview/i, transform: (m: RegExpMatchArray) => `OpenAI o${m[1].replace(/[_\s]+/g, '.')}-preview` },
  { pattern: /^openai[_\s]*o[_\s]*(\d+(?:[_\s]*\d+)*)(?![\w\d])/i, transform: (m: RegExpMatchArray) => `OpenAI o${m[1].replace(/[_\s]+/g, '.')}` },
  
  // GPT-5 variants
  { pattern: /^openai[_\s]*(5(?:[_\s]*\d+)*)[_\s]*chat/i, transform: (m: RegExpMatchArray) => `OpenAI GPT-${m[1].replace(/[_\s]+/g, '.')} Chat` },
  
  { pattern: /^openai[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*o[_\s]*latest/i, transform: (m: RegExpMatchArray) => `OpenAI GPT-${m[1].replace(/[_\s]+/g, '.')}o` },
  { pattern: /^openai[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*o[_\s]*mini/i, transform: (m: RegExpMatchArray) => `OpenAI GPT-${m[1].replace(/[_\s]+/g, '.')}o mini` },
  { pattern: /^openai[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*o/i, transform: (m: RegExpMatchArray) => `OpenAI GPT-${m[1].replace(/[_\s]+/g, '.')}o` },
  { pattern: /^openai[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*turbo/i, transform: (m: RegExpMatchArray) => `OpenAI GPT-${m[1].replace(/[_\s]+/g, '.')} Turbo` },
  { pattern: /^openai[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*mini/i, transform: (m: RegExpMatchArray) => `OpenAI GPT-${m[1].replace(/[_\s]+/g, '.')} mini` },
  { pattern: /^openai[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*nano/i, transform: (m: RegExpMatchArray) => `OpenAI GPT-${m[1].replace(/[_\s]+/g, '.')} nano` },
  { pattern: /^openai[_\s]*(\d+(?:[_\s]*\d+)*)(?![\w\d])/i, transform: (m: RegExpMatchArray) => `OpenAI GPT-${m[1].replace(/[_\s]+/g, '.')}` },
  { pattern: /^openai[_\s]*chat[_\s]*4o[_\s]*latest/i, replacement: 'OpenAI GPT-4o' },

  // Claude models with flexible versioning (Series 4+ format: claude_model_version, Series 3: claude_version_model)
  // Series 4 format: claude_sonnet_4, claude_opus_4_1
  { pattern: /^claude[_\s]*(sonnet|opus|haiku)[_\s]*(\d+(?:[_\s]*\d+)*)/i, transform: (m: RegExpMatchArray) => `Claude ${m[2].replace(/[_\s]+/g, '.')} ${m[1].charAt(0).toUpperCase() + m[1].slice(1)}` },
  
  // Series 3 format: claude_3_5_sonnet, claude_3_7_sonnet_thinking
  { pattern: /^claude[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*(sonnet|opus|haiku)[_\s]*thinking/i, transform: (m: RegExpMatchArray) => `Claude ${m[1].replace(/[_\s]+/g, '.')} ${m[2].charAt(0).toUpperCase() + m[2].slice(1)} (Thinking)` },
  { pattern: /^claude[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*(sonnet|opus|haiku)/i, transform: (m: RegExpMatchArray) => `Claude ${m[1].replace(/[_\s]+/g, '.')} ${m[2].charAt(0).toUpperCase() + m[2].slice(1)}` },

  // Gemini models with flexible versioning
  { pattern: /^gemini[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*pro/i, transform: (m: RegExpMatchArray) => `Gemini ${m[1].replace(/[_\s]+/g, '.')} Pro` },
  { pattern: /^gemini[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*flash[_\s]*lite/i, transform: (m: RegExpMatchArray) => `Gemini ${m[1].replace(/[_\s]+/g, '.')} Flash Lite` },
  { pattern: /^gemini[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*flash[_\s]*(\d+)/i, transform: (m: RegExpMatchArray) => `Gemini ${m[1].replace(/[_\s]+/g, '.')} Flash-${m[2]}` },
  { pattern: /^gemini[_\s]*(\d+(?:[_\s]*\d+)*)[_\s]*flash/i, transform: (m: RegExpMatchArray) => `Gemini ${m[1].replace(/[_\s]+/g, '.')} Flash` },

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
    const match = normalized.match(rule.pattern)
    if (match) {
      // Use transform function if available (for dynamic patterns)
      if (rule.transform) {
        return rule.transform(match)
      }
      // Use static replacement if available
      if (rule.replacement) {
        return rule.replacement
      }
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
