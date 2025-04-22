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
| 1    | claude_3_5_sonnet_cursor_02_2025              | 96.69       | 4/4       | 90.43     | 97.6                 | 99.31               | 99.44         |
| 2    | claude_3_7_sonnet_thinking_vscode_03_2025     | 93.81       | 4/4       | 90.61     | 97.51                | 90.46               | 96.67         |
| 3    | openai_o3_mini_web_chat_02_2025               | 92.22       | 4/4       | 90.99     | 97.69                | 82.36               | 97.85         |
| 4    | openai_o3_mini_web_chat_03_2025               | 91.32       | 4/4       | 90.99     | 97.9                 | 77.2                | 99.18         |
| 5    | gemini_2_0_pro_exp_cursor_chat_02_2025        | 89.99       | 4/4       | 86.6      | 98.19                | 76.04               | 99.13         |
| 6    | deepseek_r1_web_chat_02_2025                  | 89.41       | 4/4       | 90.86     | 97.85                | 73.7                | 95.22         |
| 7    | claude_3_7_sonnet_thinking_cursor_02_2025     | 86.68       | 4/4       | 89.41     | 97.59                | 72.62               | 87.11         |
| 8    | qwen_2_5_max_02_2025                          | 86.2        | 4/4       | 61.07     | 97.9                 | 86.14               | 99.71         |
| 9    | gemini_2_0_flash_web_chat_02_2025             | 85.68       | 4/4       | 91.09     | 97.85                | 90.86               | 62.93         |
| 10   | openai_4_1_mini_openai_api_04_2025            | 84.9        | 4/4       | 90.21     | 98.46                | 51.68               | 99.25         |
| 11   | openai_o1_web_chat_02_2025                    | 83.3        | 4/4       | 88.87     | 97.8                 | 46.75               | 99.77         |
| 12   | gemini_2_5_pro_exp_chat_03_2025               | 82.43       | 4/4       | 90.55     | 63.19                | 76.4                | 99.58         |
| 13   | openai_o4_high_web_chat_04_2025               | 74.17       | 3/4       | 99.22     | 97.66                | 0                   | 99.81         |
| 14   | openai_o3_high_web_chat_02_2025               | 72.07       | 3/4       | 90.83     | 97.85                | 0                   | 99.61         |
| 15   | deepseek_v3_web_chat_02_2025                  | 71.74       | 3/4       | 0         | 99.9                 | 87.45               | 99.61         |
| 16   | claude_3_7_sonnet_vscode_03_2025              | 71.08       | 3/4       | 89.71     | 97.91                | 0                   | 96.68         |
| 17   | openai_4o_web_chat_02_2025                    | 67.52       | 3/4       | 0         | 97.59                | 72.83               | 99.65         |
| 18   | openai_o3_high_web_chat_03_2025               | 66.97       | 3/4       | 91.0      | 0                    | 77.65               | 99.23         |
| 19   | openai_4_1_openai_api_04_2025                 | 62.67       | 4/4       | 84.77     | 38.6                 | 38.64               | 88.65         |
| 20   | claude_3_7_sonnet_web_chat_02_2025            | 61.86       | 3/4       | 90.39     | 0                    | 72.75               | 84.29         |
| 21   | qwen_2_5_plus_02_2025                         | 50.98       | 3/4       | 90.89     | 39.25                | 73.78               | 0             |
| 22   | openai_4_1_nano_openai_api_04_2025            | 47.44       | 2/4       | 90.03     | 99.73                | 0                   | 0             |
| 23   | openai_o4_mini_web_chat_04_2025               | 46.88       | 2/4       | 89.62     | 97.89                | 0                   | 0             |
| 24   | mistral_web_03_2025                           | 34.24       | 2/4       | 0         | 98.11                | 0                   | 38.84         |
| 25   | deepseek_r1_distill_qwen_32b_web_chat_02_2025 | 24.87       | 1/4       | 0         | 0                    | 0                   | 99.5          |
| 26   | localai_gpt_4o_phi_2_02_2025                  | 2.9         | 1/4       | 11.61     | 0                    | 0                   | 0             |
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
