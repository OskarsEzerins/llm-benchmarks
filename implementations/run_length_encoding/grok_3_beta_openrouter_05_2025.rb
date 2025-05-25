module RLE
  def self.rle_encode(input)
    return "" if input.empty?

    result = String.new
    count = 1
    current_char = input[0]

    (1...input.length).each do |i|
      if input[i] == current_char
        count += 1
      else
        result << current_char << count.to_s
        current_char = input[i]
        count = 1
      end
    end

    result << current_char << count.to_s
    result
  end

  def self.rle_decode(input)
    return "" if input.empty?

    result = String.new
    i = 0

    while i < input.length
      char = input[i]
      i += 1
      count_str = String.new

      while i < input.length && input[i].match?(/\d/)
        count_str << input[i]
        i += 1
      end

      count = count_str.to_i
      result << char * count
    end

    result
  end
end