```ruby
def measure_ai_skills
  puts "We don't just test AI..."
  puts "We make it SWEAT! 💦"
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
ruby main.rb

# See who survived
ruby bin/show_all_results
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

## 🏆 Latest Battle Results

```ruby
module LatestShowdown
  TIMESTAMP = "2025-02-15"

  LRU_CACHE_CHAMPION = {
    model: "openai_o3_high_web_chat_02_2025",
    score: "99.13",
    time: "1.4095s",
    message: "Cache me if you can! 🏃‍♂️💨"
  }

  GRAPH_PATHS_CHAMPION = {
    model: "gemini_2_0_flash_web_chat_02_2025",
    score: "99.94",
    time: "0.2662s",
    message: "Finding paths faster than your GPS! 🗺️⚡"
  }
end
```

<details>
<summary>📊 View Full Scoreboard (click to expand)</summary>

### 🧠 LRU Cache Arena

```
+------+-----------------------------------+-------+---------------+--------------+---------+------+---------------------+
| Rank | Implementation                    | Score | Best Time (s) | Avg Time (s) | Rubocop | Runs | Date                |
+------+-----------------------------------+-------+---------------+--------------+---------+------+---------------------+
| 1    | openai_o3_high_web_chat_02_2025   | 99.13 | 1.4095        | 1.4462       | 0       | 7    | 2025-02-15 01:58:36 |
| 2    | gemini_2_0_flash_web_chat_02_2025 | 98.62 | 1.4246        | 1.4528       | 8       | 7    | 2025-02-15 01:59:13 |
| 3    | claude_sonet_3_5_cursor_02_2025   | 98.2  | 1.4352        | 1.4601       | 0       | 7    | 2025-02-15 01:58:43 |
| 4    | deepseek_r1_web_chat_02_2025      | 98.09 | 1.4228        | 1.477        | 25      | 7    | 2025-02-15 01:52:48 |
| 5    | openai_o3_mini_web_chat_02_2025   | 98.07 | 1.4434        | 1.4574       | 3       | 7    | 2025-02-15 01:53:11 |
| 6    | qwen_2_5_plus_02_2025             | 97.78 | 1.4376        | 1.4754       | 0       | 7    | 2025-02-14 23:48:27 |
| 7    | openai_o1_web_chat_02_2025        | 95.86 | 1.4848        | 1.5096       | 1       | 7    | 2025-02-15 01:58:51 |
| 8    | localai_gpt_4o_phi_2_02_2025      | 5.27  | 2.6839        | 2.7356       | 33      | 7    | 2025-02-14 23:44:13 |
+------+-----------------------------------+-------+---------------+--------------+---------+------+---------------------+
```

### 🗺️ Graph Shortest Paths Showdown

```
+------+-----------------------------------+-------+---------------+--------------+---------+------+---------------------+
| Rank | Implementation                    | Score | Best Time (s) | Avg Time (s) | Rubocop | Runs | Date                |
+------+-----------------------------------+-------+---------------+--------------+---------+------+---------------------+
| 1    | gemini_2_0_flash_web_chat_02_2025 | 99.94 | 0.2662        | 0.2798       | 12      | 7    | 2025-02-14 23:50:51 |
| 2    | deepseek_r1_web_chat_02_2025      | 99.94 | 0.2663        | 0.2808       | 12      | 7    | 2025-02-14 23:51:58 |
| 3    | openai_o3_high_web_chat_02_2025   | 99.93 | 0.2673        | 0.2831       | 9       | 7    | 2025-02-14 23:52:18 |
| 4    | openai_o3_mini_web_chat_02_2025   | 99.75 | 0.2901        | 0.3034       | 9       | 7    | 2025-02-14 23:51:04 |
| 5    | claude_sonet_3_5_cursor_02_2025   | 99.66 | 0.2991        | 0.3157       | 9       | 7    | 2025-02-14 23:52:05 |
| 6    | openai_4o_web_chat_02_2025        | 99.61 | 0.3049        | 0.322        | 8       | 7    | 2025-02-14 23:50:58 |
| 7    | openai_o1_web_chat_02_2025        | 66.49 | 0.2819        | 0.295        | 16      | 7    | 2025-02-14 23:52:12 |
| 8    | qwen_2_5_plus_02_2025             | 34.13 | 8.3143        | 8.3633       | 11      | 7    | 2025-02-14 23:53:44 |
+------+-----------------------------------+-------+---------------+--------------+---------+------+---------------------+
```

</details>

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
