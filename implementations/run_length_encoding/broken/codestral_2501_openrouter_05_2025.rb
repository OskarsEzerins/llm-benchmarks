module RLE
  def self.rle_encode(input)
    return "" if input.empty?

    encoded = ""
    count = 1
    prev_char = input[0]

    input[1..-1].each_char do |char|
      if char == prev_char
        count += 1
      else
        encoded << "#{prev_char}#{count}"
        prev_char = char
        count = 1
      end
    end

    encoded << "#{prev_char}#{count}"
    encoded
  end

  def self.rle_decode(input)
    return "" if input.empty?

    decoded = ""
    count = ""
    input.each_char do |char|
      if char =~ /\d/
        count << char
      else
        decoded << char * count.to_i
        count = ""
      end
    end

    decoded
  end
end