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
| 1    | claude_3_5_sonnet_cursor_02_2025              | 86.71       | 4/4       | 90.31     | 57.88                | 99.21               | 99.42         |
| 2    | gemini_2_0_flash_web_chat_02_2025             | 85.09       | 4/4       | 91.01     | 62.38                | 90.7                | 96.26         |
| 3    | claude_3_7_sonnet_thinking_vscode_03_2025     | 83.25       | 4/4       | 89.98     | 56.26                | 90.06               | 96.7          |
| 4    | openai_o3_mini_web_chat_02_2025               | 82.52       | 4/4       | 90.72     | 59.43                | 82.09               | 97.84         |
| 5    | openai_o3_mini_web_chat_03_2025               | 82.44       | 4/4       | 90.64     | 63.35                | 76.55               | 99.22         |
| 6    | gemini_2_0_pro_exp_cursor_chat_02_2025        | 82.41       | 4/4       | 86.54     | 68.54                | 75.49               | 99.08         |
| 7    | deepseek_r1_web_chat_02_2025                  | 80.51       | 4/4       | 90.8      | 62.3                 | 73.74               | 95.21         |
| 8    | openai_4_1_mini_openai_api_04_2025            | 78.99       | 4/4       | 89.9      | 71.27                | 55.6                | 99.2          |
| 9    | qwen_2_5_max_02_2025                          | 77.63       | 4/4       | 61.49     | 63.32                | 86.0                | 99.71         |
| 10   | claude_3_7_sonnet_thinking_cursor_02_2025     | 76.36       | 4/4       | 89.29     | 56.96                | 72.13               | 87.06         |
| 11   | openai_o1_web_chat_02_2025                    | 74.02       | 4/4       | 88.77     | 61.14                | 46.42               | 99.77         |
| 12   | deepseek_v3_web_chat_02_2025                  | 71.3        | 3/4       | 0         | 98.42                | 87.18               | 99.59         |
| 13   | gemini_2_5_pro_exp_chat_03_2025               | 67.71       | 4/4       | 89.3      | 5.76                 | 76.21               | 99.56         |
| 14   | openai_o3_high_web_chat_03_2025               | 66.73       | 3/4       | 90.6      | 0                    | 77.17               | 99.17         |
| 15   | claude_4_sonnet_web_chat_05_2025              | 65.05       | 4/4       | 87.12     | 53.67                | 72.7                | 46.71         |
| 16   | openai_o4_high_web_chat_04_2025               | 64.58       | 3/4       | 99.37     | 59.21                | 0                   | 99.73         |
| 17   | openai_o3_high_web_chat_02_2025               | 63.12       | 3/4       | 90.75     | 62.14                | 0                   | 99.61         |
| 18   | claude_3_7_sonnet_vscode_03_2025              | 62.29       | 3/4       | 89.58     | 62.96                | 0                   | 96.6          |
| 19   | claude_3_7_sonnet_web_chat_02_2025            | 61.69       | 3/4       | 90.19     | 0                    | 72.29               | 84.28         |
| 20   | openai_4o_web_chat_02_2025                    | 57.42       | 3/4       | 0         | 57.5                 | 72.54               | 99.65         |
| 21   | openai_4_1_openai_api_04_2025                 | 53.21       | 3/4       | 84.85     | 0                    | 39.51               | 88.48         |
| 22   | openai_4_1_nano_openai_api_04_2025            | 46.57       | 2/4       | 89.94     | 96.35                | 0                   | 0             |
| 23   | qwen_2_5_plus_02_2025                         | 41.13       | 2/4       | 90.8      | 0                    | 73.73               | 0             |
| 24   | openai_o4_mini_web_chat_04_2025               | 37.94       | 2/4       | 88.37     | 63.4                 | 0                   | 0             |
| 25   | mistral_web_03_2025                           | 26.45       | 2/4       | 0         | 66.38                | 0                   | 39.44         |
| 26   | deepseek_r1_distill_qwen_32b_web_chat_02_2025 | 24.87       | 1/4       | 0         | 0                    | 0                   | 99.49         |
| 27   | localai_gpt_4o_phi_2_02_2025                  | 2.84        | 1/4       | 11.37     | 0                    | 0                   | 0             |
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
