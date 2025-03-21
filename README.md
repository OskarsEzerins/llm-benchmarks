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
| 1    | claude_sonet_3_5_cursor_02_2025                 | 98.39       | 4/4       | 97.65     | 97.5                 | 99.02               | 99.4          |
| 2    | claude_sonet_3_7_sonnet_thinking_vscode_03_2025 | 94.21       | 4/4       | 97.43     | 97.34                | 86.13               | 95.96         |
| 3    | openai_o3_mini_web_chat_02_2025                 | 91.51       | 4/4       | 98.01     | 97.57                | 72.8                | 97.67         |
| 4    | openai_o3_mini_web_chat_03_2025                 | 90.02       | 4/4       | 97.46     | 97.62                | 66.04               | 98.98         |
| 5    | gemini_2_0_pro_exp_cursor_chat_02_2025          | 88.37       | 4/4       | 93.06     | 98.09                | 63.29               | 99.04         |
| 6    | deepseek_r1_web_chat_02_2025                    | 87.26       | 4/4       | 98.13     | 97.75                | 58.32               | 94.84         |
| 7    | gemini_2_0_flash_web_chat_02_2025               | 86.21       | 4/4       | 98.62     | 97.75                | 85.77               | 62.69         |
| 8    | claude_sonet_3_7_sonnet_thinking_cursor_02_2025 | 84.41       | 4/4       | 96.68     | 97.3                 | 57.54               | 86.12         |
| 9    | qwen_2_5_max_02_2025                            | 82.53       | 4/4       | 56.14     | 97.73                | 76.56               | 99.67         |
| 10   | openai_o1_web_chat_02_2025                      | 73.98       | 4/4       | 95.99     | 64.37                | 35.81               | 99.74         |
| 11   | openai_o3_high_web_chat_02_2025                 | 73.91       | 3/4       | 98.25     | 97.75                | 0                   | 99.63         |
| 12   | claude_sonet_3_7_sonnet_vscode_03_2025          | 72.82       | 3/4       | 97.91     | 97.67                | 0                   | 95.68         |
| 13   | openai_o3_high_web_chat_03_2025                 | 65.72       | 3/4       | 97.65     | 0                    | 66.3                | 98.93         |
| 14   | openai_4o_web_chat_02_2025                      | 63.71       | 3/4       | 0         | 97.48                | 57.76               | 99.61         |
| 15   | deepseek_v3_web_chat_02_2025                    | 61.7        | 3/4       | 0         | 66.56                | 80.71               | 99.53         |
| 16   | claude_sonet_3_7_sonnet_web_chat_02_2025        | 59.48       | 3/4       | 97.56     | 0                    | 57.76               | 82.61         |
| 17   | qwen_2_5_plus_02_2025                           | 48.24       | 3/4       | 98.28     | 36.43                | 58.27               | 0             |
| 18   | mistral_web_03_2025                             | 32.84       | 2/4       | 0         | 98.01                | 0                   | 33.33         |
| 19   | deepseek_r1_distill_qwen_32b_web_chat_02_2025   | 24.85       | 1/4       | 0         | 0                    | 0                   | 99.41         |
| 20   | localai_gpt_4o_phi_2_02_2025                    | 3.24        | 1/4       | 12.97     | 0                    | 0                   | 0             |
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
