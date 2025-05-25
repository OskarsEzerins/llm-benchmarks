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
+---------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                   Total Implementation Rankings Across All Benchmarks                                                   |
+------+-----------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
| Rank | Implementation                                | Total Score | Completed | Lru Cache | Graph Shortest Paths | Run Length Encoding | Csv Processor |
+------+-----------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
| 1    | claude_3_5_sonnet_cursor_02_2025              | 90.92       | 4/4       | 80.62     | 95.57                | 91.89               | 95.6          |
| 2    | gemini_2_0_flash_web_chat_02_2025             | 89.94       | 4/4       | 80.91     | 96.05                | 89.1                | 93.69         |
| 3    | claude_3_7_sonnet_thinking_vscode_03_2025     | 89.69       | 4/4       | 80.51     | 95.42                | 88.87               | 93.97         |
| 4    | openai_o3_mini_web_chat_02_2025               | 89.36       | 4/4       | 80.8      | 95.73                | 86.26               | 94.65         |
| 5    | openai_o1_web_chat_02_2025                    | 89.32       | 4/4       | 80.08     | 95.91                | 85.49               | 95.82         |
| 6    | openai_o3_mini_web_chat_03_2025               | 89.2        | 4/4       | 80.77     | 96.15                | 84.39               | 95.47         |
| 7    | gemini_2_0_pro_exp_cursor_chat_02_2025        | 88.86       | 4/4       | 79.26     | 96.7                 | 84.07               | 95.4          |
| 8    | gemini_2_5_pro_exp_chat_03_2025               | 88.49       | 4/4       | 80.33     | 93.61                | 84.34               | 95.7          |
| 9    | deepseek_r1_web_chat_02_2025                  | 88.39       | 4/4       | 80.84     | 96.04                | 83.61               | 93.06         |
| 10   | openai_4_1_mini_openai_api_04_2025            | 87.71       | 4/4       | 80.52     | 96.97                | 77.87               | 95.47         |
| 11   | qwen_2_5_max_02_2025                          | 87.39       | 4/4       | 70.03     | 96.15                | 87.58               | 95.78         |
| 12   | claude_3_7_sonnet_thinking_cursor_02_2025     | 86.71       | 4/4       | 80.21     | 95.49                | 83.01               | 88.15         |
| 13   | claude_4_sonnet_web_chat_05_2025              | 85.42       | 4/4       | 79.68     | 94.91                | 83.19               | 83.91         |
| 14   | deepseek_v3_web_chat_02_2025                  | 70.87       | 3/4       | 0         | 99.82                | 87.93               | 95.72         |
| 15   | openai_o4_high_web_chat_04_2025               | 68.84       | 3/4       | 83.88     | 95.71                | 0                   | 95.79         |
| 16   | openai_4o_web_chat_02_2025                    | 68.6        | 3/4       | 0         | 95.53                | 83.13               | 95.75         |
| 17   | openai_o3_high_web_chat_02_2025               | 68.14       | 3/4       | 80.81     | 96.02                | 0                   | 95.72         |
| 18   | claude_3_7_sonnet_vscode_03_2025              | 67.58       | 3/4       | 80.28     | 96.12                | 0                   | 93.92         |
| 19   | openai_o3_high_web_chat_03_2025               | 65.19       | 3/4       | 80.73     | 0                    | 84.59               | 95.44         |
| 20   | claude_3_7_sonnet_web_chat_02_2025            | 62.52       | 3/4       | 80.6      | 0                    | 83.03               | 86.47         |
| 21   | openai_4_1_openai_api_04_2025                 | 59.96       | 3/4       | 78.64     | 0                    | 72.21               | 89.0          |
| 22   | openai_4_1_nano_openai_api_04_2025            | 45.04       | 2/4       | 80.53     | 99.62                | 0                   | 0             |
| 23   | openai_o4_mini_web_chat_04_2025               | 44.02       | 2/4       | 79.93     | 96.15                | 0                   | 0             |
| 24   | qwen_2_5_plus_02_2025                         | 41.1        | 2/4       | 80.83     | 0                    | 83.58               | 0             |
| 25   | mistral_web_03_2025                           | 39.0        | 2/4       | 0         | 96.48                | 0                   | 59.5          |
| 26   | deepseek_r1_distill_qwen_32b_web_chat_02_2025 | 23.91       | 1/4       | 0         | 0                    | 0                   | 95.65         |
| 27   | localai_gpt_4o_phi_2_02_2025                  | 15.92       | 1/4       | 63.68     | 0                    | 0                   | 0             |
+------+-----------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
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
