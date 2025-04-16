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
| 1    | claude_sonet_3_5_cursor_02_2025                 | 97.38       | 4/4       | 93.26     | 97.5                 | 99.31               | 99.43         |
| 2    | claude_sonet_3_7_sonnet_thinking_vscode_03_2025 | 94.43       | 4/4       | 93.67     | 97.36                | 90.11               | 96.55         |
| 3    | openai_o3_mini_web_chat_02_2025                 | 92.55       | 4/4       | 93.87     | 97.58                | 80.95               | 97.81         |
| 4    | openai_o3_mini_web_chat_03_2025                 | 91.7        | 4/4       | 94.02     | 97.78                | 75.86               | 99.14         |
| 5    | gemini_2_0_pro_exp_cursor_chat_02_2025          | 90.18       | 4/4       | 89.31     | 98.12                | 74.18               | 99.11         |
| 6    | deepseek_r1_web_chat_02_2025                    | 89.51       | 4/4       | 93.72     | 97.75                | 71.4                | 95.15         |
| 7    | claude_sonet_3_7_sonnet_thinking_cursor_02_2025 | 86.75       | 4/4       | 92.18     | 97.5                 | 70.42               | 86.91         |
| 8    | openai_4_1_mini_openai_api_04_2025              | 86.67       | 4/4       | 94.95     | 98.44                | 53.93               | 99.37         |
| 9    | gemini_2_0_flash_web_chat_02_2025               | 86.18       | 4/4       | 93.98     | 97.76                | 90.1                | 62.88         |
| 10   | qwen_2_5_max_02_2025                            | 86.16       | 4/4       | 62.17     | 97.81                | 84.97               | 99.7          |
| 11   | openai_o1_web_chat_02_2025                      | 83.55       | 4/4       | 91.63     | 97.7                 | 45.12               | 99.77         |
| 12   | gemini_2_5_pro_exp_chat_03_2025                 | 82.66       | 4/4       | 93.7      | 63.06                | 74.19               | 99.68         |
| 13   | openai_o4_high_web_chat_04_2025                 | 74.4        | 3/4       | 100.0     | 97.75                | 0                   | 99.87         |
| 14   | openai_o3_high_web_chat_02_2025                 | 72.77       | 3/4       | 93.69     | 97.76                | 0                   | 99.63         |
| 15   | claude_sonet_3_7_sonnet_vscode_03_2025          | 71.88       | 3/4       | 93.1      | 97.86                | 0                   | 96.57         |
| 16   | deepseek_v3_web_chat_02_2025                    | 71.5        | 3/4       | 0         | 99.9                 | 86.5                | 99.6          |
| 17   | openai_o3_high_web_chat_03_2025                 | 67.35       | 3/4       | 94.1      | 0                    | 76.09               | 99.21         |
| 18   | openai_4o_web_chat_02_2025                      | 66.92       | 3/4       | 0         | 97.48                | 70.55               | 99.65         |
| 19   | claude_sonet_3_7_sonnet_web_chat_02_2025        | 61.97       | 3/4       | 93.28     | 0                    | 70.54               | 84.06         |
| 20   | openai_4_1_openai_api_04_2025                   | 61.76       | 4/4       | 87.39     | 37.58                | 33.33               | 88.73         |
| 21   | qwen_2_5_plus_02_2025                           | 50.39       | 3/4       | 93.75     | 36.43                | 71.37               | 0             |
| 22   | openai_4_1_nano_openai_api_04_2025              | 48.81       | 2/4       | 95.39     | 99.85                | 0                   | 0             |
| 23   | openai_o4_mini_web_chat_04_2025                 | 47.83       | 2/4       | 93.33     | 97.98                | 0                   | 0             |
| 24   | mistral_web_03_2025                             | 34.09       | 2/4       | 0         | 98.07                | 0                   | 38.3          |
| 25   | deepseek_r1_distill_qwen_32b_web_chat_02_2025   | 24.87       | 1/4       | 0         | 0                    | 0                   | 99.49         |
| 26   | localai_gpt_4o_phi_2_02_2025                    | 3.08        | 1/4       | 12.33     | 0                    | 0                   | 0             |
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
