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
| 1    | claude_sonet_3_5_cursor_02_2025                 | 97.99       | 4/4       | 97.6      | 97.51                | 99.07               | 97.8          |
| 2    | openai_o3_mini_web_chat_02_2025                 | 89.86       | 4/4       | 97.66     | 97.58                | 72.79               | 91.42         |
| 3    | gemini_2_0_pro_exp_cursor_chat_02_2025          | 87.58       | 4/4       | 92.82     | 98.08                | 63.29               | 96.13         |
| 4    | deepseek_r1_web_chat_02_2025                    | 83.87       | 4/4       | 98.02     | 97.75                | 58.46               | 81.23         |
| 5    | gemini_2_0_flash_web_chat_02_2025               | 83.57       | 4/4       | 98.59     | 97.75                | 85.86               | 52.09         |
| 6    | qwen_2_5_max_02_2025                            | 82.29       | 4/4       | 56.0      | 97.72                | 76.64               | 98.8          |
| 7    | openai_o1_web_chat_02_2025                      | 73.78       | 4/4       | 95.86     | 64.37                | 35.77               | 99.13         |
| 8    | openai_o3_high_web_chat_02_2025                 | 73.66       | 3/4       | 98.2      | 97.76                | 0                   | 98.66         |
| 9    | claude_sonet_3_7_sonnet_thinking_cursor_02_2025 | 73.63       | 4/4       | 94.16     | 97.28                | 56.92               | 46.17         |
| 10   | openai_4o_web_chat_02_2025                      | 63.45       | 3/4       | 0         | 97.49                | 57.69               | 98.62         |
| 11   | deepseek_v3_web_chat_02_2025                    | 61.33       | 3/4       | 0         | 66.54                | 80.69               | 98.1          |
| 12   | qwen_2_5_plus_02_2025                           | 48.03       | 3/4       | 98.25     | 36.4                 | 57.47               | 0             |
| 13   | claude_sonet_3_7_sonnet_web_chat_02_2025        | 47.47       | 3/4       | 97.1      | 0                    | 55.68               | 37.11         |
| 14   | deepseek_r1_distill_qwen_32b_web_chat_02_2025   | 24.5        | 1/4       | 0         | 0                    | 0                   | 97.98         |
| 15   | localai_gpt_4o_phi_2_02_2025                    | 3.25        | 1/4       | 13.0      | 0                    | 0                   | 0             |
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
