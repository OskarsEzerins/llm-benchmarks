```ruby
class Reality < Exception
  def initialize
    super("Your model may be hallucinating benchmarks")
  end
end

begin
  puts "Running AI-generated code..."
  raise Reality if performance != promised_performance
rescue Reality => e
  puts "Welcome to our benchmarks!"
end
```

<div align="center">

[![MIT License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![Ruby](https://img.shields.io/badge/Ruby-3.4+-red.svg)](https://www.ruby-lang.org)

</div>

---

<div align="center">

### 🧪 Where AI Models Come to Face Their `RuntimeError`s

</div>

## 🏆 Latest Battle Results

```
+-------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                     Total Implementation Rankings Across All Benchmarks                                                     |
+------+---------------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
| Rank | Implementation                                    | Total Score | Completed | Lru Cache | Graph Shortest Paths | Run Length Encoding | Csv Processor |
+------+---------------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
| 1    | claude_3_5_sonnet_cursor_02_2025                  | 90.88       | 4/4       | 80.53     | 95.59                | 91.83               | 95.58         |
| 2    | gemini_2_0_flash_web_chat_02_2025                 | 89.88       | 4/4       | 80.8      | 96.07                | 89.0                | 93.66         |
| 3    | openai_4o_mini_openrouter_06_2025                 | 89.69       | 4/4       | 77.61     | 99.98                | 85.83               | 95.34         |
| 4    | claude_3_7_sonnet_thinking_vscode_03_2025         | 89.61       | 4/4       | 80.27     | 95.46                | 88.78               | 93.94         |
| 5    | openai_o3_mini_web_chat_02_2025                   | 89.29       | 4/4       | 80.7      | 95.75                | 86.09               | 94.62         |
| 6    | openai_o1_web_chat_02_2025                        | 89.24       | 4/4       | 79.94     | 95.91                | 85.3                | 95.8          |
| 7    | openai_o3_mini_web_chat_03_2025                   | 89.09       | 4/4       | 80.57     | 96.17                | 84.14               | 95.46         |
| 8    | gemini_2_0_pro_exp_cursor_chat_02_2025            | 88.77       | 4/4       | 79.19     | 96.75                | 83.78               | 95.37         |
| 9    | gemini_2_5_flash_preview_05_20_openrouter_06_2025 | 88.75       | 4/4       | 79.59     | 96.11                | 84.05               | 95.25         |
| 10   | claude_3_7_sonnet_thinking_openrouter_06_2025     | 88.5        | 4/4       | 77.96     | 94.68                | 86.14               | 95.24         |
| 11   | gemini_2_5_pro_preview_openrouter_05_2025         | 88.4        | 4/4       | 79.87     | 95.74                | 84.48               | 93.52         |
| 12   | deepseek_r1_web_chat_02_2025                      | 88.34       | 4/4       | 80.72     | 96.06                | 83.56               | 93.02         |
| 13   | gemini_2_5_pro_exp_chat_03_2025                   | 88.34       | 4/4       | 80.16     | 93.57                | 83.99               | 95.63         |
| 14   | openai_4_1_mini_openai_api_04_2025                | 88.27       | 4/4       | 80.29     | 96.99                | 80.38               | 95.42         |
| 15   | claude_3_7_sonnet_openrouter_06_2025              | 87.48       | 4/4       | 79.08     | 95.23                | 80.62               | 94.98         |
| 16   | grok_3_beta_openrouter_05_2025                    | 87.48       | 4/4       | 79.46     | 96.12                | 88.53               | 85.8          |
| 17   | qwen_2_5_max_02_2025                              | 87.43       | 4/4       | 70.26     | 96.19                | 87.52               | 95.76         |
| 18   | claude_opus_4_openrouter_05_2025                  | 87.02       | 4/4       | 79.79     | 96.81                | 77.66               | 93.8          |
| 19   | gemini_2_5_flash_preview_05_20_openrouter_05_2025 | 86.79       | 4/4       | 73.08     | 95.05                | 84.38               | 94.63         |
| 20   | openai_4_1_mini_openrouter_06_2025                | 86.77       | 4/4       | 78.19     | 96.06                | 77.72               | 95.12         |
| 21   | claude_3_7_sonnet_thinking_cursor_02_2025         | 86.62       | 4/4       | 80.13     | 95.54                | 82.77               | 88.06         |
| 22   | claude_sonnet_4_openrouter_07_2025                | 86.46       | 4/4       | 75.34     | 94.42                | 83.43               | 92.67         |
| 23   | claude_4_sonnet_web_chat_05_2025                  | 85.69       | 4/4       | 79.92     | 95.32                | 83.46               | 84.04         |
| 24   | qwen3_coder_openrouter_07_2025                    | 82.63       | 4/4       | 74.6      | 94.48                | 78.97               | 82.47         |
| 25   | kimi_k2_openrouter_07_2025                        | 81.79       | 4/4       | 74.22     | 93.63                | 66.95               | 92.35         |
| 26   | deepseek_v3_web_chat_02_2025                      | 70.84       | 3/4       | 0         | 99.85                | 87.81               | 95.7          |
| 27   | gemma_3_27b_it_free_openrouter_05_2025            | 69.91       | 3/4       | 0         | 95.5                 | 88.75               | 95.39         |
| 28   | openai_o4_high_web_chat_04_2025                   | 68.88       | 3/4       | 84.08     | 95.71                | 0                   | 95.71         |
| 29   | openai_4o_web_chat_02_2025                        | 68.55       | 3/4       | 0         | 95.54                | 82.94               | 95.73         |
| 30   | openai_o3_high_web_chat_02_2025                   | 68.1        | 3/4       | 80.64     | 96.05                | 0                   | 95.7          |
| 31   | openai_o4_mini_openrouter_06_2025                 | 67.82       | 3/4       | 79.42     | 96.36                | 0                   | 95.52         |
| 32   | llama_4_maverick_openrouter_05_2025               | 67.7        | 3/4       | 79.77     | 95.76                | 0                   | 95.25         |
| 33   | claude_3_7_sonnet_vscode_03_2025                  | 67.55       | 3/4       | 80.17     | 96.15                | 0                   | 93.87         |
| 34   | openai_4o_openrouter_06_2025                      | 67.29       | 3/4       | 0         | 95.32                | 81.45               | 92.37         |
| 35   | deepseek_v3_free_openrouter_05_2025               | 65.83       | 3/4       | 0         | 99.99                | 70.12               | 93.21         |
| 36   | openai_o3_high_web_chat_03_2025                   | 65.08       | 3/4       | 80.53     | 0                    | 84.34               | 95.43         |
| 37   | claude_3_5_sonnet_openrouter_05_2025              | 64.88       | 3/4       | 79.39     | 86.36                | 0                   | 93.79         |
| 38   | openai_4_1_openrouter_05_2025                     | 62.67       | 3/4       | 79.84     | 82.96                | 0                   | 87.86         |
| 39   | claude_3_7_sonnet_web_chat_02_2025                | 62.41       | 3/4       | 80.42     | 0                    | 82.82               | 86.39         |
| 40   | openai_4_1_openai_api_04_2025                     | 60.43       | 3/4       | 78.83     | 0                    | 73.94               | 88.94         |
| 41   | claude_3_5_haiku_openrouter_05_2025               | 45.97       | 2/4       | 0         | 91.05                | 0                   | 92.81         |
| 42   | openai_4_1_nano_openai_api_04_2025                | 44.99       | 2/4       | 80.32     | 99.65                | 0                   | 0             |
| 43   | openai_o4_mini_web_chat_04_2025                   | 43.99       | 2/4       | 79.81     | 96.16                | 0                   | 0             |
| 44   | openai_o4_mini_high_openrouter_05_2025            | 43.93       | 2/4       | 79.36     | 96.36                | 0                   | 0             |
| 45   | claude_3_5_sonnet_openrouter_06_2025              | 41.8        | 2/4       | 73.41     | 0                    | 0                   | 93.78         |
| 46   | qwen_2_5_plus_02_2025                             | 41.06       | 2/4       | 80.7      | 0                    | 83.55               | 0             |
| 47   | mistral_web_03_2025                               | 38.79       | 2/4       | 0         | 96.53                | 0                   | 58.63         |
| 48   | deepseek_r1_distill_qwen_32b_web_chat_02_2025     | 23.91       | 1/4       | 0         | 0                    | 0                   | 95.62         |
| 49   | command_a_openrouter_06_2025                      | 23.06       | 1/4       | 0         | 0                    | 0                   | 92.26         |
| 50   | localai_gpt_4o_phi_2_02_2025                      | 15.95       | 1/4       | 63.79     | 0                    | 0                   | 0             |
+------+---------------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
```

## 🔧 Requirements

```ruby
unless RUBY_VERSION >= "3.4.0"
  puts "⚠️ Hold up! We need Ruby 3.4+ for this party! ⚠️"
  exit
end

puts "✨ You're good to go! Let's benchmark some AI! ✨"
```

## 🚀 Features

```ruby
module BenchmarkFeatures
  class << self
    def automated_testing
      # One command for both running benchmarks and generating implementations
      system("bin/main")
    end

    def implementation_generation
      # Automatic implementation generation with OpenRouter models
      # powered by ruby_llm gem
      available_models = true
      easy_setup = true
      consistent_results = true

      puts "✨ AI-powered solution generation" if available_models && easy_setup && consistent_results
    end

    def fair_competition
      models.each do |model|
        # Each model gets the same prompt
        # Each implementation is saved with a timestamp
        # Results are tracked and compared consistently
      end
    end

    def metrics
      {
        speed: "⚡️ Microseconds matter",
        memory: "🧠 Every byte counts",
        complexity: "🤯 O(n) or go home",
        readability: "👀 Code so clean it squeaks"
      }
    end

    def transparency
      open_source = true
      results_public = true
      bias = nil # We don't do that here

      puts "Trust through code, not words" if open_source && results_public && bias.nil?
    end

    private

    def marketing_buzz
      raise NotImplementedError, "We prefer cold, hard benchmarks"
    end
  end
end

# No AI models were permanently harmed in the making of these benchmarks
# (They just learned some humility)
```

## ⚡ Quick Start

```bash
# Clone this beauty
git clone https://github.com/yourusername/llm-benchmarks
cd llm-benchmarks

# Install dependencies
bundle install

# Choose your adventure 🎮
bin/main

# Here you can:
# 1. Run benchmarks with existing implementations
# 2. Generate new AI implementations with OpenRouter models

# See who survived
bin/show_all_results

# See the total rankings
bin/show_total_rankings
```

## 🏗️ Project Anatomy

```
📦 THE_LABORATORY
 ┣ 📂 benchmarks      # Where AI models face their destiny
 ┣ 📂 implementations # AI's best attempts at glory
 ┣ 📂 lib             # Our torture... err, testing tools
 ┣ 📂 results         # The cold, hard truth
 ┗ 📂 bin             # Press buttons, get answers
```

## 🤝 Join the Fun!

```ruby
if you.have_ideas? && you.like_benchmarks?
  puts "We'd love your help!"
  fork_it
  create_branch
  push_changes
  pull_request
else
  puts "No pressure! Star us and come back later!"
end
```

---

<div align="center">

### 🔬 `assert_equal(ai_promises, reality)`

_Where AI code meets its maker... literally_

</div>
