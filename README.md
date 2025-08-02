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
+-----------------------------------------------------------------------------------------------------------------------------------------------+
|                                                     Program Fixer Implementation Rankings                                                     |
+------+-----------------------------------------------+-------------+-----------+-----------------+----------+----------------+----------------+
| Rank | Implementation                                | Total Score | Completed | Vending Machine | Calendar | Parking Garage | School Library |
+------+-----------------------------------------------+-------------+-----------+-----------------+----------+----------------+----------------+
| 1    | claude_sonnet_4_openrouter_08_2025            | 75.71       | 4/4       | 74.97           | 79.55    | 72.43          | 75.9           |
| 2    | openai_o1_mini_openrouter_08_2025             | 72.38       | 4/4       | 76.68           | 83.66    | 53.27          | 75.9           |
| 3    | openai_chat_4o_latest_openrouter_08_2025      | 71.82       | 4/4       | 77.08           | 78.03    | 53.67          | 78.51          |
| 4    | claude_opus_4_openrouter_08_2025              | 70.84       | 4/4       | 74.97           | 91.29    | 64.11          | 53.0           |
| 5    | openai_4_1_openrouter_08_2025                 | 70.75       | 4/4       | 76.88           | 85.57    | 46.25          | 74.3           |
| 6    | codestral_2508_openrouter_08_2025             | 69.4        | 4/4       | 75.37           | 85.26    | 69.81          | 47.17          |
| 7    | r1_openrouter_08_2025                         | 68.69       | 4/4       | 77.88           | 72.12    | 45.43          | 79.31          |
| 8    | openai_4_openrouter_08_2025                   | 68.61       | 4/4       | 77.88           | 81.55    | 55.97          | 59.03          |
| 9    | claude_3_7_sonnet_thinking_openrouter_08_2025 | 68.58       | 4/4       | 77.28           | 78.75    | 67.11          | 51.19          |
| 10   | openai_o3_mini_openrouter_08_2025             | 68.47       | 4/4       | 77.48           | 80.15    | 40.73          | 75.5           |
| 11   | openai_o3_mini_high_openrouter_08_2025        | 68.39       | 4/4       | 77.68           | 79.35    | 41.03          | 75.5           |
| 12   | claude_3_5_sonnet_openrouter_08_2025          | 67.95       | 4/4       | 77.08           | 80.35    | 63.39          | 50.99          |
| 13   | openai_o4_mini_openrouter_08_2025             | 67.68       | 4/4       | 77.28           | 84.46    | 32.89          | 76.1           |
| 14   | grok_3_openrouter_08_2025                     | 67.28       | 4/4       | 77.28           | 65.1     | 65.91          | 60.83          |
| 15   | openai_o4_mini_high_openrouter_08_2025        | 65.15       | 4/4       | 77.48           | 80.75    | 27.88          | 74.5           |
| 16   | openai_4_turbo_openrouter_08_2025             | 64.66       | 4/4       | 77.48           | 86.97    | 40.41          | 53.8           |
| 17   | llama_4_scout_openrouter_08_2025              | 63.26       | 4/4       | 77.68           | 73.52    | 45.03          | 56.81          |
| 18   | openai_4_1_mini_openrouter_08_2025            | 63.04       | 4/4       | 76.68           | 80.55    | 46.74          | 48.19          |
| 19   | llama_4_maverick_openrouter_08_2025           | 62.96       | 4/4       | 77.68           | 83.86    | 42.53          | 47.77          |
| 20   | gemini_2_5_pro_openrouter_08_2025             | 62.36       | 4/4       | 78.48           | 84.46    | 32.69          | 53.8           |
| 21   | grok_4_openrouter_08_2025                     | 62.23       | 4/4       | 45.55           | 84.66    | 39.21          | 79.51          |
| 22   | gemini_2_5_flash_openrouter_08_2025           | 62.21       | 4/4       | 77.68           | 84.86    | 29.69          | 56.61          |
| 23   | openai_4_1_nano_openrouter_08_2025            | 61.59       | 4/4       | 78.08           | 84.46    | 11.94          | 71.89          |
| 24   | mistral_medium_3_openrouter_08_2025           | 60.35       | 4/4       | 45.95           | 61.38    | 57.77          | 76.3           |
| 25   | claude_3_7_sonnet_openrouter_08_2025          | 60.33       | 4/4       | 77.48           | 63.5     | 49.15          | 51.19          |
| 26   | deepseek_v3_openrouter_08_2025                | 59.57       | 4/4       | 43.24           | 73.12    | 64.09          | 57.81          |
| 27   | grok_3_mini_openrouter_08_2025                | 58.65       | 4/4       | 44.95           | 75.83    | 34.91          | 78.91          |
| 28   | gemini_2_5_flash_lite_openrouter_08_2025      | 58.53       | 4/4       | 74.77           | 78.03    | 19.06          | 62.24          |
| 29   | gemini_2_0_flash_001_openrouter_08_2025       | 57.34       | 4/4       | 44.95           | 88.57    | 39.63          | 56.21          |
| 30   | claude_3_5_haiku_openrouter_08_2025           | 57.32       | 4/4       | 77.88           | 84.46    | 16.94          | 49.99          |
| 31   | openai_4o_openrouter_08_2025                  | 55.83       | 4/4       | 45.35           | 77.95    | 55.47          | 44.56          |
| 32   | claude_3_haiku_openrouter_08_2025             | 53.88       | 4/4       | 43.64           | 55.95    | 36.0           | 79.91          |
| 33   | kimi_k2_openrouter_08_2025                    | 52.12       | 4/4       | 45.55           | 64.9     | 44.23          | 53.8           |
| 34   | nova_pro_v1_openrouter_08_2025                | 51.9        | 4/4       | 45.95           | 73.72    | 14.63          | 73.29          |
| 35   | openai_4o_mini_openrouter_08_2025             | 51.67       | 4/4       | 43.64           | 73.32    | 19.04          | 70.69          |
| 36   | coder_large_openrouter_08_2025                | 50.57       | 4/4       | 45.75           | 80.35    | 9.32           | 66.86          |
| 37   | qwen3_coder_openrouter_08_2025                | 49.67       | 4/4       | 45.95           | 59.18    | 40.33          | 53.2           |
| 38   | nova_lite_v1_openrouter_08_2025               | 49.12       | 4/4       | 32.23           | 63.18    | 23.76          | 77.3           |
| 39   | openai_3_5_turbo_openrouter_08_2025           | 46.12       | 4/4       | 43.64           | 59.67    | 36.4           | 44.76          |
| 40   | nova_micro_v1_openrouter_08_2025              | 39.94       | 4/4       | 37.43           | 22.65    | 26.97          | 72.69          |
| 41   | qwen3_14b_openrouter_08_2025                  | 35.97       | 3/4       | 43.44           | 0        | 35.0           | 65.46          |
| 42   | gemma_3_4b_it_openrouter_08_2025              | 14.85       | 2/4       | 43.64           | 15.74    | 0              | 0              |
| 43   | magnum_v4_72b_openrouter_08_2025              | 10.91       | 1/4       | 43.64           | 0        | 0              | 0              |
| 44   | command_a_openrouter_08_2025                  | 7.18        | 3/4       | 11.71           | 7.2      | 0              | 9.8            |
+------+-----------------------------------------------+-------------+-----------+-----------------+----------+----------------+----------------+
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
