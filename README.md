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
+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                    Total Implementation Rankings Across All Benchmarks                                                    |
+------+-------------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
| Rank | Implementation                                  | Total Score | Completed | Lru Cache | Graph Shortest Paths | Run Length Encoding | Csv Processor |
+------+-------------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
| 1    | claude_sonet_3_5_cursor_02_2025                 | 98.38       | 4/4       | 97.65     | 97.49                | 98.99               | 99.4          |
| 2    | claude_sonet_3_7_sonnet_thinking_vscode_03_2025 | 94.13       | 4/4       | 97.4      | 97.21                | 85.83               | 96.1          |
| 3    | openai_o3_mini_web_chat_02_2025                 | 91.48       | 4/4       | 98.03     | 97.57                | 72.65               | 97.67         |
| 4    | openai_o3_mini_web_chat_03_2025                 | 89.93       | 4/4       | 97.67     | 97.57                | 65.43               | 99.06         |
| 5    | gemini_2_0_pro_exp_cursor_chat_02_2025          | 88.33       | 4/4       | 93.05     | 98.09                | 63.15               | 99.04         |
| 6    | deepseek_r1_web_chat_02_2025                    | 87.31       | 4/4       | 98.08     | 97.74                | 58.58               | 94.84         |
| 7    | gemini_2_0_flash_web_chat_02_2025               | 86.2        | 4/4       | 98.62     | 97.74                | 85.76               | 62.67         |
| 8    | claude_sonet_3_7_sonnet_thinking_cursor_02_2025 | 84.39       | 4/4       | 96.73     | 97.32                | 57.4                | 86.1          |
| 9    | qwen_2_5_max_02_2025                            | 82.5        | 4/4       | 56.09     | 97.74                | 76.49               | 99.68         |
| 10   | openai_o1_web_chat_02_2025                      | 82.28       | 4/4       | 95.99     | 97.69                | 35.69               | 99.75         |
| 11   | gemini_2_5_pro_exp_chat_03_2025                 | 80.05       | 4/4       | 93.98     | 62.7                 | 64.01               | 99.49         |
| 12   | openai_o3_high_web_chat_02_2025                 | 73.89       | 3/4       | 98.21     | 97.74                | 0                   | 99.63         |
| 13   | claude_sonet_3_7_sonnet_vscode_03_2025          | 72.9        | 3/4       | 97.83     | 97.71                | 0                   | 96.07         |
| 14   | deepseek_v3_web_chat_02_2025                    | 70.01       | 3/4       | 0         | 99.89                | 80.63               | 99.54         |
| 15   | openai_o3_high_web_chat_03_2025                 | 65.62       | 3/4       | 97.71     | 0                    | 65.77               | 99.01         |
| 16   | openai_4o_web_chat_02_2025                      | 63.69       | 3/4       | 0         | 97.47                | 57.66               | 99.62         |
| 17   | claude_sonet_3_7_sonnet_web_chat_02_2025        | 59.48       | 3/4       | 97.64     | 0                    | 57.63               | 82.64         |
| 18   | qwen_2_5_plus_02_2025                           | 48.31       | 3/4       | 98.26     | 36.44                | 58.55               | 0             |
| 19   | mistral_web_03_2025                             | 33.33       | 2/4       | 0         | 97.87                | 0                   | 35.46         |
| 20   | deepseek_r1_distill_qwen_32b_web_chat_02_2025   | 24.85       | 1/4       | 0         | 0                    | 0                   | 99.41         |
| 21   | localai_gpt_4o_phi_2_02_2025                    | 3.24        | 1/4       | 12.95     | 0                    | 0                   | 0             |
+------+-------------------------------------------------+-------------+-----------+-----------+----------------------+---------------------+---------------+
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
      system("ruby main.rb") # One command to rule them all
    end

    def fair_competition
      models.each do |model|
        raise "No cheating!" if model.using_gpu?
        raise "Nice try!" if model.response_time < Time.now
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

# Get the party started 🎉
bundle install

# Time to make AI models nervous
bin/benchmark

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
