# filepath: rle.rb
module RLE
  def self.rle_encode(input)
    return "" if input.empty?

    result = ""
    count = 1
    prev_char = input[0]

    (1...input.length).each do |i|
      if input[i] == prev_char
        count += 1
      else
        result << "#{prev_char}#{count}"
        prev_char = input[i]
        count = 1
      end
    end

    result << "#{prev_char}#{count}"
    result
  end

  def self.rle_decode(input)
    return "" if input.empty?

    result = ""
    chars = input.scan(/([A-Za-z])(\d+)/)

    chars.each do |char, count|
      result << char * count.to_i
    end

    result
  end
end
