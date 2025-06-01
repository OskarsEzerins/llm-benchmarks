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
| 1    | claude_3_5_sonnet_cursor_02_2025                  | 90.92       | 4/4       | 80.61     | 95.6                 | 91.88               | 95.6          |
| 2    | openai_4o_mini_openrouter_06_2025                 | 90.55       | 4/4       | 79.81     | 99.99                | 86.72               | 95.69         |
| 3    | gemini_2_0_flash_web_chat_02_2025                 | 89.93       | 4/4       | 80.88     | 96.08                | 89.08               | 93.7          |
| 4    | claude_3_7_sonnet_thinking_vscode_03_2025         | 89.71       | 4/4       | 80.46     | 95.49                | 88.9                | 93.99         |
| 5    | openai_o3_mini_web_chat_02_2025                   | 89.35       | 4/4       | 80.78     | 95.76                | 86.21               | 94.65         |
| 6    | openai_o1_web_chat_02_2025                        | 89.31       | 4/4       | 80.07     | 95.93                | 85.42               | 95.82         |
| 7    | claude_3_7_sonnet_thinking_openrouter_06_2025     | 89.24       | 4/4       | 79.28     | 95.01                | 87.02               | 95.64         |
| 8    | openai_o3_mini_web_chat_03_2025                   | 89.21       | 4/4       | 80.76     | 96.2                 | 84.36               | 95.5          |
| 9    | gemini_2_5_flash_preview_05_20_openrouter_06_2025 | 89.19       | 4/4       | 80.24     | 96.24                | 84.83               | 95.43         |
| 10   | gemini_2_0_pro_exp_cursor_chat_02_2025            | 88.86       | 4/4       | 79.31     | 96.75                | 83.96               | 95.41         |
| 11   | gemini_2_5_pro_preview_openrouter_05_2025         | 88.67       | 4/4       | 80.36     | 95.84                | 84.82               | 93.66         |
| 12   | gemini_2_5_pro_exp_chat_03_2025                   | 88.49       | 4/4       | 80.38     | 93.66                | 84.23               | 95.68         |
| 13   | deepseek_r1_web_chat_02_2025                      | 88.39       | 4/4       | 80.8      | 96.07                | 83.64               | 93.05         |
| 14   | openai_4_1_mini_openai_api_04_2025                | 88.37       | 4/4       | 80.57     | 97.02                | 80.41               | 95.48         |
| 15   | claude_3_7_sonnet_openrouter_06_2025              | 88.28       | 4/4       | 80.35     | 95.45                | 81.97               | 95.34         |
| 16   | grok_3_beta_openrouter_05_2025                    | 87.75       | 4/4       | 79.85     | 96.22                | 88.83               | 86.11         |
| 17   | openai_4_1_mini_openrouter_06_2025                | 87.61       | 4/4       | 79.48     | 96.22                | 79.27               | 95.45         |
| 18   | qwen_2_5_max_02_2025                              | 87.48       | 4/4       | 70.33     | 96.19                | 87.6                | 95.78         |
| 19   | claude_opus_4_openrouter_05_2025                  | 87.31       | 4/4       | 80.18     | 96.88                | 78.22               | 93.98         |
| 20   | gemini_2_5_flash_preview_05_20_openrouter_05_2025 | 87.11       | 4/4       | 73.7      | 95.14                | 84.82               | 94.77         |
| 21   | claude_3_7_sonnet_thinking_cursor_02_2025         | 86.72       | 4/4       | 80.27     | 95.55                | 82.96               | 88.12         |
| 22   | claude_4_sonnet_web_chat_05_2025                  | 85.91       | 4/4       | 80.22     | 95.36                | 83.78               | 84.3          |
| 23   | deepseek_v3_web_chat_02_2025                      | 70.87       | 3/4       | 0         | 99.85                | 87.9                | 95.73         |
| 24   | gemma_3_27b_it_free_openrouter_05_2025            | 70.06       | 3/4       | 0         | 95.6                 | 89.1                | 95.53         |
| 25   | openai_o4_high_web_chat_04_2025                   | 68.95       | 3/4       | 84.26     | 95.76                | 0                   | 95.78         |
| 26   | openai_4o_web_chat_02_2025                        | 68.59       | 3/4       | 0         | 95.56                | 83.07               | 95.75         |
| 27   | openai_o4_mini_openrouter_06_2025                 | 68.28       | 3/4       | 80.72     | 96.62                | 0                   | 95.79         |
| 28   | openai_o3_high_web_chat_02_2025                   | 68.13       | 3/4       | 80.77     | 96.05                | 0                   | 95.72         |
| 29   | llama_4_maverick_openrouter_05_2025               | 67.83       | 3/4       | 80.14     | 95.85                | 0                   | 95.34         |
| 30   | openai_4o_openrouter_06_2025                      | 67.77       | 3/4       | 0         | 95.58                | 82.67               | 92.85         |
| 31   | claude_3_7_sonnet_vscode_03_2025                  | 67.61       | 3/4       | 80.35     | 96.18                | 0                   | 93.91         |
| 32   | deepseek_v3_free_openrouter_05_2025               | 66.07       | 3/4       | 0         | 99.99                | 70.96               | 93.32         |
| 33   | openai_o3_high_web_chat_03_2025                   | 65.19       | 3/4       | 80.71     | 0                    | 84.56               | 95.47         |
| 34   | claude_3_5_sonnet_openrouter_05_2025              | 65.08       | 3/4       | 79.72     | 86.62                | 0                   | 93.97         |
| 35   | openai_4_1_openrouter_05_2025                     | 62.9        | 3/4       | 80.18     | 83.28                | 0                   | 88.15         |
| 36   | claude_3_7_sonnet_web_chat_02_2025                | 62.51       | 3/4       | 80.56     | 0                    | 83.0                | 86.46         |
| 37   | openai_4_1_openai_api_04_2025                     | 60.6        | 3/4       | 79.06     | 0                    | 74.3                | 89.03         |
| 38   | claude_3_5_haiku_openrouter_05_2025               | 46.05       | 2/4       | 0         | 91.2                 | 0                   | 92.99         |
| 39   | openai_4_1_nano_openai_api_04_2025                | 45.05       | 2/4       | 80.54     | 99.65                | 0                   | 0             |
| 40   | openai_o4_mini_web_chat_04_2025                   | 44.07       | 2/4       | 80.07     | 96.2                 | 0                   | 0             |
| 41   | openai_o4_mini_high_openrouter_05_2025            | 44.02       | 2/4       | 79.63     | 96.43                | 0                   | 0             |
| 42   | claude_3_5_sonnet_openrouter_06_2025              | 42.62       | 2/4       | 76.23     | 0                    | 0                   | 94.24         |
| 43   | qwen_2_5_plus_02_2025                             | 41.1        | 2/4       | 80.79     | 0                    | 83.62               | 0             |
| 44   | mistral_web_03_2025                               | 38.94       | 2/4       | 0         | 96.55                | 0                   | 59.19         |
| 45   | deepseek_r1_distill_qwen_32b_web_chat_02_2025     | 23.91       | 1/4       | 0         | 0                    | 0                   | 95.65         |
| 46   | command_a_openrouter_06_2025                      | 23.14       | 1/4       | 0         | 0                    | 0                   | 92.54         |
| 47   | localai_gpt_4o_phi_2_02_2025                      | 15.97       | 1/4       | 63.87     | 0                    | 0                   | 0             |
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
