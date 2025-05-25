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
| 1    | claude_3_5_sonnet_cursor_02_2025                  | 90.92       | 4/4       | 80.6      | 95.58                | 91.89               | 95.6          |
| 2    | gemini_2_0_flash_web_chat_02_2025                 | 89.93       | 4/4       | 80.86     | 96.06                | 89.09               | 93.7          |
| 3    | claude_3_7_sonnet_thinking_vscode_03_2025         | 89.71       | 4/4       | 80.51     | 95.46                | 88.88               | 93.97         |
| 4    | openai_o3_mini_web_chat_02_2025                   | 89.36       | 4/4       | 80.8      | 95.75                | 86.23               | 94.65         |
| 5    | openai_o1_web_chat_02_2025                        | 89.32       | 4/4       | 80.06     | 95.92                | 85.46               | 95.82         |
| 6    | openai_o3_mini_web_chat_03_2025                   | 89.2        | 4/4       | 80.77     | 96.18                | 84.38               | 95.48         |
| 7    | gemini_2_0_pro_exp_cursor_chat_02_2025            | 88.85       | 4/4       | 79.26     | 96.72                | 84.02               | 95.4          |
| 8    | gemini_2_5_pro_preview_openrouter_05_2025         | 88.6        | 4/4       | 79.97     | 95.87                | 84.84               | 93.72         |
| 9    | gemini_2_5_pro_exp_chat_03_2025                   | 88.5        | 4/4       | 80.38     | 93.62                | 84.31               | 95.69         |
| 10   | deepseek_r1_web_chat_02_2025                      | 88.39       | 4/4       | 80.83     | 96.05                | 83.62               | 93.06         |
| 11   | openai_4_1_mini_openai_api_04_2025                | 88.14       | 4/4       | 80.54     | 97.01                | 79.55               | 95.47         |
| 12   | grok_3_beta_openrouter_05_2025                    | 87.52       | 4/4       | 79.09     | 96.24                | 88.8                | 85.94         |
| 13   | qwen_2_5_max_02_2025                              | 87.42       | 4/4       | 70.12     | 96.17                | 87.6                | 95.78         |
| 14   | gemini_2_5_flash_preview_05_20_openrouter_05_2025 | 86.84       | 4/4       | 73.36     | 95.14                | 84.12               | 94.72         |
| 15   | claude_opus_4_openrouter_05_2025                  | 86.78       | 4/4       | 79.43     | 96.99                | 76.96               | 93.73         |
| 16   | claude_3_7_sonnet_thinking_cursor_02_2025         | 86.72       | 4/4       | 80.21     | 95.52                | 82.99               | 88.14         |
| 17   | claude_4_sonnet_web_chat_05_2025                  | 85.71       | 4/4       | 79.75     | 95.24                | 83.51               | 84.33         |
| 18   | deepseek_v3_web_chat_02_2025                      | 70.87       | 3/4       | 0         | 99.83                | 87.92               | 95.72         |
| 19   | gemma_3_27b_it_free_openrouter_05_2025            | 70.06       | 3/4       | 0         | 95.63                | 89.1                | 95.52         |
| 20   | openai_o4_high_web_chat_04_2025                   | 68.84       | 3/4       | 83.82     | 95.74                | 0                   | 95.78         |
| 21   | openai_4o_web_chat_02_2025                        | 68.6        | 3/4       | 0         | 95.54                | 83.1                | 95.74         |
| 22   | openai_o3_high_web_chat_02_2025                   | 68.14       | 3/4       | 80.8      | 96.03                | 0                   | 95.72         |
| 23   | llama_4_maverick_openrouter_05_2025               | 67.79       | 3/4       | 79.89     | 95.85                | 0                   | 95.41         |
| 24   | claude_3_7_sonnet_vscode_03_2025                  | 67.58       | 3/4       | 80.28     | 96.15                | 0                   | 93.89         |
| 25   | openai_o3_high_web_chat_03_2025                   | 65.18       | 3/4       | 80.73     | 0                    | 84.57               | 95.44         |
| 26   | deepseek_v3_free_openrouter_05_2025               | 65.16       | 3/4       | 0         | 99.99                | 67.32               | 93.34         |
| 27   | claude_3_5_sonnet_openrouter_05_2025              | 64.86       | 3/4       | 78.94     | 86.62                | 0                   | 93.9          |
| 28   | openai_4_1_openrouter_05_2025                     | 62.76       | 3/4       | 79.83     | 83.05                | 0                   | 88.18         |
| 29   | claude_3_7_sonnet_web_chat_02_2025                | 62.52       | 3/4       | 80.58     | 0                    | 83.01               | 86.47         |
| 30   | openai_4_1_openai_api_04_2025                     | 59.95       | 3/4       | 78.56     | 0                    | 72.24               | 88.99         |
| 31   | claude_3_5_haiku_openrouter_05_2025               | 46.05       | 2/4       | 0         | 91.24                | 0                   | 92.94         |
| 32   | openai_4_1_nano_openai_api_04_2025                | 45.04       | 2/4       | 80.54     | 99.63                | 0                   | 0             |
| 33   | openai_o4_mini_web_chat_04_2025                   | 44.03       | 2/4       | 79.96     | 96.18                | 0                   | 0             |
| 34   | openai_o4_mini_high_openrouter_05_2025            | 43.88       | 2/4       | 79.09     | 96.44                | 0                   | 0             |
| 35   | qwen_2_5_plus_02_2025                             | 41.11       | 2/4       | 80.83     | 0                    | 83.59               | 0             |
| 36   | mistral_web_03_2025                               | 38.98       | 2/4       | 0         | 96.52                | 0                   | 59.39         |
| 37   | deepseek_r1_distill_qwen_32b_web_chat_02_2025     | 23.91       | 1/4       | 0         | 0                    | 0                   | 95.65         |
| 38   | localai_gpt_4o_phi_2_02_2025                      | 15.92       | 1/4       | 63.68     | 0                    | 0                   | 0             |
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
