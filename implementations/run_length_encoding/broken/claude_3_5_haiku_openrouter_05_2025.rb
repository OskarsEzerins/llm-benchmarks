module RLE
  def self.rle_encode(input)
    return '' if input.empty?

    encoded = []
    current_char = input[0]
    count = 1

    input.chars[1..-1].each do |char|
      if char == current_char
        count += 1
      else
        encoded << current_char + count.to_s
        current_char = char
        count = 1
      end
    end

    encoded << current_char + count.to_s
    encoded.join
  end

  def self.rle_decode(input)
    return '' if input.empty?

    decoded = []
    input.scan(/([A-Za-z])(\d+)/) do |char, count|
      decoded << char * count.to_i
    end

    decoded.join
  end
end