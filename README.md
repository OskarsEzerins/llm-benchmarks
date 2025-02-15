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
| 1    | claude_sonet_3_5_cursor_02_2025               | 96.89       | 4/4       | 97.44     | 97.53                | 99.28               | 93.33         |
| 2    | gemini_2_0_pro_exp_cursor_chat_02_2025        | 86.28       | 4/4       | 93.84     | 98.15                | 63.79               | 89.34         |
| 3    | openai_o3_mini_web_chat_02_2025               | 85.49       | 4/4       | 97.6      | 97.61                | 73.14               | 73.6          |
| 4    | qwen_2_5_max_02_2025                          | 80.72       | 4/4       | 51.73     | 97.76                | 76.9                | 96.49         |
| 5    | gemini_2_0_flash_web_chat_02_2025             | 76.13       | 4/4       | 98.56     | 97.79                | 86.14               | 22.03         |
| 6    | deepseek_r1_web_chat_02_2025                  | 73.91       | 4/4       | 97.9      | 97.8                 | 58.11               | 41.85         |
| 7    | openai_o1_web_chat_02_2025                    | 73.36       | 4/4       | 95.4      | 64.42                | 36.07               | 97.54         |
| 8    | openai_o3_high_web_chat_02_2025               | 73.11       | 3/4       | 98.38     | 97.79                | 0                   | 96.27         |
| 9    | openai_4o_web_chat_02_2025                    | 63.02       | 3/4       | 0         | 97.54                | 58.03               | 96.53         |
| 10   | deepseek_v3_web_chat_02_2025                  | 60.53       | 3/4       | 0         | 66.57                | 80.97               | 94.59         |
| 11   | qwen_2_5_plus_02_2025                         | 48.02       | 3/4       | 98.43     | 36.49                | 57.15               | 0             |
| 12   | deepseek_r1_distill_qwen_32b_web_chat_02_2025 | 23.49       | 1/4       | 0         | 0                    | 0                   | 93.94         |
| 13   | localai_gpt_4o_phi_2_02_2025                  | 1.91        | 1/4       | 7.64      | 0                    | 0                   | 0             |
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
