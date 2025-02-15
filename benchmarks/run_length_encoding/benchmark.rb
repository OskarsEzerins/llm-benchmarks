require 'benchmark'

class RunLengthEncodingBenchmark
  def self.run(implementation_path)
    require_relative implementation_path

    encoding_strings = [
      "",
      "A",
      "AAAA",
      "ABC",
      "ABBC",
      "ABBCCC",
      "AAAAAAAAAA",
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
      "ZZZZZZZZZZZZZZZZZZZZZZZZZZ",
      "AABBCCDD",
      "AABBCDAA",
      "A" * 1000,
      ("A" * 1_000_000) + ("B" * 1_000_000) + ("C" * 1_000_000), # Large string
      (0...1_000_000).map { rand(26).chr }.join # Random string
    ]

    decoding_strings = []

    encoding_strings.each do |str|
      encoded = RLE.rle_encode(str)
      decoded = RLE.rle_decode(encoded)
      raise "Encoding/Decoding mismatch for '#{str}'" unless str == decoded # Check for correctness

      decoding_strings << encoded # Store encoded string for decoding benchmark
    end

    time = Benchmark.realtime do
      encoding_strings.each do |str|
        RLE.rle_encode(str)
      end

      decoding_strings.each do |str|
        RLE.rle_decode(str)
      end
    end

    time.round(4)
  end
end
